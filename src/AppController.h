#pragma once

#include <QObject>

class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool autoStartEnabled READ autoStartEnabled WRITE setAutoStartEnabled NOTIFY autoStartEnabledChanged)

public:
    explicit AppController(QObject *parent = nullptr) : QObject(parent) {}

    bool autoStartEnabled() const;
    void setAutoStartEnabled(bool enabled);

signals:
    void autoStartEnabledChanged();
};
