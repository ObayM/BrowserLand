#include "browser/Remote.h"

#include <QDebug>
#include <QDir>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include <QWindow>

Remote::Remote(QQmlApplicationEngine *engine, QObject *parent)
    : QObject(parent)
    , m_engine(engine)
{
    m_server.setSocketOptions(QLocalServer::UserAccessOption);

    connect(&m_server, &QLocalServer::newConnection, this, [this] {
        while (QLocalSocket *socket = m_server.nextPendingConnection()) {
            
            connect(socket, &QLocalSocket::disconnected, socket, &QObject::deleteLater);
            connect(socket, &QLocalSocket::readyRead, socket, [this, socket] {
                
                while (socket->canReadLine())
                    socket->write(handle(QString::fromUtf8(socket->readLine()).trimmed()).toUtf8() + '\n');
            });
        }
    });
}

QString Remote::socketName()
{
#ifdef Q_OS_WIN
    return QStringLiteral("browserland-") + qEnvironmentVariable("USERNAME");
#else
    return QDir(QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation))
        .filePath(QStringLiteral("browserland.sock"));
#endif
}

bool Remote::send(const QStringList &commands, QStringList *replies)
{
    QLocalSocket socket;
    socket.connectToServer(socketName());
    if (!socket.waitForConnected(1000))
        return false;

    for (const QString &command : commands)
        socket.write(command.toUtf8() + '\n');
    socket.waitForBytesWritten(1000);

    for (qsizetype i = 0; i < commands.size(); ++i) {
        while (!socket.canReadLine()) {
            if (!socket.waitForReadyRead(5000))
                return true;
        }
        const QString reply = QString::fromUtf8(socket.readLine()).trimmed();
        if (replies)
            replies->append(reply);
    }
    return true;
}

bool Remote::listen()
{
    QLocalServer::removeServer(socketName());
    if (m_server.listen(socketName()))
        return true;

    qWarning().noquote() << "browserland: could not listen on" << socketName() << m_server.errorString();
    return false;
}

QString Remote::handle(const QString &line)
{
    const QString command = line.section(u' ', 0, 0);
    const QString rest = line.section(u' ', 1).trimmed();

    if (command == u"dispatch") {
        const QString action = rest.section(u' ', 0, 0);
        const QString args = rest.section(u' ', 1).trimmed();

        QObject *browser = m_engine->singletonInstance<QObject *>("BrowserLand", "Browser");
        QVariant ran;
        
        QMetaObject::invokeMethod(browser, "run", Q_RETURN_ARG(QVariant, ran), Q_ARG(QVariant, action),
                                  Q_ARG(QVariant, args));
        return ran.toBool() ? QStringLiteral("ok") : QStringLiteral("unknown action '%1'").arg(action);
    }

    if (command == u"activate") {
        auto *window = qobject_cast<QWindow *>(m_engine->rootObjects().value(0));
        if (!window)
            return QStringLiteral("no window yet");

        if (!rest.isEmpty())
            qputenv("XDG_ACTIVATION_TOKEN", rest.toUtf8());
        
        window->setWindowStates(window->windowStates() & ~Qt::WindowMinimized);
        window->raise();
        window->requestActivate();
        return QStringLiteral("ok");
    }

    return QStringLiteral("unknown command '%1'").arg(command);
}
