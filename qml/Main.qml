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

    FolderSettingsWindow {
        id: defaultFolderSettingsWindow
        folderData: folderManager.defaultFolderData
        editingDefaults: true
    }

    SettingsWindow {
        folderSettingsHost: sharedFolderSettingsWindow
        defaultSettingsHost: defaultFolderSettingsWindow
    }

    FolderSpawner {
        folderSettingsHost: sharedFolderSettingsWindow
    }
}
