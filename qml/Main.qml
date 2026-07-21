import QtQuick
import QtQuick.Window

Window {
    id: root

    width: 1

    height: 1

    visible: false

    color: "transparent"

    FolderSettingsWindow {
        id: sharedFolderSettingsWindow
    }

    SettingsWindow {
        folderSettingsHost: sharedFolderSettingsWindow
    }

    FolderSpawner {
        folderSettingsHost: sharedFolderSettingsWindow
    }
}
