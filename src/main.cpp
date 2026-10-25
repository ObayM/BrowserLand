#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

int main (int argc, char *argv[])
{
    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    app.setApplicationName("browserland");
    app.setOrganizationName("browserland");

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app, [] {QCoreApplication::exit(1); },
        Qt::QueuedConnection
    );

    engine.loadFromModule("BrowserLand", "Main");

    return app.exec();

}