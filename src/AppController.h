#pragma once

#include <QObject>

class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool autoStartEnabled READ autoStartEnabled WRITE setAutoStartEnabled NOTIFY autoStartEnabledChanged)
    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)

public:
    explicit AppController(QObject *parent = nullptr) : QObject(parent) {}

    bool autoStartEnabled() const;
    void setAutoStartEnabled(bool enabled);
    QString appVersion() const;

signals:
    void autoStartEnabledChanged();
};
