#pragma once

#include "config/ConfigParser.h"
#include <QUrl>

#include <QHash>
#include <QQmlPropertyMap>
#include <QtQml/qqmlregistration.h>

class ConfigWatcher;
class QJSEngine;
class QQmlEngine;

class Config : public QQmlPropertyMap
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QStringList errors READ errors NOTIFY reloaded)
    Q_PROPERTY(QVariantList binds READ binds NOTIFY reloaded)
    Q_PROPERTY(QVariantList widgets READ widgets NOTIFY reloaded)
    Q_PROPERTY(QVariantList siteRules READ siteRules NOTIFY reloaded)
    Q_PROPERTY(QString configDir READ configDir CONSTANT)
    Q_PROPERTY(QString configFile READ configFile CONSTANT)
    Q_PROPERTY(QUrl shellUrl READ shellUrl NOTIFY reloaded)

public:
    explicit Config(const QString &configDir, QObject *parent = nullptr);
    ~Config() override;

    static Config *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    static QString defaultConfigDir();
    static QString defaultsFile();

    static bool installStarterConfig(const QString &dir);

    QStringList errors() const;
    QVariantList binds() const;
    QVariantList widgets() const;
    QVariantList siteRules() const;
    QUrl shellUrl() const;
    QString configDir() const;
    QString configFile() const;

    QVariant setting(const QString &key, const QVariant &fallback = {}) const;

public slots:
    void reload();

signals:
    void reloaded();

private:
    void applyValues(const QVariantMap &values);
    QQmlPropertyMap *sectionMap(const QStringList &path);

    QString m_configDir;
    QVariantMap m_values;
    QList<Keybind> m_binds;
    QList<WidgetDecl> m_widgets;
    QVariantList m_siteRules;
    QList<ConfigError> m_errors;
    QHash<QString, QQmlPropertyMap *> m_sections;
    ConfigWatcher *m_watcher;
};
