#pragma once

#include <QObject>
#include <QUrl>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

class QJSEngine;
class QQmlEngine;

class History : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit History(const QString &dataDir, QObject *parent = nullptr);
    ~History() override;

    static History *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    Q_INVOKABLE void add(const QUrl &url, const QString &title, const QUrl &icon);
    Q_INVOKABLE void setIcon(const QUrl &url, const QUrl &icon);
    Q_INVOKABLE QVariantList top(int limit = 8) const;
    Q_INVOKABLE int visitedToday() const;
    Q_INVOKABLE QVariantList search(const QString &text, int limit = 8) const;
    Q_INVOKABLE void clear();

private:
    QString m_connection;
};
