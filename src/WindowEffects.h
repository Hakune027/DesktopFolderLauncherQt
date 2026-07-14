#pragma once

#include <QObject>
#include <QHash>
#include <QPointer>
#include <QWindow>

class QVariantAnimation;
class QTimer;

class WindowEffects : public QObject
{
    Q_OBJECT
public:
    explicit WindowEffects(QObject *parent = nullptr);

    Q_INVOKABLE bool applyFrostedGlass(QWindow *window, bool enabled,
                                       bool lightTheme, bool windowShadow = true);
    Q_INVOKABLE void animateGeometry(QWindow *window, int x, int y,
                                     int width, int height, int duration = 240);
    Q_INVOKABLE void sendToDesktopLayer(QWindow *window);

signals:
    void desktopClicked();

private:
    QHash<QWindow *, QPointer<QVariantAnimation>> m_geometryAnimations;
    QTimer *m_desktopClickTimer = nullptr;
    bool m_leftButtonDown = false;
};
