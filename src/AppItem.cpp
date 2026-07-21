#include "AppItem.h"

#include <QDesktopServices>
#include <QUrl>
#include <QDir>

#ifdef Q_OS_WIN
#include <windows.h>
#include <shellapi.h>
#endif

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
#ifdef Q_OS_WIN
    // ShellExecute resolves PIDL-backed Store application shortcuts whose
    // .lnk file intentionally has no ordinary executable target path.
    const std::wstring nativePath = QDir::toNativeSeparators(m_path).toStdWString();
    const HINSTANCE result = ShellExecuteW(nullptr, L"open", nativePath.c_str(),
                                           nullptr, nullptr, SW_SHOWNORMAL);
    if (reinterpret_cast<INT_PTR>(result) > 32)
        return;
#endif
    QDesktopServices::openUrl(
        QUrl::fromLocalFile(
            m_path));
}
