#include "config/ConfigWatcher.h"

#include <QFileInfo>

ConfigWatcher::ConfigWatcher(QObject *parent)
    : QObject(parent)
{
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(150);
    connect(&m_debounce, &QTimer::timeout, this, &ConfigWatcher::changed);

    const auto restart = [this] { m_debounce.start(); };
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, restart);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, restart);
}

void ConfigWatcher::watch(const QString &dir, const QStringList &files)
{
    if (!m_watcher.files().isEmpty())
        m_watcher.removePaths(m_watcher.files());

    if (!m_watcher.directories().isEmpty())
        m_watcher.removePaths(m_watcher.directories());

    QStringList paths;
    if (QFileInfo(dir).isDir())
        paths.append(dir);

    for (const QString &file : files) {
        if (!file.startsWith(u':') && QFileInfo::exists(file))
            paths.append(file);
    }

    if (!paths.isEmpty())
        m_watcher.addPaths(paths);
}
