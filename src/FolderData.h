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
                NOTIFY nameChanged)

    Q_PROPERTY(
        QString folderId
            READ folderId
                CONSTANT)

    Q_PROPERTY(FileManager *items READ items CONSTANT)
    Q_PROPERTY(int itemCount READ itemCount NOTIFY itemsChanged)

    Q_PROPERTY(
        int windowX
            READ windowX
                NOTIFY windowPositionChanged)

    Q_PROPERTY(
        int windowY
            READ windowY
                NOTIFY windowPositionChanged)

    Q_PROPERTY(int cornerRadius READ cornerRadius WRITE setCornerRadius NOTIFY appearanceChanged)
    Q_PROPERTY(QString backgroundStyle READ backgroundStyle WRITE setBackgroundStyle NOTIFY appearanceChanged)
    Q_PROPERTY(qreal backgroundOpacity READ backgroundOpacity WRITE setBackgroundOpacity NOTIFY appearanceChanged)
    Q_PROPERTY(int iconSize READ iconSize WRITE setIconSize NOTIFY appearanceChanged)
    Q_PROPERTY(int iconSpacing READ iconSpacing WRITE setIconSpacing NOTIFY appearanceChanged)
    Q_PROPERTY(int edgePadding READ edgePadding WRITE setEdgePadding NOTIFY appearanceChanged)
    Q_PROPERTY(int gridColumns READ gridColumns WRITE setGridColumns NOTIFY appearanceChanged)
    Q_PROPERTY(int gridRows READ gridRows WRITE setGridRows NOTIFY appearanceChanged)
    Q_PROPERTY(bool showFolderName READ showFolderName WRITE setShowFolderName NOTIFY appearanceChanged)
    Q_PROPERTY(bool showIconNames READ showIconNames WRITE setShowIconNames NOTIFY appearanceChanged)
    Q_PROPERTY(bool showIconBorder READ showIconBorder WRITE setShowIconBorder NOTIFY appearanceChanged)
    Q_PROPERTY(QString iconTone READ iconTone WRITE setIconTone NOTIFY appearanceChanged)
    Q_PROPERTY(bool allowIconGaps READ allowIconGaps WRITE setAllowIconGaps NOTIFY appearanceChanged)
    Q_PROPERTY(bool lockPosition READ lockPosition WRITE setLockPosition NOTIFY interactionChanged)
    Q_PROPERTY(bool doubleClickToLaunch READ doubleClickToLaunch WRITE setDoubleClickToLaunch NOTIFY interactionChanged)
    Q_PROPERTY(bool frostedGlass READ frostedGlass WRITE setFrostedGlass NOTIFY appearanceChanged)
    Q_PROPERTY(QString borderStyle READ borderStyle WRITE setBorderStyle NOTIFY appearanceChanged)
    Q_PROPERTY(qreal borderOpacity READ borderOpacity WRITE setBorderOpacity NOTIFY appearanceChanged)
    Q_PROPERTY(bool overflowMode READ overflowMode WRITE setOverflowMode NOTIFY appearanceChanged)
    Q_PROPERTY(QString expansionDirection READ expansionDirection WRITE setExpansionDirection NOTIFY appearanceChanged)
    Q_PROPERTY(QString overflowCover READ overflowCover WRITE setOverflowCover NOTIFY appearanceChanged)

public:
    explicit FolderData(
        QString name,
        QObject *parent = nullptr);

    explicit FolderData(
        QString name,
        QString folderId,
        QObject *parent = nullptr);

    QString name() const;
    void setName(const QString &name);

    QString folderId() const;

    void setFolderId(
        const QString &id);

    int windowX() const;

    int windowY() const;

    int cornerRadius() const;
    QString backgroundStyle() const;
    qreal backgroundOpacity() const;
    int iconSize() const;
    int iconSpacing() const;
    int edgePadding() const;
    int gridColumns() const;
    int gridRows() const;
    bool showFolderName() const;
    bool showIconNames() const;
    bool showIconBorder() const;
    QString iconTone() const;
    bool allowIconGaps() const;
    bool lockPosition() const;
    bool doubleClickToLaunch() const;
    bool frostedGlass() const;
    QString borderStyle() const;
    qreal borderOpacity() const;
    bool overflowMode() const;
    QString expansionDirection() const;
    QString overflowCover() const;

    void setCornerRadius(int value);
    void setBackgroundStyle(const QString &value);
    void setBackgroundOpacity(qreal value);
    void setIconSize(int value);
    void setIconSpacing(int value);
    void setEdgePadding(int value);
    void setGridColumns(int value);
    void setGridRows(int value);
    void setShowFolderName(bool value);
    void setShowIconNames(bool value);
    void setShowIconBorder(bool value);
    void setIconTone(const QString &value);
    void setAllowIconGaps(bool value);
    void setLockPosition(bool value);
    void setDoubleClickToLaunch(bool value);
    void setFrostedGlass(bool value);
    void setBorderStyle(const QString &value);
    void setBorderOpacity(qreal value);
    void setOverflowMode(bool value);
    void setExpansionDirection(const QString &value);
    void setOverflowCover(const QString &value);
    void beginRestore();
    void endRestore();

    Q_INVOKABLE
    void setWindowPosition(
        int x,
        int y);

    FileManager *items() const;
    int itemCount() const;

    Q_INVOKABLE
    void addFile(
        QString path);

    Q_INVOKABLE
    void removeFile(
        int index);

    Q_INVOKABLE void moveItemToPosition(int index, int x, int y);
    Q_INVOKABLE void moveItem(int from, int to);

    Q_INVOKABLE
    void openLocation(
        QString path);

    Q_INVOKABLE
    bool save();

signals:
    void nameChanged();

    void itemsChanged();

    void windowPositionChanged();

    void appearanceChanged();
    void interactionChanged();
    void persistenceError(const QString &message);

private:
    void updateGridLayout();

    QString m_name;

    QString m_folderId;

    int m_windowX = -1;

    int m_windowY = -1;

    int m_cornerRadius = 30;
    QString m_backgroundStyle = QStringLiteral("black");
    qreal m_backgroundOpacity = 0.8;
    int m_iconSize = 64;
    int m_iconSpacing = 36;
    int m_edgePadding = 20;
    int m_gridColumns = 3;
    int m_gridRows = 2;
    bool m_showFolderName = true;
    bool m_showIconNames = true;
    bool m_showIconBorder = false;
    QString m_iconTone = QStringLiteral("original");
    bool m_allowIconGaps = true;
    bool m_lockPosition = false;
    bool m_doubleClickToLaunch = false;
    bool m_frostedGlass = false;
    QString m_borderStyle = QStringLiteral("subtle");
    qreal m_borderOpacity = 1.0;
    bool m_overflowMode = false;
    QString m_expansionDirection = QStringLiteral("down");
    QString m_overflowCover;

    FileManager *m_fileManager;
    bool m_restoring = false;
};

#endif
