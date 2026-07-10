#include "IconProvider.h"

#include <QFileIconProvider>
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QUrl>

QString IconProvider::getIcon(QString filePath)
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

    QString savePath =
        cachePath + "/" + info.baseName() + ".png";

    icon.pixmap(128, 128)
        .save(savePath);

    qDebug()
        << "Icon saved:"
        << savePath;

    return QUrl::fromLocalFile(savePath).toString();
}