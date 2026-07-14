#include "FileManager.h"

#include <QFileInfo>
#include <QUrl>
#include <QDesktopServices>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>

#include <QFile>
#include <QDir>
#include <QPoint>

#include <QStandardPaths>
#include <QSaveFile>
#include <QJsonParseError>
#include <QLoggingCategory>
#include <algorithm>

#include "IconProvider.h"

FileManager::FileManager(QObject *parent)
    : QAbstractListModel(parent)
{
}

int FileManager::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_items.size(); }

QVariant FileManager::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size() || role != ItemRole)
        return {};
    return QVariant::fromValue(static_cast<QObject *>(m_items.at(index.row())));
}

QHash<int, QByteArray> FileManager::roleNames() const { return {{ItemRole, "item"}}; }

void FileManager::setFolderInfo(
    const QString &folderId,
    const QString &folderName)
{
    m_folderId = folderId;
    m_folderName = folderName;
}

void FileManager::setGridLayout(int horizontalGridSize, int verticalGridSize,
                                int columns, int rows, bool reflow)
{
    horizontalGridSize = qMax(40, horizontalGridSize);
    verticalGridSize = qMax(40, verticalGridSize);
    columns = qMax(1, columns);
    rows = qMax(1, rows);
    if (m_horizontalGridSize == horizontalGridSize
        && m_verticalGridSize == verticalGridSize
        && m_gridColumns == columns && m_gridRows == rows)
        return;
    m_horizontalGridSize = horizontalGridSize;
    m_verticalGridSize = verticalGridSize;
    m_gridColumns = columns;
    m_gridRows = rows;
    if (!reflow || m_items.isEmpty())
        return;
    for (int i = 0; i < m_items.size(); ++i) {
        m_items.at(i)->setX((i % m_gridColumns) * m_horizontalGridSize);
        m_items.at(i)->setY((i / m_gridColumns) * m_verticalGridSize);
    }
    save();
}

void FileManager::setAllowGaps(bool value)
{
    if (m_allowGaps == value)
        return;
    m_allowGaps = value;
    if (!m_allowGaps) {
        compactItems();
        save();
    }
}

void FileManager::compactItems()
{
    QList<AppItem *> ordered = m_items;
    std::sort(ordered.begin(), ordered.end(), [](const AppItem *left, const AppItem *right) {
        return left->y() == right->y() ? left->x() < right->x() : left->y() < right->y();
    });
    for (int i = 0; i < ordered.size(); ++i) {
        ordered.at(i)->setX((i % m_gridColumns) * m_horizontalGridSize);
        ordered.at(i)->setY((i / m_gridColumns) * m_verticalGridSize);
    }
}

QString FileManager::dataPath()
{

    QString dir =
        QStandardPaths::writableLocation(
            QStandardPaths::AppLocalDataLocation);

    QDir().mkpath(dir);

    if (m_folderId.isEmpty())
    {
        return dir +
               "/folders.json";
    }

    return dir +
           "/" +
           m_folderId +
           ".json";
}

QString FileManager::legacyDataPath()
{

    QString dir =
        QStandardPaths::writableLocation(
            QStandardPaths::AppLocalDataLocation);

    if (m_folderName.isEmpty())
    {
        return QString();
    }

    return dir +
           "/" +
           m_folderName +
           ".json";
}

void FileManager::addFile(QString path)
{
    if (m_items.size() >= m_gridColumns * m_gridRows)
        return;

    if (path.startsWith("file:///"))
    {
        path =
            QUrl(path)
                .toLocalFile();
    }

    path = QDir::cleanPath(QFileInfo(path).absoluteFilePath());
    QFileInfo info(path);

    if (!info.exists())
    {
        return;
    }

    // 防止重复添加

    for (AppItem *item : m_items)
    {
        if (item &&
            QString::compare(QDir::cleanPath(item->path()), path, Qt::CaseInsensitive) == 0)
        {
            return;
        }
    }

    QString iconPath =
        IconProvider::getIcon(path);

    // 自动找一个空闲网格位置
    const int maxCols = m_gridColumns;
    int newX = 0, newY = 0;
    bool found = false;

    for (int row = 0; !found; row++) {
        for (int col = 0; col < maxCols; col++) {
            int gx = col * m_horizontalGridSize;
            int gy = row * m_verticalGridSize;
            bool occupied = false;
            for (AppItem *existing : m_items) {
                if (existing &&
                    existing->x() == gx &&
                    existing->y() == gy) {
                    occupied = true;
                    break;
                }
            }
            if (!occupied) {
                newX = gx;
                newY = gy;
                found = true;
                break;
            }
        }
    }

    auto item =
        new AppItem(
            info.baseName(),
            path,
            iconPath,
            this);
    item->setX(newX);
    item->setY(newY);

    beginInsertRows({}, m_items.size(), m_items.size());
    m_items.append(item);
    endInsertRows();

    save();

    emit itemsChanged();
}

