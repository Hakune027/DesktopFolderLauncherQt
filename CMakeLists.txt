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
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)


qt_add_executable(
    DesktopFolderLauncher

    main.cpp


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

install(TARGETS DesktopFolderLauncher
    RUNTIME DESTINATION bin
)

include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    qt_add_executable(DesktopFolderLauncherTests
        tests/model_tests.cpp
        src/AppItem.cpp src/AppItem.h
        src/FileManager.cpp src/FileManager.h
        src/IconProvider.cpp src/IconProvider.h
        src/FolderData.cpp src/FolderData.h
        src/FolderManager.cpp src/FolderManager.h
    )
    target_include_directories(DesktopFolderLauncherTests PRIVATE src)
    target_link_libraries(DesktopFolderLauncherTests PRIVATE
        Qt6::Core Qt6::Gui Qt6::Qml Qt6::Widgets Qt6::Test)
    add_test(NAME model_tests COMMAND DesktopFolderLauncherTests)
    set_tests_properties(model_tests PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
        ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>"
    )
endif()
