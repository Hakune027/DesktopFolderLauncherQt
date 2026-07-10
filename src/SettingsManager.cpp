#include "SettingsManager.h"

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent),
      settings(
          "DesktopFolderLauncher",
          "DesktopFolderLauncher")
{
}

void SettingsManager::setValue(
    const QString &key,
    const QVariant &value)
{
    settings.setValue(
        key,
        value);
}

QVariant SettingsManager::value(
    const QString &key,
    const QVariant &defaultValue)
{
    return settings.value(
        key,
        defaultValue);
}