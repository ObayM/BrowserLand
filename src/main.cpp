#include "browser/History.h"
#include "browser/Remote.h"
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
    parser.setApplicationDescription(QStringLiteral("BrowserLand: the browser you configure like Hyprland.\n"
                                                    "Control the running one with: browserland dispatch ACTION [ARGS]"));
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

bool wantsDispatch(int argc, char *argv[])
{
    return argc > 1 && qstrcmp(argv[1], "dispatch") == 0;
}

int runDispatch(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    QTextStream err(stderr);

    QStringList words = app.arguments().mid(2);
    if (words.isEmpty()) {
        err << "usage: browserland dispatch ACTION [ARGS]\n";
        return 1;
    }
    const QString action = words.takeFirst();

    QStringList replies;
    
    if (!Remote::send({QStringLiteral("dispatch %1 %2").arg(action, words.join(u' '))}, &replies)) {
        err << "browserland isn't running\n";
        return 1;
    }

    if (replies.value(0) == u"ok")
        return 0;
    err << (replies.isEmpty() ? QStringLiteral("browserland didn't answer") : replies.constFirst()) << '\n';
    return 1;
}

}

int main(int argc, char *argv[])
{
    if (wantsConfigCheck(argc, argv))
        return runConfigCheck(argc, argv);
    
    if (wantsDispatch(argc, argv))
        return runDispatch(argc, argv);

    const QString activationToken = qEnvironmentVariable("XDG_ACTIVATION_TOKEN");

    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    app.setApplicationName("browserland");
    app.setOrganizationName("browserland");


    QLoggingCategory::setFilterRules(QStringLiteral("js=false"));

    QCommandLineParser parser;
    addOptions(parser);
    parser.process(app);

    const QStringList urls = parser.positionalArguments();
    QStringList commands;

    if (!urls.isEmpty())
        commands.append(QStringLiteral("dispatch new-tab ")
                        + QString::fromUtf8(QUrl::fromUserInput(urls.constFirst()).toEncoded()));
    
    commands.append(QStringLiteral("activate ") + activationToken);
    
    if (Remote::send(commands))
        return 0;

    const QString configDir = configDirFrom(parser);
    if (configDir == Config::defaultConfigDir())
        Config::installStarterConfig(configDir);
    Config config(configDir);
    System system(System::defaultDataDir());
    History history(system.dataDir());

    QQmlApplicationEngine engine;

    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));

    Remote remote(&engine);
    remote.listen();

    if (!urls.isEmpty())
        engine.setInitialProperties({{"startUrl", QUrl::fromUserInput(urls.constFirst())}});


    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(1); },
                     Qt::QueuedConnection);

    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/BrowserLand/qml/Main.qml")));

    return app.exec();
}