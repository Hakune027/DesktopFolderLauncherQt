#include "FileManager.h"

#include <QQmlListProperty>

#include <QFileInfo>

#include "IconProvider.h"

#include <QUrl>

FileManager::FileManager(QObject *parent)
    : QObject(parent)
{
}

QQmlListProperty<QObject> FileManager::items()
{
    return QQmlListProperty<QObject>(
        this,
        &m_items);
}

void FileManager::addFile(QString path)
{

    if (path.startsWith("file:///"))
    {
        path =
            QUrl(path)
                .toLocalFile();
    }

    QFileInfo info(path);

    if (!info.exists())
    {
        return;
    }

    QString iconPath =
        IconProvider::getIcon(path);

    auto item =
        new AppItem(
            info.baseName(),
            path,
            iconPath,
            this);

    m_items.append(item);

    emit itemsChanged();
}