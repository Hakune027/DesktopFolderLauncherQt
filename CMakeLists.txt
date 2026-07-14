cmake_minimum_required(VERSION 3.21)

project(
    DesktopFolderLauncher
    VERSION 1.0
    LANGUAGES CXX
)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    Widgets
    QuickControls2
)


qt_standard_project_setup()


qt_add_executable(
    DesktopFolderLauncher

    main.cpp


    src/SettingsManager.cpp
    src/SettingsManager.h


    src/AppItem.cpp
    src/AppItem.h


    src/FileManager.cpp
    src/FileManager.h


    src/IconProvider.cpp
    src/IconProvider.h


    src/DropHandler.cpp
    src/DropHandler.h

    src/FolderManager.cpp
    src/FolderManager.h

    src/FolderData.cpp
    src/FolderData.h
)


qt_add_qml_module(
    DesktopFolderLauncher

    URI DesktopFolderLauncher

    VERSION 1.0

    QML_FILES

        qml/Main.qml

        qml/FolderWindow.qml

        qml/AppIcon.qml

        qml/SettingsWindow.qml

        qml/FolderSpawner.qml
)


target_link_libraries(
    DesktopFolderLauncher
    PRIVATE

    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Widgets
    Qt6::QuickControls2
)