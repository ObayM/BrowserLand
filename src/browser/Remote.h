#pragma once

#include <QLocalServer>
#include <QObject>

class QQmlApplicationEngine;

class Remote : public QObject
{
    Q_OBJECT

public:
    explicit Remote(QQmlApplicationEngine *engine, QObject *parent = nullptr);

    static QString socketName();
    static bool send(const QStringList &commands, QStringList *replies = nullptr);

    bool listen();

private:
    QString handle(const QString &line);

    QQmlApplicationEngine *m_engine;
    QLocalServer m_server;
};
