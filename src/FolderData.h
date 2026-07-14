#ifndef FOLDERDATA_H
#define FOLDERDATA_H

#include <QObject>

#include "FileManager.h"

class FolderData : public QObject
{

    Q_OBJECT

    Q_PROPERTY(
        QString name
            READ name
                CONSTANT)

    Q_PROPERTY(
        QString folderId
            READ folderId
                CONSTANT)

    Q_PROPERTY(FileManager *items READ items CONSTANT)

    Q_PROPERTY(
        int windowX
            READ windowX
                NOTIFY windowPositionChanged)

    Q_PROPERTY(
        int windowY
            READ windowY
                NOTIFY windowPositionChanged)

public:
    explicit FolderData(
        QString name,
        QObject *parent = nullptr);

    explicit FolderData(
        QString name,
        QString folderId,
        QObject *parent = nullptr);

    QString name() const;

    QString folderId() const;

    void setFolderId(
        const QString &id);

    int windowX() const;

    int windowY() const;

    Q_INVOKABLE
    void setWindowPosition(
        int x,
        int y);

    FileManager *items() const;

    Q_INVOKABLE
    void addFile(
        QString path);

    Q_INVOKABLE
    void removeFile(
        int index);

    Q_INVOKABLE void moveItemToPosition(int index, int x, int y);

    Q_INVOKABLE
    void openLocation(
        QString path);

    Q_INVOKABLE
    bool save();

signals:

    void itemsChanged();

    void windowPositionChanged();

private:
    QString m_name;

    QString m_folderId;

    int m_windowX = -1;

    int m_windowY = -1;

    FileManager *m_fileManager;
};

#endif
