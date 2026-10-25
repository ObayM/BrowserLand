#include "config/ConfigParser.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>

#include <utility>


namespace {

constexpr int kMaxSourceDepth = 16;

bool isIdentifier(const QString &name)
{
    static const QRegularExpression re(QStringLiteral("^[A-Za-z_][A-Za-z0-9_]*$"));
    return re.match(name).hasMatch();
}

QString stripComment(const QString &line)
{
    for (int i = 0; i < line.size(); ++i) {
        
        if (line.at(i) != u'#')
            continue;
        
        const bool atStart = line.left(i).trimmed().isEmpty();

        const bool spaceBefore = i > 0 && line.at(i - 1).isSpace();
        
        const bool spaceAfter = i + 1 >= line.size() || line.at(i + 1).isSpace();
        
        if (atStart || (spaceBefore && spaceAfter))
            return line.left(i);
    }
    return line;
}

QStringList splitArgs(const QString &value)
{
    QStringList parts = value.split(u',');

    for (QString &part : parts)
        part = part.trimmed();
    
    return parts;
}

QString resolvePath(const QString &path, const QString &relativeTo)
{
    QString p = path.trimmed();
    if (p == u"~" || p.startsWith(u"~/"))
        p = QDir::homePath() + p.mid(1);
    
    if (QDir::isRelativePath(p)) {
        const QFileInfo from(relativeTo);

        const QString base = from.exists() ? from.absolutePath() : QDir::currentPath();

        p = QDir(base).filePath(p);
    }

    return QDir::cleanPath(p);
}


QString ConfigError::toString() const
{
    return QStringLiteral("%1:%2: %3").arg(QFileInfo(file).fileName()).arg(line).arg(message);
}

ParsedConfig ConfigParser::parseFile(const QString &path)
{
    reset();
    readFile(QFileInfo(path).absoluteFilePath(), QString(), 0);
    return std::exchange(m_result, {});
}

ParsedConfig ConfigParser::parseString(const QString &text, const QString &fileName)
{
    reset();
    m_fileStack.append(fileName);
    parseText(text, fileName);
    m_fileStack.clear();
    return std::exchange(m_result, {});
}

void ConfigParser::reset()
{
    m_result = {}
    m_variables.clear()
    m_fileStack.clear();
}


void ConfigParser::readFile(const QString &path, const QString &fromFile, int fromLine)
{
    const QString errorFile = fromFile.isEmpty() ? path : fromFile;

    if (m_fileStack.contains(path)) {
        addError(errorFile, fromLine, QStringLiteral("source loop: %1 is already being read").arg(path));
        return;
    }

    if (m_fileStack.size() >= kMaxSourceDepth) {
        addError(errorFile, fromLine, QStringLiteral("too many nested 'source' files"));
        return;
    }

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        addError(errorFile, fromLine, QStringLiteral("cannot open %1").arg(path));
        return;
    }

    if (!m_result.files.contains(path))
        m_result.files.append(path);

    m_fileStack.append(path);

    parseText(QString::fromUtf8(file.readAll()), path);
    m_fileStack.removeLast();
}


void ConfigParser::parseText(const QString &text, const QString &file)
{
    QStringList sections;
    const QStringList lines = text.split(u'\n');

    for (int i = 0; i < lines.size(); ++i) {
        const int lineNo = i + 1;
        
        const QString line = stripComment(lines.at(i)).trimmed();
        
        if (line.isEmpty())
            continue;

        if (line == u"}") {
            if (sections.isEmpty())
                addError(file, lineNo, QStringLiteral("'}' without a matching '{'"));
            else
                sections.removeLast();
            continue;
        }

        if (line.endsWith(u'{')) {
            const QString name = line.chopped(1).trimmed();

            if (!isIdentifier(name))
                addError(file, lineNo, QStringLiteral("invalid section name '%1' (use letters, digits and _)").arg(name));
            
            sections.append(name);
            continue;
        }

        const qsizetype eq = line.indexOf(u'=');
        if (eq < 0) {
            addError(file, lineNo, QStringLiteral("expected 'key = value' or 'section {', got '%1'").arg(line));
            continue;
        }

        const QString key = line.left(eq).trimmed();
        const QString rawValue = line.mid(eq + 1).trimmed();

        if (key.startsWith(u'$')) {
            
            const QString name = key.mid(1);
            if (!isIdentifier(name)) {
                addError(file, lineNo, QStringLiteral("invalid variable name '%1'").arg(key));
                continue;
            }
            
            m_variables.insert(name, substitute(rawValue, file, lineNo));
            continue;
        }

        if (!isIdentifier(key)) {
            addError(file, lineNo, QStringLiteral("invalid key '%1' (use letters, digits and _)").arg(key));
            continue;
        }

        const QString value = substitute(rawValue, file, lineNo);

        if (sections.isEmpty()) {
            if (key == u"source") {
                readFile(resolvePath(value, file), file, lineNo);
                continue;
            }

            if (key == u"bind") {
                parseBind(value, file, lineNo);
                continue;
            }

            if (key == u"widget") {
                parseWidget(value, file, lineNo);
                continue;
            }
        }

        m_result.values.insert((sections + QStringList{key}).join(u'.'), typedValue(value));
    }

    if (!sections.isEmpty())
        addError(file, int(lines.size()), QStringLiteral("section '%1' is missing its closing '}'").arg(sections.last()));
}


