#include "FileManager.h"

#include <QQmlListProperty>

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

#include "IconProvider.h"

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

QString FileManager::dataPath()
{

    QString dir =
        QStandardPaths::writableLocation(
            QStandardPaths::AppLocalDataLocation);

    QDir().mkpath(dir);

    return dir +
           "/folders.json";
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

    // 防止重复添加

    for (QObject *obj : m_items)
    {

        AppItem *item =
            qobject_cast<AppItem *>(obj);

        if (item &&
            item->path() == path)
        {
            return;
        }
    }

    QString iconPath =
        IconProvider::getIcon(path);

    // 自动找一个空闲网格位置
    const int gridSize = 100;
    const int maxCols = 3;
    int newX = 0, newY = 0;
    bool found = false;

    for (int row = 0; !found; row++) {
        for (int col = 0; col < maxCols; col++) {
            int gx = col * gridSize;
            int gy = row * gridSize;
            bool occupied = false;
            for (QObject *obj : m_items) {
                AppItem *existing =
                    qobject_cast<AppItem *>(obj);
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

    m_items.append(item);

    save();

    emit itemsChanged();
}

void FileManager::save()
{

    QJsonArray array;

    for (QObject *obj : m_items)
    {

        AppItem *item =
            qobject_cast<AppItem *>(obj);

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

    QFile file(dataPath());

    if (file.open(QIODevice::WriteOnly))
    {

        file.write(
            doc.toJson());

        file.close();
    }
}

void FileManager::load()
{

    QFile file(dataPath());

    if (!file.exists())
        return;

    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray data =
        file.readAll();

    file.close();

    QJsonDocument doc =
        QJsonDocument::fromJson(data);

    QJsonArray array =
        doc.array();

    // 跟踪已占用位置，解决冲突
    QList<QPoint> occupied;
    const int gridSize = 100;
    const int maxCols = 3;

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
                    QPoint candidate(col * gridSize,
                                     row * gridSize);
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

    QObject *obj =
        m_items.takeAt(index);

    obj->deleteLater();

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

    QObject *item =
        m_items.takeAt(from);

    m_items.insert(
        to,
        item);

    save();

    emit itemsChanged();
}