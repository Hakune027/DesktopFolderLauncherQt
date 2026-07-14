#ifndef FILEMANAGER_H
#define FILEMANAGER_H

#include <QAbstractListModel>

#include "AppItem.h"

class FileManager : public QAbstractListModel
{

    Q_OBJECT

public:
    enum Roles { ItemRole = Qt::UserRole + 1 };
    explicit FileManager(
        QObject *parent = nullptr);

    void setFolderInfo(
        const QString &folderId,
        const QString &folderName);

    void setGridLayout(int horizontalGridSize, int verticalGridSize,
                       int columns, int rows, bool reflow = true);
    void setAllowGaps(bool value);
    void setAllowOverflow(bool value);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE
    void addFile(
        QString path);

    Q_INVOKABLE
    void moveItem(
        int from,
        int to);

    Q_INVOKABLE void moveItemToPosition(int index, int x, int y);

    Q_INVOKABLE
    void removeFile(
        int index);

    Q_INVOKABLE
    void openLocation(
        QString path);

    Q_INVOKABLE
    void load();

    Q_INVOKABLE
    bool save();

    Q_INVOKABLE QObject *itemAt(int index) const;

signals:

    void itemsChanged();

private:
    void compactItems();

    QString dataPath();

    QString legacyDataPath();

    QList<AppItem *> m_items;

    QString m_folderId;

    QString m_folderName;
    int m_horizontalGridSize = 100;
    int m_verticalGridSize = 100;
    int m_gridColumns = 3;
    int m_gridRows = 2;
    bool m_allowGaps = true;
    bool m_allowOverflow = false;
};

#endif
