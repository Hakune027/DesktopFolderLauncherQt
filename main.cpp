#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>

#include "src/SettingsManager.h"
#include "src/FileManager.h"
#include "src/DropHandler.h"

int main(int argc, char *argv[])
{

    QGuiApplication app(argc, argv);

    QQuickWindow::setDefaultAlphaBuffer(true);

    SettingsManager settings;

    FileManager fileManager;

    fileManager.load();

    DropHandler *dropHandler = new DropHandler(&app);

    QQmlApplicationEngine engine;

    engine.rootContext()
        ->setContextProperty(
            "settings",
            &settings);

    engine.rootContext()
        ->setContextProperty(
            "fileManager",
            &fileManager);

    QObject::connect(
        dropHandler,
        &DropHandler::fileDropped,
        &fileManager,
        &FileManager::addFile);

    engine.loadFromModule(
        "DesktopFolderLauncher",
        "Main");

    if (engine.rootObjects().isEmpty())
    {
        return -1;
    }

    // Register native OLE drag-and-drop on the frameless window
    QQuickWindow *window =
        qobject_cast<QQuickWindow *>(
            engine.rootObjects().first());

    if (window)
    {
        dropHandler->registerWindow(window);
    }

    int result = app.exec();

    // Cleanup: revoke OLE drop target before destroying

    dropHandler->unregisterWindow();

    return result;
}