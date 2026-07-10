#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>

class SettingsManager : public QObject
{
    Q_OBJECT

public:
    explicit SettingsManager(QObject *parent = nullptr);

    Q_INVOKABLE
    void setValue(
        const QString &key,
        const QVariant &value);

    Q_INVOKABLE
    QVariant value(
        const QString &key,
        const QVariant &defaultValue = QVariant());

private:
    QSettings settings;
};

#endif