#pragma once

#include <QObject>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

class QJSEngine;
class QQmlEngine;

class System : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString dataDir READ dataDir CONSTANT)

public:
    explicit System(const QString &dataDir, QObject *parent = nullptr);
    ~System() override;

    static System *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    static QString defaultDataDir();

    QString dataDir() const;

    Q_INVOKABLE QVariant readJson(const QString &name) const;
    Q_INVOKABLE bool writeJson(const QString &name, const QVariant &value) const;
    Q_INVOKABLE QString downloadDir(const QString &configured) const;
    Q_INVOKABLE bool exec(const QString &command) const;

private:
    QString m_dataDir;
};
