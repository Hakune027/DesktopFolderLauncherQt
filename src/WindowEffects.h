#pragma once

#include <QObject>
#include <QWindow>

class WindowEffects : public QObject
{
    Q_OBJECT
public:
    explicit WindowEffects(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE bool applyFrostedGlass(QWindow *window, bool enabled,
                                       bool lightTheme);
};
