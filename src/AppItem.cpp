#include "AppItem.h"

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