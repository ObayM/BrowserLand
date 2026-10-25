#pragma once

#include <QFileSystemWatcher>
#include <QObject>
#include <QStringList>
#include <QTimer>

class ConfigWatcher : public QObject
{
    Q_OBJECT

public:
    explicit ConfigWatcher(QObject *parent = nullptr);

    void watch(const QString &dir, const QStringList &files);

signals:
    void changed();

private:
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
};
