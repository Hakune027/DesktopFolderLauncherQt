#ifndef FOLDERMANAGER_H
#define FOLDERMANAGER_H

#include <QAbstractListModel>

class FolderManager : public QAbstractListModel
{

    Q_OBJECT
    Q_PROPERTY(int defaultGridColumns READ defaultGridColumns WRITE setDefaultGridColumns NOTIFY defaultSettingsChanged)
    Q_PROPERTY(int defaultGridRows READ defaultGridRows WRITE setDefaultGridRows NOTIFY defaultSettingsChanged)
    Q_PROPERTY(int defaultIconSize READ defaultIconSize WRITE setDefaultIconSize NOTIFY defaultSettingsChanged)
    Q_PROPERTY(int defaultIconSpacing READ defaultIconSpacing WRITE setDefaultIconSpacing NOTIFY defaultSettingsChanged)
    Q_PROPERTY(int defaultEdgePadding READ defaultEdgePadding WRITE setDefaultEdgePadding NOTIFY defaultSettingsChanged)
    Q_PROPERTY(bool defaultOverflowMode READ defaultOverflowMode WRITE setDefaultOverflowMode NOTIFY defaultSettingsChanged)
    Q_PROPERTY(bool defaultFrostedGlass READ defaultFrostedGlass WRITE setDefaultFrostedGlass NOTIFY defaultSettingsChanged)
    Q_PROPERTY(QObject *defaultFolderData READ defaultFolderData CONSTANT)

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

    int defaultGridColumns() const { return m_defaultGridColumns; }
    int defaultGridRows() const { return m_defaultGridRows; }
    int defaultIconSize() const { return m_defaultIconSize; }
    int defaultIconSpacing() const { return m_defaultIconSpacing; }
    int defaultEdgePadding() const { return m_defaultEdgePadding; }
    bool defaultOverflowMode() const { return m_defaultOverflowMode; }
    bool defaultFrostedGlass() const { return m_defaultFrostedGlass; }
    QObject *defaultFolderData() const;
    void setDefaultGridColumns(int value);
    void setDefaultGridRows(int value);
    void setDefaultIconSize(int value);
    void setDefaultIconSpacing(int value);
    void setDefaultEdgePadding(int value);
    void setDefaultOverflowMode(bool value);
    void setDefaultFrostedGlass(bool value);

signals:

    void foldersChanged();
    void persistenceError(const QString &message);
    void defaultSettingsChanged();

private:
    QString configPath() const;
    QString defaultsPath() const;
    void loadDefaults();
    bool saveDefaults();
    void applyDefaultsToFolder(class FolderData *folder) const;

    QList<class FolderData *> m_folders;
    int m_defaultGridColumns = 3;
    int m_defaultGridRows = 2;
    int m_defaultIconSize = 64;
    int m_defaultIconSpacing = 36;
    int m_defaultEdgePadding = 20;
    bool m_defaultOverflowMode = false;
    bool m_defaultFrostedGlass = false;
    class FolderData *m_defaultFolder = nullptr;
};

#endif
