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

void FolderData::setWindowPosition(
    int x,
    int y)
{

    if (m_windowX == x &&
        m_windowY == y)
        return;

    m_windowX = x;
    m_windowY = y;
    m_hasWindowPosition = true;

    qDebug()
        << "[FolderData] setWindowPosition"
        << m_name
        << m_folderId
        << x << y;

    emit windowPositionChanged();
}

QQmlListProperty<QObject>
FolderData::items()
{

    return m_fileManager->items();
}

void FolderData::addFile(QString path)
{

    m_fileManager->addFile(path);
}

void FolderData::removeFile(int index)
{

    m_fileManager->removeFile(index);
}

void FolderData::save()
{
    m_fileManager->save();
}
