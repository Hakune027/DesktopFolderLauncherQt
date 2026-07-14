#include "FolderManager.h"

FolderManager::FolderManager(QObject *parent)
    : QObject(parent)
{
}

QVariantList FolderManager::folders() const
{
    return m_folders;
}

void FolderManager::createFolder(
    QString name)
{

    if (name.isEmpty())
        return;

    QVariantMap folder;

    folder["name"] = name;

    folder["x"] = 300;

    folder["y"] = 200;

    m_folders.append(folder);

    emit foldersChanged();
}

void FolderManager::removeFolder(
    int index)
{

    if (index < 0 ||
        index >= m_folders.size())
        return;

    m_folders.removeAt(index);

    emit foldersChanged();
}