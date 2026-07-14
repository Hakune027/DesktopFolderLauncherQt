#include "FolderData.h"

#include <QUuid>
#include <QDebug>
#include <QStringList>

FolderData::FolderData(
    QString name,
    QObject *parent)

    : FolderData(
          name,
          QUuid::createUuid()
              .toString(
                  QUuid::WithoutBraces),
          parent)
{
}

FolderData::FolderData(
    QString name,
    QString folderId,
    QObject *parent)

    : QObject(parent),
      m_name(name),
      m_folderId(folderId)
{

    m_fileManager =
        new FileManager(this);

    m_fileManager->setFolderInfo(
        m_folderId,
        m_name);

    m_fileManager->load();

    connect(
        m_fileManager,
        &FileManager::itemsChanged,
        this,
        &FolderData::itemsChanged);
    connect(m_fileManager, &FileManager::persistenceError,
            this, &FolderData::persistenceError);
}

QString FolderData::name() const
{
    return m_name;
}

QString FolderData::folderId() const
{
    return m_folderId;
}

void FolderData::setFolderId(
    const QString &id)
{
    m_folderId = id;
}

int FolderData::windowX() const
{
    return m_windowX;
}

int FolderData::windowY() const
{
    return m_windowY;
}

int FolderData::cornerRadius() const { return m_cornerRadius; }
QString FolderData::backgroundStyle() const { return m_backgroundStyle; }
qreal FolderData::backgroundOpacity() const { return m_backgroundOpacity; }
int FolderData::iconSize() const { return m_iconSize; }
int FolderData::iconSpacing() const { return m_iconSpacing; }
int FolderData::edgePadding() const { return m_edgePadding; }
int FolderData::gridColumns() const { return m_gridColumns; }
int FolderData::gridRows() const { return m_gridRows; }

void FolderData::updateGridLayout()
{
    const int effectiveSpacing = m_showIconNames ? m_iconSpacing : qMax(4, m_iconSpacing - 20);
    m_fileManager->setGridLayout(m_iconSize + effectiveSpacing,
                                 m_iconSize + effectiveSpacing,
                                 m_gridColumns, m_gridRows);
}
bool FolderData::showFolderName() const { return m_showFolderName; }
bool FolderData::showIconNames() const { return m_showIconNames; }
bool FolderData::showIconBorder() const { return m_showIconBorder; }
QString FolderData::iconTone() const { return m_iconTone; }
bool FolderData::allowIconGaps() const { return m_allowIconGaps; }
bool FolderData::lockPosition() const { return m_lockPosition; }
bool FolderData::frostedGlass() const { return m_frostedGlass; }
QString FolderData::borderStyle() const { return m_borderStyle; }
bool FolderData::overflowMode() const { return m_overflowMode; }
QString FolderData::expansionDirection() const { return m_expansionDirection; }
QString FolderData::overflowCover() const { return m_overflowCover; }

void FolderData::setCornerRadius(int value)
{
    value = qBound(0, value, 60);
    if (m_cornerRadius == value)
        return;
    m_cornerRadius = value;
    emit appearanceChanged();
}

void FolderData::setBackgroundStyle(const QString &value)
{
    const QString normalized = value == QStringLiteral("white")
        ? QStringLiteral("white") : QStringLiteral("black");
    if (m_backgroundStyle == normalized)
        return;
    m_backgroundStyle = normalized;
    emit appearanceChanged();
}

void FolderData::setBackgroundOpacity(qreal value)
{
    value = qBound(0.1, value, 1.0);
    if (qFuzzyCompare(m_backgroundOpacity, value))
        return;
    m_backgroundOpacity = value;
    emit appearanceChanged();
}

void FolderData::setIconSize(int value)
{
    value = qBound(32, value, 96);
    if (m_iconSize == value)
        return;
    m_iconSize = value;
    updateGridLayout();
    emit appearanceChanged();
}

void FolderData::setIconSpacing(int value)
{
    value = qBound(24, value, 80);
    if (m_iconSpacing == value)
        return;
    m_iconSpacing = value;
    updateGridLayout();
    emit appearanceChanged();
}

void FolderData::setEdgePadding(int value)
{
    value = qBound(0, value, 80);
    if (m_edgePadding == value)
        return;
    m_edgePadding = value;
    emit appearanceChanged();
}

void FolderData::setGridColumns(int value)
{
    value = qBound(1, value, 12);
    int rows = m_gridRows;
    if (!m_overflowMode) {
        const int requiredRows = qMax(1, (m_fileManager->rowCount() + value - 1) / value);
        rows = qMax(rows, requiredRows);
    }
    if (m_gridColumns == value && m_gridRows == rows)
        return;
    m_gridColumns = value;
    m_gridRows = rows;
    updateGridLayout();
    emit appearanceChanged();
}

