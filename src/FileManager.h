#ifndef FILEMANAGER_H
#define FILEMANAGER_H

#include <QObject>
#include <QQmlListProperty>

#include "AppItem.h"

class FileManager : public QObject
{

    Q_OBJECT

    Q_PROPERTY(
        QQmlListProperty<QObject>
            items
                READ items
                    NOTIFY itemsChanged)

public:
    explicit FileManager(
        QObject *parent = nullptr);

    QQmlListProperty<QObject>
    items();

    Q_INVOKABLE
    void addFile(
        QString path);

    Q_INVOKABLE
    void moveItem(
        int from,
        int to);

    Q_INVOKABLE
    void removeFile(
        int index);

    Q_INVOKABLE
    void openLocation(
        QString path);

    Q_INVOKABLE
    void load();

    // 新增
    Q_INVOKABLE
    void save();

signals:

    void itemsChanged();

private:
    QString dataPath();

    QList<QObject *> m_items;
};

#endif