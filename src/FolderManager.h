#ifndef FOLDERMANAGER_H
#define FOLDERMANAGER_H

#include <QObject>
#include <QVariantList>

class FolderManager : public QObject
{

    Q_OBJECT

    Q_PROPERTY(
        QVariantList folders
            READ folders
                NOTIFY foldersChanged)

public:
    explicit FolderManager(
        QObject *parent = nullptr);

    QVariantList folders() const;

    Q_INVOKABLE
    void createFolder(
        QString name);

    Q_INVOKABLE
    void removeFolder(
        int index);

signals:

    void foldersChanged();

private:
    QVariantList m_folders;
};

#endif