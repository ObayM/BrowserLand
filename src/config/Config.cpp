#include "config/Config.h"

#include "config/ConfigWatcher.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJSEngine>
#include <QMetaMethod>
#include <QSet>
#include <QStandardPaths>
#include <QUrl>


namespace {

Config *s_instance = nullptr;


bool isReservedName(const QMetaObject &meta, const QString &name)
{
    const QByteArray latin = name.toLatin1();
    if (meta.indexOfProperty(latin.constData()) >= 0)
        return true;
    for (int i = 0; i < meta.methodCount(); ++i) {
        if (meta.method(i).name() == latin)
            return true;
    }
    return name == u"keys";
}

}

Config::Config(const QString &configDir, QObject *parent)
    : QQmlPropertyMap(this, parent)
    , m_configDir(QDir::cleanPath(configDir))
    , m_watcher(new ConfigWatcher(this))
{
    s_instance = this;
    connect(m_watcher, &ConfigWatcher::changed, this, &Config::reload);
    reload();
}

Config::~Config()
{
    if (s_instance == this)
        s_instance = nullptr;
}

Config *Config::create(QQmlEngine *, QJSEngine *)
{
    Q_ASSERT_X(s_instance, "Config::create", "main.cpp must create the Config before loading QML");

    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
    return s_instance;
}

QString Config::defaultConfigDir()
{
    return QDir(QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation))
        .filePath(QStringLiteral("browserland"));
}

QString Config::defaultsFile()
{
    return QStringLiteral(":/browserland/default.conf");
}

bool Config::installStarterConfig(const QString &dir)
{
    const QString target = QDir(dir).filePath(QStringLiteral("browserland.conf"));
    if (QFileInfo::exists(target))
        return false;

    if (!QDir().mkpath(dir) || !QFile::copy(defaultsFile(), target)) {
        qWarning().noquote() << "browserland: could not create" << target;
        return false;
    }

    QFile::setPermissions(target, QFile::permissions(target) | QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    qInfo().noquote() << "browserland: created your config at" << target;
    return true;
}

QStringList Config::errors() const
{
    QStringList list;
    for (const ConfigError &error : m_errors)
        list.append(error.toString());
    return list;
}

QVariantList Config::binds() const
{
    QVariantList list;
    for (const Keybind &bind : m_binds) {
        list.append(QVariantMap{
            {QStringLiteral("sequence"), bind.sequence},
            {QStringLiteral("action"), bind.action},
            {QStringLiteral("args"), bind.args},
        });
    }
    return list;
}

QVariantList Config::widgets() const
{
    QVariantList list;
    for (const WidgetDecl &widget : m_widgets) {
        list.append(QVariantMap{
            {QStringLiteral("name"), widget.name},
            {QStringLiteral("file"), widget.file},
            {QStringLiteral("url"), QUrl::fromLocalFile(widget.file)},
            {QStringLiteral("slot"), widget.slot},
        });
    }
    return list;
}

QString Config::configDir() const
{
    return m_configDir;
}

QString Config::configFile() const
{
    return QDir(m_configDir).filePath(QStringLiteral("browserland.conf"));
}

QVariant Config::setting(const QString &key, const QVariant &fallback) const
{
    return m_values.value(key, fallback);
}

void Config::reload()
{
    ConfigParser parser;
    const ParsedConfig defaults = parser.parseFile(defaultsFile());
    const bool hasUserFile = QFileInfo::exists(configFile());
    const ParsedConfig user = hasUserFile ? parser.parseFile(configFile()) : ParsedConfig{};

    m_errors = defaults.errors + user.errors;

    QVariantMap values = defaults.values;
    for (auto it = user.values.cbegin(); it != user.values.cend(); ++it)
        values.insert(it.key(), it.value());
    applyValues(values);

    const QList<Keybind> allBinds = defaults.binds + user.binds;

    QSet<QString> seen;

    m_binds.clear();

    for (auto it = allBinds.crbegin(); it != allBinds.crend(); ++it) {
        if (seen.contains(it->sequence))
            continue;
        seen.insert(it->sequence);
        m_binds.prepend(*it);
    }

    m_widgets = user.widgets;
    m_watcher->watch(m_configDir, user.files);

    if (!hasUserFile)
        qInfo().noquote() << "browserland: no config at" << configFile() << "- using built-in defaults";

    qInfo().noquote() << QStringLiteral("browserland: config loaded, %1 error(s)").arg(m_errors.size());

    for (const ConfigError &error : std::as_const(m_errors))
        qWarning().noquote() << "  " << error.toString();

    emit reloaded();
}

void Config::applyValues(const QVariantMap &values)
{
    QSet<QString> sections;
    for (auto it = values.cbegin(); it != values.cend(); ++it) {
        const QStringList parts = it.key().split(u'.');
        for (int i = 1; i < parts.size(); ++i)
            sections.insert(parts.mid(0, i).join(u'.'));
    }

    for (auto it = m_values.cbegin(); it != m_values.cend(); ++it) {
        if (values.contains(it.key()))
            continue;
        QStringList parts = it.key().split(u'.');
        const QString leaf = parts.takeLast();
        if (QQmlPropertyMap *map = parts.isEmpty() ? this : m_sections.value(parts.join(u'.')))
            map->clear(leaf);
    }

    QVariantMap applied;
    QSet<QString> reported;
    auto reportOnce = [this, &reported](const QString &name, const QString &message) {
        if (!reported.contains(name)) {
            reported.insert(name);
            m_errors.append({configFile(), 0, message});
        }
    };

    for (auto it = values.cbegin(); it != values.cend(); ++it) {
        const QStringList names = it.key().split(u'.');

        if (sections.contains(it.key())) {
            reportOnce(it.key(), QStringLiteral("'%1' is used both as a setting and as a section").arg(it.key()));
            continue;
        }

        QString reservedName;

        for (int i = 0; i < names.size() && reservedName.isEmpty(); ++i) {
            const QMetaObject &meta = i == 0 ? Config::staticMetaObject : QQmlPropertyMap::staticMetaObject;

            if (isReservedName(meta, names.at(i)))
                reservedName = names.at(i);
        }
        if (!reservedName.isEmpty()) {
            reportOnce(reservedName, QStringLiteral("'%1' is a reserved name, please pick another").arg(reservedName));
            continue;
        }

        QQmlPropertyMap *map = sectionMap(names.mid(0, names.size() - 1));

        if (map->value(names.last()) != it.value())
            map->insert(names.last(), it.value());

        applied.insert(it.key(), it.value());
    }

    m_values = applied;
}

QQmlPropertyMap *Config::sectionMap(const QStringList &path)
{
    QQmlPropertyMap *map = this;
    for (int i = 0; i < path.size(); ++i) {
        const QString key = path.mid(0, i + 1).join(u'.');
        QQmlPropertyMap *child = m_sections.value(key);
        if (!child) {
            child = new QQmlPropertyMap(this);
            m_sections.insert(key, child);
        }

        if (map->value(path.at(i)).value<QObject *>() != child)
            map->insert(path.at(i), QVariant::fromValue(static_cast<QObject *>(child)));

        map = child;
    }
    return map;
}
