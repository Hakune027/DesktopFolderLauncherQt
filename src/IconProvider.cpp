#include "IconProvider.h"

#include <QFileIconProvider>
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QUrl>
#include <QCryptographicHash>

QString IconProvider::getIcon(const QString &filePath)
{

    QFileInfo info(filePath);

    QFileIconProvider provider;

    QIcon icon =
        provider.icon(info);

    QString cachePath =
        QStandardPaths::writableLocation(
            QStandardPaths::CacheLocation);

    QDir dir(cachePath);

    if (!dir.exists())
    {
        dir.mkpath(".");
    }

    const QByteArray cacheKey = QCryptographicHash::hash(
        info.canonicalFilePath().toUtf8() + QByteArray::number(info.lastModified().toMSecsSinceEpoch()),
        QCryptographicHash::Sha256).toHex();
    QString savePath = cachePath + "/" + QString::fromLatin1(cacheKey) + ".png";

    if (!QFileInfo::exists(savePath) && !icon.pixmap(128, 128).save(savePath))
        return QString();

    qDebug()
        << "Icon saved:"
        << savePath;

    return QUrl::fromLocalFile(savePath).toString();
}
