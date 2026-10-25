#include "config/ConfigCheck.h"

#include "config/ConfigParser.h"

#include <QFileInfo>
#include <QTextStream>

namespace {

QString typeName(const QVariant &value)
{
    switch (value.typeId()) {
    case QMetaType::Bool:
        return QStringLiteral("yes/no");
    case QMetaType::Int:
        return QStringLiteral("number");
    case QMetaType::Double:
        return QStringLiteral("decimal");
    default:
        return QStringLiteral("text");
    }
}

QString display(const QVariant &value)
{
    if (value.typeId() == QMetaType::Bool)
        return value.toBool() ? QStringLiteral("true") : QStringLiteral("false");
    return value.toString();
}

void printTable(QTextStream &out, const QList<QStringList> &rows)
{
    if (rows.isEmpty()) {
        out << "  (none)\n";
        return;
    }

    QList<qsizetype> widths;
    for (const QStringList &row : rows) {
        for (int i = 0; i < row.size(); ++i) {
            if (widths.size() <= i)
                widths.append(0);
            widths[i] = qMax(widths[i], row.at(i).size());
        }
    }

    for (const QStringList &row : rows) {
        QString line;
        for (int i = 0; i < row.size(); ++i)
            line += i + 1 < row.size() ? row.at(i).leftJustified(widths.at(i) + 2) : row.at(i);
        out << "  " << line.trimmed() << '\n';
    }
}

}

int checkConfig(const QString &file, QTextStream &out)
{
    const ParsedConfig config = ConfigParser().parseFile(file);

    out << "Checking " << QFileInfo(file).absoluteFilePath() << '\n';
    for (const QString &sourced : config.files.mid(1))
        out << "  also read " << sourced << '\n';

    out << "\nSettings\n";

    QList<QStringList> rows;
    for (auto it = config.values.cbegin(); it != config.values.cend(); ++it)
        rows.append({it.key(), display(it.value()), QStringLiteral("(%1)").arg(typeName(it.value()))});
    printTable(out, rows);

    out << "\nKeybinds\n";

    rows.clear();

    for (const Keybind &bind : config.binds)
        rows.append({bind.sequence, bind.action, bind.args});
    printTable(out, rows);

    out << "\nWidgets\n";

    rows.clear();

    for (const WidgetDecl &widget : config.widgets)
        rows.append({widget.name, widget.slot, widget.file});

    printTable(out, rows);

    out << '\n';
    if (config.errors.isEmpty()) {
        out << "OK: no errors.\n";
        out.flush();
        return 0;
    }

    out << config.errors.size() << (config.errors.size() == 1 ? " error:\n" : " errors:\n");
    for (const ConfigError &error : config.errors)
        out << "  " << error.toString() << '\n';
    out.flush();
    return 1;
}
