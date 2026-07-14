#include "AppController.h"

#include <QCoreApplication>
#include <QDir>
#include <QSettings>

namespace {
constexpr auto runKey = "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr auto valueName = "DesktopFolderLauncher";
}

bool AppController::autoStartEnabled() const
{
#ifdef Q_OS_WIN
    QSettings settings(QString::fromLatin1(runKey), QSettings::NativeFormat);
    return !settings.value(QString::fromLatin1(valueName)).toString().isEmpty();
#else
    return false;
#endif
}

void AppController::setAutoStartEnabled(bool enabled)
{
#ifdef Q_OS_WIN
    if (autoStartEnabled() == enabled)
        return;
    QSettings settings(QString::fromLatin1(runKey), QSettings::NativeFormat);
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