void FolderData::setGridRows(int value)
{
    value = qBound(1, value, 12);
    int columns = m_gridColumns;
    if (!m_overflowMode) {
        const int requiredRows = qMax(1, (m_fileManager->rowCount() + columns - 1) / columns);
        value = qMax(value, requiredRows);
    }
    if (m_gridRows == value && m_gridColumns == columns)
        return;
    m_gridColumns = columns;
    m_gridRows = value;
    updateGridLayout();
    emit appearanceChanged();
}

void FolderData::setShowFolderName(bool value)
{
    if (m_showFolderName == value)
        return;
    m_showFolderName = value;
    emit appearanceChanged();
}

void FolderData::setShowIconNames(bool value)
{
    if (m_showIconNames == value)
        return;
    m_showIconNames = value;
    updateGridLayout();
    emit appearanceChanged();
}

void FolderData::setShowIconBorder(bool value)
{
    if (m_showIconBorder == value)
        return;
    m_showIconBorder = value;
    emit appearanceChanged();
}

void FolderData::setIconTone(const QString &value)
{
    static const QStringList allowed = {
        QStringLiteral("original"), QStringLiteral("grayscale")
    };
    const QString normalized = allowed.contains(value)
        ? value
        : ((value == QStringLiteral("black") || value == QStringLiteral("white"))
           ? QStringLiteral("grayscale") : QStringLiteral("original"));
    if (m_iconTone == normalized)
        return;
    m_iconTone = normalized;
    emit appearanceChanged();
}

void FolderData::setAllowIconGaps(bool value)
{
    if (m_allowIconGaps == value)
        return;
    m_allowIconGaps = value;
    m_fileManager->setAllowGaps(value);
    emit appearanceChanged();
}

void FolderData::setLockPosition(bool value)
{
    if (m_lockPosition == value)
        return;
    m_lockPosition = value;
    emit interactionChanged();
}

void FolderData::setFrostedGlass(bool value)
{
    if (m_frostedGlass == value)
        return;
    m_frostedGlass = value;
    emit appearanceChanged();
}

void FolderData::setBorderStyle(const QString &value)
{
    static const QStringList allowed = {QStringLiteral("none"), QStringLiteral("subtle"),
                                        QStringLiteral("solid"), QStringLiteral("accent"),
                                        QStringLiteral("double")};
    const QString normalized = allowed.contains(value) ? value : QStringLiteral("subtle");
    if (m_borderStyle == normalized)
        return;
    m_borderStyle = normalized;
    emit appearanceChanged();
}

void FolderData::setOverflowMode(bool value)
{
    if (m_overflowMode == value)
        return;
    m_overflowMode = value;
    m_fileManager->setAllowOverflow(value);
    if (!value) {
        const int requiredRows = qMax(1, (m_fileManager->rowCount() + m_gridColumns - 1)
                                      / m_gridColumns);
        m_gridRows = qBound(1, requiredRows, 12);
        updateGridLayout();
    }
    emit appearanceChanged();
}

void FolderData::setExpansionDirection(const QString &value)
{
    static const QStringList allowed = {QStringLiteral("down"), QStringLiteral("up"),
                                        QStringLiteral("right"), QStringLiteral("left")};
    const QString normalized = allowed.contains(value) ? value : QStringLiteral("down");
    if (m_expansionDirection == normalized)
        return;
    m_expansionDirection = normalized;
    emit appearanceChanged();
}

void FolderData::setOverflowCover(const QString &value)
{
    if (m_overflowCover == value)
        return;
    m_overflowCover = value;
    emit appearanceChanged();
}




void FolderData::setWindowPosition(
    int x,
    int y)
{

    if (m_windowX == x &&
        m_windowY == y)
        return;

    m_windowX = x;
    m_windowY = y;
    qDebug()
        << "[FolderData] setWindowPosition"
        << m_name
        << m_folderId
        << x << y;

    emit windowPositionChanged();
}

FileManager *FolderData::items() const { return m_fileManager; }
int FolderData::itemCount() const { return m_fileManager->rowCount(); }

void FolderData::addFile(QString path)
{

    m_fileManager->addFile(path);
}

void FolderData::removeFile(int index)
{

    m_fileManager->removeFile(index);
}

void FolderData::moveItemToPosition(int index, int x, int y)
{
    m_fileManager->moveItemToPosition(index, x, y);
}

void FolderData::moveItem(int from, int to)
{
    m_fileManager->moveItem(from, to);
}

void FolderData::openLocation(QString path)
{

    m_fileManager->openLocation(path);
}

bool FolderData::save()
{
    return m_fileManager->save();
}
