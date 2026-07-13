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

    auto item =
        new AppItem(
            info.baseName(),
            path,
            iconPath,
            this);

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

        auto item =
            new AppItem(
                info.baseName(),
                path,
                icon,
                this);

        m_items.append(item);
    }

    emit itemsChanged();
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