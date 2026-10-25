#pragma once

#include <QHash>
#include <QList>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QVariantMap>

struct ConfigError
{
    QString file;
    int line = 0;
    QString message;

    QString toString() const;
};


struct Keybind
{
    QString sequence;
    QString action;
    QString args;

    QString file;
    int line = 0;
};


struct WidgetDecl
{
    QString name;
    QString file;

    QString slot;
};

struct SiteRule
{
    QString rule;
    QString arg;
    QString site;

    QString file;
    int line = 0;
};

struct ParsedConfig
{
    QVariantMap values;
    QList<Keybind> binds;

    QList<WidgetDecl> widgets;
    QList<SiteRule> siteRules;
    QList<ConfigError> errors;
    QStringList files;
};

class ConfigParser
{
private:
    void reset();
    void readFile(const QString &path, const QString &fromFile, int fromLine);
    void parseText(const QString &text, const QString &file);

    void parseBind(const QString &value, const QString &file, int line);
    void parseWidget(const QString &value, const QString &file, int line);
    void parseSiteRule(const QString &value, const QString &file, int line);

    QString substitute(const QString &value, const QString &file, int line);
    void addError(const QString &file, int line, const QString &message);

    ParsedConfig m_result;
    QHash<QString, QString> m_variables;

    QStringList m_fileStack;

public:
    ParsedConfig parseFile(const QString &path);
    ParsedConfig parseString(const QString &text, const QString &fileName = QStringLiteral("<string>"));

    static QVariant typedValue(const QString &raw);
    static QString keySequence(const QString &mods, const QString &key, QString *error = nullptr);
    static QString hostRegex(const QString &site);

};

