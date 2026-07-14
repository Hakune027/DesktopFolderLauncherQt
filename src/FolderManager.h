#ifndef FOLDERMANAGER_H
#define FOLDERMANAGER_H

#include <QAbstractListModel>

class FolderManager : public QAbstractListModel
{

    Q_OBJECT

public:
    enum Roles { FolderRole = Qt::UserRole + 1 };
    explicit FolderManager(
        QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

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
    bool save();

signals:

    void foldersChanged();

private:
    QString configPath();

    QList<class FolderData *> m_folders;
};

#endif
