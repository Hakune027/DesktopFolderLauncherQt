#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QStyle>
#include "src/FolderManager.h"
#include "src/DropHandler.h"
#include "src/WindowEffects.h"

int main(int argc, char *argv[])
{

    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);

    QQuickWindow::setDefaultAlphaBuffer(true);

    FolderManager folderManager;

    DropHandler *dropHandler = new DropHandler(&app);
    WindowEffects windowEffects;

    QQmlApplicationEngine engine;

    engine.rootContext()
        ->setContextProperty(
            "folderManager",
            &folderManager);

    engine.rootContext()
        ->setContextProperty(
            "dropHandler",
            dropHandler);

    engine.rootContext()->setContextProperty("windowEffects", &windowEffects);

    engine.loadFromModule(
        "DesktopFolderLauncher",
        "Main");

    if (engine.rootObjects().isEmpty())
    {
        return -1;
    }

    QWindow *settingsWindow = engine.rootObjects().first()->findChild<QWindow *>("settingsWindow");

    QSystemTrayIcon trayIcon;
    QMenu trayMenu;
    QAction showSettingsAction(QStringLiteral("打开设置"), &trayMenu);
    QAction quitAction(QStringLiteral("退出"), &trayMenu);
    trayMenu.addAction(&showSettingsAction);
    trayMenu.addSeparator();
    trayMenu.addAction(&quitAction);

    QIcon trayImage = app.windowIcon();
    if (trayImage.isNull())
        trayImage = app.style()->standardIcon(QStyle::SP_DirIcon);
    trayIcon.setIcon(trayImage);
    trayIcon.setToolTip(QStringLiteral("DesktopFolderLauncher"));
    trayIcon.setContextMenu(&trayMenu);

    const auto showSettings = [settingsWindow]() {
        if (!settingsWindow)
            return;
        settingsWindow->show();
        settingsWindow->raise();
        settingsWindow->requestActivate();
    };
    QObject::connect(&showSettingsAction, &QAction::triggered, &app, showSettings);
    QObject::connect(&quitAction, &QAction::triggered, &app, &QApplication::quit);
    QObject::connect(&trayIcon, &QSystemTrayIcon::activated, &app,
                     [showSettings](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick)
            showSettings();
    });
    trayIcon.show();

    // Register native OLE drag-and-drop on the settings window.
    QQuickWindow *window = qobject_cast<QQuickWindow *>(settingsWindow);

    if (window)
    {
        dropHandler->registerWindow(window);
    }

    int result = app.exec();

    // Cleanup: revoke OLE drop target before destroying
    dropHandler->unregisterWindow();

    return result;
}
