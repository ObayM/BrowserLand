#include "browser/History.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QJSEngine>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

namespace {

History *s_instance = nullptr;

QString likePattern(QString text)
{
    text.replace(u'\\', QStringLiteral("\\\\")).replace(u'%', QStringLiteral("\\%")).replace(u'_', QStringLiteral("\\_"));
    return text;
}

}

History::History(const QString &dataDir, QObject *parent)
    : QObject(parent)
    , m_connection(QStringLiteral("browserland-history-%1").arg(quintptr(this)))
{
    s_instance = this;
    QDir().mkpath(dataDir);

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connection);
    db.setDatabaseName(QDir(dataDir).filePath(QStringLiteral("history.sqlite")));
    if (!db.open()) {
        qWarning().noquote() << "browserland: could not open history:" << db.lastError().text();
        return;
    }

    QSqlQuery(db).exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS pages ("
        "url TEXT PRIMARY KEY, title TEXT NOT NULL DEFAULT '', icon TEXT NOT NULL DEFAULT '', "
        "visits INTEGER NOT NULL DEFAULT 0, last_visit INTEGER NOT NULL DEFAULT 0)"));
    QSqlQuery(db).exec(QStringLiteral("ALTER TABLE pages ADD COLUMN icon TEXT NOT NULL DEFAULT ''"));
}

History::~History()
{
    if (s_instance == this)
        s_instance = nullptr;
    QSqlDatabase::database(m_connection, false).close();
    QSqlDatabase::removeDatabase(m_connection);
}

History *History::create(QQmlEngine *, QJSEngine *)
{
    Q_ASSERT_X(s_instance, "History::create", "main.cpp must create History before loading QML");

    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
    return s_instance;
}

void History::add(const QUrl &url, const QString &title, const QUrl &icon)
{
    if (url.scheme() != u"http" && url.scheme() != u"https")
        return;

    QSqlQuery query(QSqlDatabase::database(m_connection));
    query.prepare(QStringLiteral(
        "INSERT INTO pages (url, title, icon, visits, last_visit) VALUES (?, ?, ?, 1, ?) "
        "ON CONFLICT(url) DO UPDATE SET "
        "title = CASE WHEN excluded.title = '' THEN pages.title ELSE excluded.title END, "
        "icon = CASE WHEN excluded.icon = '' THEN pages.icon ELSE excluded.icon END, "
        "visits = pages.visits + 1, last_visit = excluded.last_visit"));
    
    query.addBindValue(url.toString());
    query.addBindValue(title);
    query.addBindValue(icon.toString());
    query.addBindValue(QDateTime::currentMSecsSinceEpoch());

    if (!query.exec())
        qWarning().noquote() << "browserland: could not save history:" << query.lastError().text();
}

QVariantList History::search(const QString &text, int limit) const
{
    const QStringList words = text.simplified().split(u' ', Qt::SkipEmptyParts);
    if (words.isEmpty() || limit <= 0)
        return {};

    QStringList conditions;
    for (qsizetype i = 0; i < words.size(); ++i)
        conditions.append(QStringLiteral("(url LIKE ? ESCAPE '\\' OR title LIKE ? ESCAPE '\\')"));

    // sites whose address starts with the first word come first, so "git" finds github.com
    const QString host = QStringLiteral("substr(url, instr(url, '://') + 3)");
    QSqlQuery query(QSqlDatabase::database(m_connection));
    query.prepare(QStringLiteral("SELECT url, title FROM pages WHERE %1 "
                                 "ORDER BY (%2 LIKE ? ESCAPE '\\' OR %2 LIKE ? ESCAPE '\\') DESC, "
                                 "visits DESC, last_visit DESC LIMIT ?")
                      .arg(conditions.join(QStringLiteral(" AND ")), host));

    for (const QString &word : words) {
        query.addBindValue(u'%' + likePattern(word) + u'%');
        query.addBindValue(u'%' + likePattern(word) + u'%');
    }
    query.addBindValue(likePattern(words.constFirst()) + u'%');
    query.addBindValue(QStringLiteral("www.") + likePattern(words.constFirst()) + u'%');
    query.addBindValue(limit);

    QVariantList results;
    if (!query.exec()) {
        qWarning().noquote() << "browserland: history search failed:" << query.lastError().text();
        return results;
    }
    while (query.next()) {
        results.append(QVariantMap{
            {QStringLiteral("url"), query.value(0).toString()},
            {QStringLiteral("title"), query.value(1).toString()},
        });
    }
    return results;
}

void History::clear()
{
    QSqlQuery(QSqlDatabase::database(m_connection)).exec(QStringLiteral("DELETE FROM pages"));
}

void History::setIcon(const QUrl &url, const QUrl &icon)
{
    if (icon.isEmpty())
        return;

    QSqlQuery query(QSqlDatabase::database(m_connection));
    query.prepare(QStringLiteral("UPDATE pages SET icon = ? WHERE url = ?"));
    query.addBindValue(icon.toString());
    query.addBindValue(url.toString());
    
    if (!query.exec())
        qWarning().noquote() << "browserland: could not save icon:" << query.lastError().text();
}

QVariantList History::top(int limit) const
{
    QVariantList results;
    QSqlQuery query(QSqlDatabase::database(m_connection));

    query.prepare(QStringLiteral("SELECT url, title, icon FROM pages ORDER BY visits DESC, last_visit DESC LIMIT ?"));
    query.addBindValue(limit);
    
    if (!query.exec()) {
        qWarning().noquote() << "browserland: could not read your top sites:" << query.lastError().text();
        return results;
    }

    while (query.next()) {
        results.append(QVariantMap{
            {QStringLiteral("url"), query.value(0).toString()},
            {QStringLiteral("title"), query.value(1).toString()},
            {QStringLiteral("icon"), query.value(2).toString()},
        });
    }
    return results;
}

int History::visitedToday() const
{
    QSqlQuery query(QSqlDatabase::database(m_connection));
    
    query.prepare(QStringLiteral("SELECT COUNT(*) FROM pages WHERE last_visit >= ?"));
    
    query.addBindValue(QDateTime(QDate::currentDate(), QTime(0, 0)).toMSecsSinceEpoch());
    return query.exec() && query.next() ? query.value(0).toInt() : 0;
}