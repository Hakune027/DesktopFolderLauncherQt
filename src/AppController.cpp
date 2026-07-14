#include "AppController.h"

#include <QCoreApplication>
#include <QDir>
#include <QSettings>
#include <QFileDialog>
#include <QUrl>
#include <QImage>
#include <QPainter>
#include <QPainterPath>
#include <QStandardPaths>
#include <QUuid>

namespace {
constexpr auto runKey = "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr auto valueName = "DesktopFolderLauncher";
}

bool AppController::autoStartEnabled() const
{
#ifdef Q_OS_WIN
    QSettings settings(QString::fromLatin1(runKey), QSettings::NativeFormat);
    QString configured = settings.value(QString::fromLatin1(valueName)).toString().trimmed();
    if (configured.startsWith(QLatin1Char('"')) && configured.endsWith(QLatin1Char('"')))
        configured = configured.mid(1, configured.size() - 2);
    const QString executable = QDir::cleanPath(QCoreApplication::applicationFilePath());
    return QDir::cleanPath(configured).compare(executable, Qt::CaseInsensitive) == 0;
#else
    return false;
#endif
}

void AppController::setAutoStartEnabled(bool enabled)
{
#ifdef Q_OS_WIN
    QSettings settings(QString::fromLatin1(runKey), QSettings::NativeFormat);
    if (enabled && autoStartEnabled())
        return;
    if (!enabled && !settings.contains(QString::fromLatin1(valueName)))
        return;
    if (enabled) {
        const QString executable = QDir::toNativeSeparators(QCoreApplication::applicationFilePath());
        settings.setValue(QString::fromLatin1(valueName), QStringLiteral("\"") + executable + QStringLiteral("\""));
    } else {
        settings.remove(QString::fromLatin1(valueName));
    }
    settings.sync();
    emit autoStartEnabledChanged();
#else
    Q_UNUSED(enabled);
#endif
}

QString AppController::appVersion() const
{
    return QCoreApplication::applicationVersion();
}

QString AppController::chooseImageFile() const
{
    const QString path = QFileDialog::getOpenFileName(
        nullptr,
        tr("选择缩略区封面"),
        QString(),
        tr("图片文件 (*.png *.jpg *.jpeg *.webp *.bmp *.svg)"));
    if (path.isEmpty())
        return {};

    const QImage source(path);
    if (source.isNull())
        return QUrl::fromLocalFile(path).toString();

    constexpr int outputSize = 512;
    constexpr qreal cornerRadius = 112.0;
    const int cropSize = qMin(source.width(), source.height());
    const QRect sourceRect((source.width() - cropSize) / 2,
                           (source.height() - cropSize) / 2,
                           cropSize, cropSize);
    QImage rounded(outputSize, outputSize, QImage::Format_ARGB32_Premultiplied);
    rounded.fill(Qt::transparent);
    QPainter painter(&rounded);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setRenderHint(QPainter::SmoothPixmapTransform, true);
    QPainterPath clipPath;
    clipPath.addRoundedRect(QRectF(0, 0, outputSize, outputSize),
                            cornerRadius, cornerRadius);
    painter.setClipPath(clipPath);
    painter.drawImage(QRect(0, 0, outputSize, outputSize), source, sourceRect);
    painter.end();

    QString dataDir = qEnvironmentVariable("DESK_FOLDER_DATA_DIR");
    if (dataDir.isEmpty())
        dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    const QString coverDir = QDir(dataDir).filePath(QStringLiteral("covers"));
    QDir().mkpath(coverDir);
    const QString outputPath = QDir(coverDir).filePath(
        QStringLiteral("cover_%1.png").arg(
            QUuid::createUuid().toString(QUuid::WithoutBraces)));
    if (!rounded.save(outputPath, "PNG"))
        return QUrl::fromLocalFile(path).toString();
    return QUrl::fromLocalFile(outputPath).toString();
}