void ConfigParser::parseBind(const QString &value, const QString &file, int line)
{
    QStringList parts = splitArgs(value);
    
    if (parts.size() < 3 || parts.at(2).isEmpty()) {
        addError(file, line, QStringLiteral("bind needs 'MODS, KEY, action', got '%1'").arg(value));
        return;
    }

    QString error;

    const QString sequence = keySequence(parts.at(0), parts.at(1), &error);
    
    if (sequence.isEmpty()) {
        addError(file, line, error);
        return;
    }

    const QString args = parts.mid(3).join(QStringLiteral(", "));
    
    m_result.binds.append({sequence, parts.at(2), args, file, line});
}

void ConfigParser::parseWidget(const QString &value, const QString &file, int line)
{
    const QStringList parts = splitArgs(value);
    
    if (parts.size() != 3 || parts.contains(QString())) {
        addError(file, line, QStringLiteral("widget needs 'name, file.qml, slot', got '%1'").arg(value));
        return;
    }
    
    m_result.widgets.append({parts.at(0), resolvePath(parts.at(1), file), parts.at(2)});
}


QString ConfigParser::substitute(const QString &value, const QString &file, int line)
{
    static const QRegularExpression re(QStringLiteral("\\$([A-Za-z_][A-Za-z0-9_]*)"));

    QString out;
    qsizetype last = 0;

    auto it = re.globalMatch(value);
    
    while (it.hasNext()) {
        const auto match = it.next();
        out += value.mid(last, match.capturedStart() - last);

        const QString name = match.captured(1);
        
        if (m_variables.contains(name)) {
            out += m_variables.value(name);

        } else {
            addError(file, line, QStringLiteral("unknown variable '$%1'").arg(name));
            out += match.captured(0);
        }

        last = match.capturedEnd();
    }

    out += value.mid(last);
    return out;
}

void ConfigParser::addError(const QString &file, int line, const QString &message)
{
    m_result.errors.append({file, line, message});
}

QVariant ConfigParser::typedValue(const QString &raw)
{
    const QString v = raw.trimmed();

    if (v.size() >= 2 && v.startsWith(u'"') && v.endsWith(u'"'))
        return v.mid(1, v.size() - 2);

    const QString lower = v.toLower();

    if (lower == u"true" || lower == u"yes" || lower == u"on")
        return true;
    
    if (lower == u"false" || lower == u"no" || lower == u"off")
        return false;

    static const QRegularExpression intRe(QStringLiteral("^-?\\d+$"));
    static const QRegularExpression floatRe(QStringLiteral("^-?(\\d+\\.\\d*|\\.\\d+)$"));

    bool ok = false;
    
    if (intRe.match(v).hasMatch()) {
        const int i = v.toInt(&ok);
        
        if (ok)
            return i;
    }

    if (floatRe.match(v).hasMatch()) {
        const double d = v.toDouble(&ok);
        
        if (ok)
            return d;
    }
    return v;
}


QString ConfigParser::keySequence(const QString &mods, const QString &key, QString *error)
{
    auto fail = [error](const QString &message) {
        if (error)
            *error = message;
        return QString();
    };

    QStringList parts;
    static const QRegularExpression modSeparators(QStringLiteral("[\\s_+]+"));
    const QStringList modTokens = mods.toUpper().split(modSeparators, Qt::SkipEmptyParts);

    for (const QString &mod : modTokens) {
        QString name;

        if (mod == u"CTRL" || mod == u"CONTROL")
            name = QStringLiteral("Ctrl");
        else if (mod == u"SHIFT")
            name = QStringLiteral("Shift");
        else if (mod == u"ALT")
            name = QStringLiteral("Alt");
        else if (mod == u"SUPER" || mod == u"META" || mod == u"WIN" || mod == u"CMD")
            name = QStringLiteral("Meta");
        else
            return fail(QStringLiteral("unknown modifier '%1' (use CTRL, SHIFT, ALT or SUPER)").arg(mod));
        if (!parts.contains(name))
            parts.append(name);
    }

    static const QHash<QString, QString> aliases = {
        {QStringLiteral("ESCAPE"), QStringLiteral("Esc")},
        {QStringLiteral("ESC"), QStringLiteral("Esc")},
        {QStringLiteral("ENTER"), QStringLiteral("Return")},
        {QStringLiteral("DELETE"), QStringLiteral("Del")},
        {QStringLiteral("INSERT"), QStringLiteral("Ins")},
        {QStringLiteral("PAGEUP"), QStringLiteral("PgUp")},
        {QStringLiteral("PAGEDOWN"), QStringLiteral("PgDown")},
        {QStringLiteral("PLUS"), QStringLiteral("+")},
        {QStringLiteral("MINUS"), QStringLiteral("-")},
        {QStringLiteral("EQUAL"), QStringLiteral("=")},
        {QStringLiteral("COMMA"), QStringLiteral(",")},
        {QStringLiteral("PERIOD"), QStringLiteral(".")},
        {QStringLiteral("SLASH"), QStringLiteral("/")},
    };

    const QString k = key.trimmed();
    if (k.isEmpty())
        return fail(QStringLiteral("bind is missing a key"));
    if (k.size() == 1)
        parts.append(k.toUpper());
    else if (aliases.contains(k.toUpper()))
        parts.append(aliases.value(k.toUpper()));
    else
        parts.append(k.left(1).toUpper() + k.mid(1).toLower());

    return parts.join(u'+');
}

}