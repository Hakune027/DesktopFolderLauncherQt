#include "AppItem.h"

#include <QDesktopServices>
#include <QUrl>
#include <QImage>

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
    const QImage image(QUrl(icon).toLocalFile());
    if (!image.isNull() && image.hasAlphaChannel()) {
        const QImage rgba = image.convertToFormat(QImage::Format_RGBA8888);
        qsizetype transparentPixels = 0;
        const qsizetype pixelCount = qsizetype(rgba.width()) * rgba.height();
        for (int y = 0; y < rgba.height(); ++y) {
            const auto *line = reinterpret_cast<const QRgb *>(rgba.constScanLine(y));
            for (int x = 0; x < rgba.width(); ++x)
                transparentPixels += qAlpha(line[x]) < 245;
        }
        m_iconHasTransparency = pixelCount > 0
                && transparentPixels * 100 >= pixelCount * 8;
    }
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

bool AppItem::iconHasTransparency() const
{
    return m_iconHasTransparency;
}