bool FileManager::save()
{

    QJsonArray array;

    for (AppItem *item : m_items)
    {
        if (!item)
            continue;

        QJsonObject json;

        json["name"] =
            item->name();

        json["path"] =
            item->path();

        json["icon"] =
            item->icon();

        json["x"] =
            item->x();

        json["y"] =
            item->y();

        array.append(json);
    }

    QJsonDocument doc(array);

    QSaveFile file(dataPath());

    if (file.open(QIODevice::WriteOnly))
    {

        if (file.write(doc.toJson()) < 0 || !file.commit()) {
            qWarning() << "Failed to save folder data:" << file.errorString();
            return false;
        }
        return true;
    }
    qWarning() << "Failed to open folder data for writing:" << file.errorString();
    return false;
}

void FileManager::load()
{
    if (!m_items.isEmpty()) {
        beginResetModel();
        qDeleteAll(m_items);
        m_items.clear();
        endResetModel();
    }

    QString path = dataPath();

    QFile file(path);

    // 迁移: 如果 UUID 文件不存在, 尝试从旧版 name.json 复制
    if (!file.exists())
    {

        QString legacyPath =
            legacyDataPath();

        if (!legacyPath.isEmpty())
        {

            QFile legacyFile(legacyPath);

            if (legacyFile.exists())
            {

                // 复制旧数据到新路径
                legacyFile.copy(path);

                qDebug()
                    << "FileManager: 迁移数据"
                    << legacyPath
                    << "->"
                    << path;
            }
        }
    }

    // 重新打开(可能已从旧版迁移)
    if (!file.exists())
        return;

    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray data =
        file.readAll();

    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);
    if (error.error != QJsonParseError::NoError || !doc.isArray()) {
        qWarning() << "Invalid folder data, preserving file:" << path << error.errorString();
        QFile::copy(path, path + ".corrupt");
        return;
    }

    QJsonArray array =
        doc.array();

    // 跟踪已占用位置，解决冲突
    QList<QPoint> occupied;
    const int maxCols = m_gridColumns;

    beginResetModel();
    for (auto value : array)
    {

        QJsonObject obj =
            value.toObject();

        QString path =
            obj["path"].toString();

        QFileInfo info(path);

        if (!info.exists())
            continue;

        QString icon =
            IconProvider::getIcon(path);

        int x = obj["x"].toInt();
        int y = obj["y"].toInt();

        // 检测位置冲突，冲突时自动找空位
        QPoint pos(x, y);
        if (occupied.contains(pos)) {
            bool found = false;
            for (int row = 0; !found; row++) {
                for (int col = 0; col < maxCols; col++) {
                    QPoint candidate(col * m_horizontalGridSize,
                                     row * m_verticalGridSize);
                    if (!occupied.contains(candidate)) {
                        x = candidate.x();
                        y = candidate.y();
                        occupied.append(candidate);
                        found = true;
                        break;
                    }
                }
            }
        } else {
            occupied.append(pos);
        }

        auto item =
            new AppItem(
                info.baseName(),
                path,
                icon,
                this);
        item->setX(x);
        item->setY(y);
        m_items.append(item);
    }

    endResetModel();
    emit itemsChanged();

    // 如果加载时有位置冲突被修正，持久化保存
    save();
}

void FileManager::removeFile(int index)
{

    if (index < 0 ||
        index >= m_items.size())
    {
        return;
    }

    beginRemoveRows({}, index, index);
    AppItem *obj = m_items.takeAt(index);
    endRemoveRows();

    obj->deleteLater();

    if (!m_allowGaps)
        compactItems();

    save();

    emit itemsChanged();
}

void FileManager::openLocation(QString path)
{

    QFileInfo info(path);

    if (!info.exists())
        return;

    QDesktopServices::openUrl(

        QUrl::fromLocalFile(
            info.absolutePath())

    );
}

void FileManager::moveItem(
    int from,
    int to)
{

    if (from < 0 ||
        to < 0 ||
        from >= m_items.size() ||
        to >= m_items.size())
    {
        return;
    }

    if (from == to)
        return;

    const int destination = to > from ? to + 1 : to;
    beginMoveRows({}, from, from, {}, destination);
    m_items.move(from, to);
    endMoveRows();

    save();

    emit itemsChanged();
}

void FileManager::moveItemToPosition(int index, int x, int y)
{
    if (index < 0 || index >= m_items.size())
        return;
    AppItem *dragged = m_items.at(index);
    AppItem *target = nullptr;
    for (int i = 0; i < m_items.size(); ++i) {
        if (i != index && m_items.at(i)->x() == x && m_items.at(i)->y() == y) {
            target = m_items.at(i);
            break;
        }
    }
    const int oldX = dragged->x();
    const int oldY = dragged->y();
    dragged->setX(x);
    dragged->setY(y);
    if (target) {
        target->setX(oldX);
        target->setY(oldY);
    }
    if (!m_allowGaps)
        compactItems();
    save();
}
