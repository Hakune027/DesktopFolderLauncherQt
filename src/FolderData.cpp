#include "FolderData.h"

#include <QUuid>
#include <QDebug>

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
bool FolderData::showIconShadow() const { return m_showIconShadow; }
bool FolderData::allowIconGaps() const { return m_allowIconGaps; }
bool FolderData::lockPosition() const { return m_lockPosition; }
bool FolderData::frostedGlass() const { return m_frostedGlass; }

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
    const int requiredRows = qMax(1, (m_fileManager->rowCount() + value - 1) / value);
    if (m_gridColumns == value && m_gridRows >= requiredRows)
        return;
    m_gridColumns = value;
    m_gridRows = qMax(m_gridRows, requiredRows);
    updateGridLayout();
    emit appearanceChanged();
}

void FolderData::setGridRows(int value)
{
    value = qBound(1, value, 12);
    const int requiredRows = qMax(1, (m_fileManager->rowCount() + m_gridColumns - 1) / m_gridColumns);
    value = qMax(value, requiredRows);
    if (m_gridRows == value)
        return;
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

void FolderData::setShowIconShadow(bool value)
{
    if (m_showIconShadow == value)
        return;
    m_showIconShadow = value;
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

void FolderData::openLocation(QString path)
{

    m_fileManager->openLocation(path);
}

bool FolderData::save()
{
    return m_fileManager->save();
}
