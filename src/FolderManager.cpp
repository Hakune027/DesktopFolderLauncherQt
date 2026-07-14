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
#include <QSaveFile>
#include <QJsonParseError>
#include <QRegularExpression>
#include <utility>

FolderManager::FolderManager(QObject *parent)
    : QAbstractListModel(parent)
{
    load();
}

int FolderManager::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_folders.size(); }

QVariant FolderManager::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_folders.size() || role != FolderRole)
        return {};
    return QVariant::fromValue(static_cast<QObject *>(m_folders.at(index.row())));
}

QHash<int, QByteArray> FolderManager::roleNames() const { return {{FolderRole, "folderData"}}; }

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

    name = name.trimmed();
    if (name.isEmpty() || name.size() > 80 || name.contains(QRegularExpression(QStringLiteral("[\\x00-\\x1f]"))))
        return;
    for (const FolderData *folder : std::as_const(m_folders))
        if (folder->name().compare(name, Qt::CaseInsensitive) == 0)
            return;

    FolderData *folder =
        new FolderData(
            name,
            this);

    beginInsertRows({}, m_folders.size(), m_folders.size());
    m_folders.append(folder);
    endInsertRows();

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
    FolderData *folder = m_folders[index];

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

    beginRemoveRows({}, index, index);
    FolderData *obj = m_folders.takeAt(index);
    endRemoveRows();

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

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);
    if (error.error != QJsonParseError::NoError || !doc.isArray()) {
        qWarning() << "Invalid folder configuration, preserving file:" << configPath() << error.errorString();
        QFile::copy(configPath(), configPath() + ".corrupt");
        return;
    }

    QJsonArray array =
        doc.array();

    qDebug()
        << "[FolderManager] load >>>";

    beginResetModel();
    qDeleteAll(m_folders);
    m_folders.clear();
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

    endResetModel();
    emit foldersChanged();

    // 如果旧版配置缺少 id, 立即保存以固化 UUID
    save();
}

bool FolderManager::save()
{

    QJsonArray array;

    qDebug()
        << "[FolderManager] save >>>";

    for (FolderData *folder : m_folders)
    {
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

    QSaveFile file(configPath());

    if (file.open(QIODevice::WriteOnly))
    {

        if (file.write(doc.toJson()) < 0 || !file.commit()) {
            qWarning() << "Failed to save folder configuration:" << file.errorString();
            return false;
        }
        return true;
    }
    qWarning() << "Failed to open folder configuration for writing:" << file.errorString();
    return false;
}
