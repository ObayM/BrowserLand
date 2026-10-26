#pragma once

#include <QList>
#include <QNetworkCookie>
#include <QObject>
#include <QPointer>
#include <QtQml/qqmlregistration.h>

class QWebEngineCookieStore;

class Cookies : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QObject *profile READ profile WRITE setProfile NOTIFY profileChanged)

public:
    explicit Cookies(QObject *parent = nullptr);

    QObject *profile() const;
    void setProfile(QObject *profile);

    Q_INVOKABLE int count(const QString &host) const;
    Q_INVOKABLE void clear(const QString &host);

signals:
    void profileChanged();
    void changed();

private:
    QPointer<QObject> m_profile;
    QPointer<QWebEngineCookieStore> m_store;
    QList<QNetworkCookie> m_cookies;
};
