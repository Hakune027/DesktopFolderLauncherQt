#include "AppItem.h"

#include <QDesktopServices>
#include <QUrl>

AppItem::AppItem(
    QString name,
    QString path,
    QString icon,
    QObject *parent)

    : QObject(parent),
      m_name(name),
      m_path(path),
      m_icon(icon)

{
}

QString AppItem::name() const
{
    return m_name;
}

QString AppItem::path() const
{
    return m_path;
}

QString AppItem::icon() const
{
    return m_icon;
}

int AppItem::x() const
{
    return m_x;
}

int AppItem::y() const
{
    return m_y;
}

void AppItem::setX(int value)
{

    if (m_x == value)
        return;

    m_x = value;

    emit positionChanged();
}

void AppItem::setY(int value)
{

    if (m_y == value)
        return;

    m_y = value;

    emit positionChanged();
}

void AppItem::open()
{

    QDesktopServices::openUrl(
        QUrl::fromLocalFile(
            m_path));
}