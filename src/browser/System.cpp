#include "browser/System.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJSEngine>
#include <QJSValue>
#include <QJsonDocument>
#include <QProcess>
#include <QSaveFile>
#include <QStandardPaths>

namespace {

System *s_instance = nullptr;

}

System::System(const QString &dataDir, QObject *parent)
    : QObject(parent)
    , m_dataDir(QDir::cleanPath(dataDir))
{
    s_instance = this;
    QDir().mkpath(m_dataDir);
}

System::~System()
{
    if (s_instance == this)
        s_instance = nullptr;
}

System *System::create(QQmlEngine *, QJSEngine *)
{
    Q_ASSERT_X(s_instance, "System::create", "main.cpp must create System before loading QML");

    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
    return s_instance;
}

QString System::defaultDataDir()
{
    return QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation))
        .filePath(QStringLiteral("browserland"));
}

QString System::dataDir() const
{
    return m_dataDir;
}

QVariant System::readJson(const QString &name) const
{
    QFile file(QDir(m_dataDir).filePath(name));
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return QJsonDocument::fromJson(file.readAll()).toVariant();
}

bool System::writeJson(const QString &name, const QVariant &value) const
{
    const QVariant plain = value.metaType() == QMetaType::fromType<QJSValue>()
        ? value.value<QJSValue>().toVariant()
        : value;

    QSaveFile file(QDir(m_dataDir).filePath(name));

    if (!file.open(QIODevice::WriteOnly))
        return false;
    
    file.write(QJsonDocument::fromVariant(plain).toJson());
    return file.commit();
}

QString System::downloadDir(const QString &configured) const
{
    QString dir = configured.trimmed();
    if (dir == u"~" || dir.startsWith(u"~/"))
        dir = QDir::homePath() + dir.mid(1);
    if (dir.isEmpty())
        dir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    
    if (dir.isEmpty())
        dir = QDir::homePath();
    if (QDir::isRelativePath(dir))
        dir = QDir::home().filePath(dir);

    QDir().mkpath(dir);
    return QDir::cleanPath(dir);
}

bool System::exec(const QString &command) const
{
    if (command.trimmed().isEmpty())
        return false;

#ifdef Q_OS_WIN
    const bool started = QProcess::startDetached(QStringLiteral("cmd.exe"), {QStringLiteral("/c"), command}, QDir::homePath());
#else
    const bool started = QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), command}, QDir::homePath());
#endif

    if (!started)
        qWarning().noquote() << "browserland: could not run" << command;
    return started;
}
