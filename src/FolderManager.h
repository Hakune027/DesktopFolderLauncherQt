#ifndef FOLDERMANAGER_H
#define FOLDERMANAGER_H

#include <QObject>
#include <QQmlListProperty>

class FolderManager : public QObject
{

    Q_OBJECT

    Q_PROPERTY(
        QQmlListProperty<QObject>
            folders
                READ folders
                    NOTIFY foldersChanged)

public:
    explicit FolderManager(
        QObject *parent = nullptr);

    QQmlListProperty<QObject>
    folders();

    Q_INVOKABLE
    void createFolder(
        QString name);

    Q_INVOKABLE
    void removeFolder(
        int index);

    Q_INVOKABLE
    int folderCount();

    Q_INVOKABLE
    QObject *folderAt(
        int index);

    Q_INVOKABLE
    void load();

    Q_INVOKABLE
    void save();

signals:

    void foldersChanged();

private:
    QString configPath();

    QList<QObject *> m_folders;
};

#endif