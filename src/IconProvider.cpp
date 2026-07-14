#include "IconProvider.h"

#include <QFileIconProvider>
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QUrl>
#include <QCryptographicHash>
#include <QImage>

#ifdef Q_OS_WIN
#include <windows.h>
#include <shellapi.h>
#include <shobjidl.h>
#endif

#ifdef Q_OS_WIN
namespace {
QIcon iconFromHandle(HICON handle)
{
    if (!handle)
        return {};
    QIcon icon(QPixmap::fromImage(QImage::fromHICON(handle)));
    DestroyIcon(handle);
    return icon;
}

QIcon shellIconWithoutOverlay(const QFileInfo &fileInfo)
{
    QString iconSource = fileInfo.absoluteFilePath();
    int iconIndex = 0;

    if (fileInfo.suffix().compare(QStringLiteral("lnk"), Qt::CaseInsensitive) == 0) {
        IShellLinkW *shellLink = nullptr;
        if (SUCCEEDED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                       IID_IShellLinkW, reinterpret_cast<void **>(&shellLink)))) {
            IPersistFile *persistFile = nullptr;
            if (SUCCEEDED(shellLink->QueryInterface(IID_IPersistFile,
                                                    reinterpret_cast<void **>(&persistFile)))) {
                const std::wstring linkPath = QDir::toNativeSeparators(fileInfo.absoluteFilePath()).toStdWString();
                if (SUCCEEDED(persistFile->Load(linkPath.c_str(), STGM_READ))) {
                    wchar_t iconPath[MAX_PATH] = {};
                    if (SUCCEEDED(shellLink->GetIconLocation(iconPath, MAX_PATH, &iconIndex)) && iconPath[0]) {
                        iconSource = QString::fromWCharArray(iconPath);
                    } else {
                        wchar_t targetPath[MAX_PATH] = {};
                        WIN32_FIND_DATAW findData = {};
                        if (SUCCEEDED(shellLink->GetPath(targetPath, MAX_PATH, &findData, SLGP_RAWPATH))
                            && targetPath[0]) {
                            iconSource = QString::fromWCharArray(targetPath);
                            iconIndex = 0;
                        }
                    }
                }
                persistFile->Release();
            }
            shellLink->Release();
        }
    }

    HICON highResolutionIcon = nullptr;
    const std::wstring source = QDir::toNativeSeparators(iconSource).toStdWString();
    if (PrivateExtractIconsW(source.c_str(), iconIndex, 256, 256,
                             &highResolutionIcon, nullptr, 1, LR_DEFAULTCOLOR) > 0
        && highResolutionIcon) {
        return iconFromHandle(highResolutionIcon);
    }

    SHFILEINFOW shellInfo = {};
    const std::wstring nativePath = QDir::toNativeSeparators(iconSource).toStdWString();
    if (SHGetFileInfoW(nativePath.c_str(), 0, &shellInfo, sizeof(shellInfo),
                       SHGFI_ICON | SHGFI_LARGEICON) != 0 && shellInfo.hIcon)
        return iconFromHandle(shellInfo.hIcon);
    return {};
}
}
#endif

QString IconProvider::getIcon(const QString &filePath)
{

    QFileInfo info(filePath);

    QIcon icon;
#ifdef Q_OS_WIN
    icon = shellIconWithoutOverlay(info);
#endif
    if (icon.isNull()) {
        QFileIconProvider provider;
        icon = provider.icon(info);
    }

    QString cachePath =
        QStandardPaths::writableLocation(
            QStandardPaths::CacheLocation);

    QDir dir(cachePath);

    if (!dir.exists())
    {
        dir.mkpath(".");
    }

    const QByteArray cacheKey = QCryptographicHash::hash(
        QByteArrayLiteral("high-resolution-icon-v3|") + info.canonicalFilePath().toUtf8()
            + QByteArray::number(info.lastModified().toMSecsSinceEpoch()),
        QCryptographicHash::Sha256).toHex();
    QString savePath = cachePath + "/" + QString::fromLatin1(cacheKey) + ".png";

    if (!QFileInfo::exists(savePath) && !icon.pixmap(256, 256).save(savePath))
        return QString();

    qDebug()
        << "Icon saved:"
        << savePath;

    return QUrl::fromLocalFile(savePath).toString();
}
