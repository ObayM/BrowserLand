#include "browser/Cookies.h"

#include <QQuickWebEngineProfile>
#include <QWebEngineCookieStore>

#include <algorithm>

namespace {

bool appliesTo(const QNetworkCookie &cookie, const QString &host)
{
    QString domain = cookie.domain();
    if (domain.startsWith(u'.'))
        domain.remove(0, 1);
    const QString suffix = u'.' + domain;
    return !domain.isEmpty() && (host == domain || host.endsWith(suffix));
}

}

Cookies::Cookies(QObject *parent)
    : QObject(parent)
{
}

QObject *Cookies::profile() const
{
    return m_profile;
}

void Cookies::setProfile(QObject *profile)
{
    if (m_profile == profile)
        return;

    if (m_store)
        m_store->disconnect(this);
    
    m_profile = profile;
    m_cookies.clear();

    auto *webProfile = qobject_cast<QQuickWebEngineProfile *>(profile);
    QWebEngineCookieStore *store = webProfile ? webProfile->cookieStore() : nullptr;
    
    m_store = store;

    if (store) {
        connect(store, &QWebEngineCookieStore::cookieAdded, this, [this](const QNetworkCookie &cookie) {
            m_cookies.removeIf([&](const QNetworkCookie &known) { return known.hasSameIdentifier(cookie); });
            m_cookies.append(cookie);
            emit changed();
        });

        connect(store, &QWebEngineCookieStore::cookieRemoved, this, [this](const QNetworkCookie &cookie) {
            if (m_cookies.removeIf([&](const QNetworkCookie &known) { return known.hasSameIdentifier(cookie); }) > 0)
                emit changed();
        });
        store->loadAllCookies();
    }

    emit profileChanged();
    emit changed();
}

int Cookies::count(const QString &host) const
{
    return int(std::count_if(m_cookies.cbegin(), m_cookies.cend(),
                             [&](const QNetworkCookie &cookie) { return appliesTo(cookie, host); }));
}

void Cookies::clear(const QString &host)
{
    if (!m_store)
        return;

    const QList<QNetworkCookie> cookies = m_cookies;

    for (const QNetworkCookie &cookie : cookies) {
        
        if (appliesTo(cookie, host))
            m_store->deleteCookie(cookie);
    }
}
