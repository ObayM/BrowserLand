#include "browser/History.h"
#include "browser/System.h"
#include "config/Config.h"
#include "config/ConfigCheck.h"

#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QTextStream>
#include <QUrl>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

namespace {

void addOptions(QCommandLineParser &parser)
{
    parser.setApplicationDescription(QStringLiteral("BrowserLand: the browser you configure like Hyprland."));
    parser.addHelpOption();
    parser.addOptions({
        {QStringLiteral("config-dir"), QStringLiteral("Read browserland.conf from <dir>."), QStringLiteral("dir")},
        {QStringLiteral("check-config"), QStringLiteral("Check the config for mistakes, print what it contains, and exit.")},
    });
    parser.addPositionalArgument(QStringLiteral("url"), QStringLiteral("Page to open instead of the homepage."),
                                 QStringLiteral("[url]"));
}

QString configDirFrom(const QCommandLineParser &parser)
{
    if (parser.isSet(QStringLiteral("config-dir")))
        return QDir(parser.value(QStringLiteral("config-dir"))).absolutePath();
    const QString fromEnv = qEnvironmentVariable("BROWSERLAND_CONFIG_DIR");
    if (!fromEnv.isEmpty())
        return QDir(fromEnv).absolutePath();
    return Config::defaultConfigDir();
}

bool wantsConfigCheck(int argc, char *argv[])
{
    for (int i = 1; i < argc; ++i) {
        if (qstrcmp(argv[i], "--check-config") == 0)
            return true;
    }
    return false;
}

int runConfigCheck(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    QCommandLineParser parser;
    addOptions(parser);
    parser.process(app);

    QTextStream out(stdout);
    return checkConfig(QDir(configDirFrom(parser)).filePath(QStringLiteral("browserland.conf")), out);
}

}

int main(int argc, char *argv[])
{
    if (wantsConfigCheck(argc, argv))
        return runConfigCheck(argc, argv);

    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    app.setApplicationName("browserland");
    app.setOrganizationName("browserland");


    QLoggingCategory::setFilterRules(QStringLiteral("js=false"));

    QCommandLineParser parser;
    addOptions(parser);
    parser.process(app);

    const QString configDir = configDirFrom(parser);
    if (configDir == Config::defaultConfigDir())
        Config::installStarterConfig(configDir);
    Config config(configDir);
    System system(System::defaultDataDir());
    History history(system.dataDir());

    QQmlApplicationEngine engine;

    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));

    const QStringList urls = parser.positionalArguments();
    if (!urls.isEmpty())
        engine.setInitialProperties({{"startUrl", QUrl::fromUserInput(urls.constFirst())}});


    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(1); },
                     Qt::QueuedConnection);

    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/BrowserLand/qml/Main.qml")));

    return app.exec();
}