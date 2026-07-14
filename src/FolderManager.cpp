#include "FolderManager.h"

#include "FolderData.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QUuid>

FolderManager::FolderManager(QObject *parent)
    : QObject(parent)
{
    load();
}

QQmlListProperty<QObject>
FolderManager::folders()
{

    return QQmlListProperty<QObject>(
        this,
        &m_folders);
}

QString FolderManager::configPath()
{

    QString dir =
        QStandardPaths::writableLocation(
            QStandardPaths::AppLocalDataLocation);

    QDir().mkpath(dir);

    return dir +
           "/folders_config.json";
}

void FolderManager::createFolder(
    QString name)
{

    if (name.isEmpty())
        return;

    FolderData *folder =
        new FolderData(
            name,
            this);

    m_folders.append(folder);

    save();

    emit foldersChanged();
}

void FolderManager::removeFolder(
    int index)
{

    if (
        index < 0 ||
        index >= m_folders.size())
    {
        return;
    }

    // 删除该文件夹的数据文件(使用 folderId)
    FolderData *folder =
        qobject_cast<FolderData *>(
            m_folders[index]);

    if (folder)
    {
        QString dir =
            QStandardPaths::writableLocation(
                QStandardPaths::AppLocalDataLocation);

        QString dataFile =
            dir +
            "/" +
            folder->folderId() +
            ".json";

        QFile::remove(dataFile);

        // 同时清理旧版 name.json (如果存在)
        QString legacyFile =
            dir +
            "/" +
            folder->name() +
            ".json";

        if (legacyFile != dataFile)
        {
            QFile::remove(legacyFile);
        }
    }

    QObject *obj =
        m_folders.takeAt(index);

    obj->deleteLater();

    save();

    emit foldersChanged();
}

int FolderManager::folderCount()
{

    return m_folders.size();
}

QObject *FolderManager::folderAt(
    int index)
{

    if (
        index < 0 ||
        index >= m_folders.size())
    {
        return nullptr;
    }

    return m_folders[index];
}

void FolderManager::load()
{

    QFile file(configPath());

    if (!file.exists())
    {
        qDebug()
            << "[FolderManager] load: 配置不存在, 跳过";
        return;
    }

    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray data =
        file.readAll();

    file.close();

    QJsonDocument doc =
        QJsonDocument::fromJson(data);

    QJsonArray array =
        doc.array();

    qDebug()
        << "[FolderManager] load >>>";

    for (auto value : array)
    {

        QJsonObject obj =
            value.toObject();

        QString name =
            obj["name"].toString();

        if (name.isEmpty())
            continue;

        // 读取 folderId (旧版配置可能没有, 则生成新的)
        QString folderId =
            obj["id"].toString();

        if (folderId.isEmpty())
        {
            folderId =
                QUuid::createUuid()
                    .toString(
                        QUuid::WithoutBraces);
        }

        int wx = -1;
        int wy = -1;

        // 恢复窗口位置
        if (obj.contains("windowX") &&
            obj.contains("windowY"))
        {
            wx = obj["windowX"].toInt();
            wy = obj["windowY"].toInt();
        }

        qDebug()
            << "  "
            << name
            << folderId
            << "pos:"
            << wx << wy;

        FolderData *folder =
            new FolderData(
                name,
                folderId,
                this);

        folder->setWindowPosition(
            wx,
            wy);

        m_folders.append(folder);
    }

    qDebug()
        << "[FolderManager] load <<<";

    emit foldersChanged();

    // 如果旧版配置缺少 id, 立即保存以固化 UUID
    save();
}

void FolderManager::save()
{

    QJsonArray array;

    qDebug()
        << "[FolderManager] save >>>";

    for (QObject *obj : m_folders)
    {

        FolderData *folder =
            qobject_cast<FolderData *>(obj);

        if (!folder)
            continue;

        QJsonObject json;

        json["name"] =
            folder->name();

        json["id"] =
            folder->folderId();

        json["windowX"] =
            folder->windowX();

        json["windowY"] =
            folder->windowY();

        qDebug()
            << "  "
            << folder->name()
            << folder->folderId()
            << "pos:"
            << folder->windowX()
            << folder->windowY();

        array.append(json);
    }

    qDebug()
        << "[FolderManager] save <<<";

    QJsonDocument doc(array);

    QFile file(configPath());

    if (file.open(QIODevice::WriteOnly))
    {

        file.write(
            doc.toJson());

        file.close();
    }
}
