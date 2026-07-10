#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "src/SettingsManager.h"

int main(int argc, char *argv[])
{

    QGuiApplication app(argc, argv);

    SettingsManager settings;

    QQmlApplicationEngine engine;

    engine.rootContext()
        ->setContextProperty(
            "settings",
            &settings);

    engine.loadFromModule(
        "DesktopFolderLauncher",
        "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}