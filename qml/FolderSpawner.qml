import QtQuick

Item {
    id: root
    property var folderSettingsHost

    // 已创建的窗口映射: key -> window
    property var windowMap: ({})

    Component {
        id: folderComponent

        FolderWindow {}
    }

    Connections {

        target: folderManager

        function onFoldersChanged() {
            syncFolders();
        }
    }

    function syncFolders() {
        let count = folderManager.folderCount();

        // 收集当前存在的 folderData
        let currentDataList = [];
        for (let i = 0; i < count; i++) {
            let data = folderManager.folderAt(i);
            if (data) {
                currentDataList.push(data);
            }
        }

        // 关闭已删除文件夹对应的窗口
        let keysToRemove = [];
        for (let key in windowMap) {
            let found = false;
            for (let j = 0; j < currentDataList.length; j++) {
                if (currentDataList[j] === windowMap[key].folderData) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                let win = windowMap[key];
                if (win) {
                    win.close();
                }
                keysToRemove.push(key);
            }
        }

        for (let k = 0; k < keysToRemove.length; k++) {
            delete windowMap[keysToRemove[k]];
        }

        // 为新文件夹创建窗口
        for (let i = 0; i < count; i++) {
            let data = folderManager.folderAt(i);
            if (!data)
                continue;

            // folderId is stable across deletions and list reordering. Using
            // the current model index here can overwrite another live window.
            let key = "folder_" + data.folderId;
            if (windowMap[key])
                continue;

            let folder = folderComponent.createObject(null, {
                "folderData": data,
                "folderSettingsHost": root.folderSettingsHost
            });

            if (folder) {
                folder.expansionRequested.connect(function(expandedWindow) {
                    for (let existingKey in root.windowMap) {
                        let existingWindow = root.windowMap[existingKey];
                        if (existingWindow && existingWindow !== expandedWindow
                                && existingWindow.overflowExpanded) {
                            existingWindow.overflowExpanded = false;
                        }
                    }
                });

                console.log(
                    "[FolderSpawner] 创建窗口:",
                    data.name,
                    "index=" + i,
                    "savedPos=(" + data.windowX + "," + data.windowY + ")"
                );

                windowMap[key] = folder;

                // 窗口关闭时清理
                folder.closing.connect(function () {
                    console.log(
                        "[FolderSpawner] 窗口关闭:",
                        data.name,
                        "position=(" + folder.x + "," + folder.y + ")"
                    );

                    // 持久化窗口位置 & 文件夹元数据
                    if (data) {
                        data.setWindowPosition(folder.x, folder.y);
                    }
                    if (typeof folderManager !== 'undefined') {
                        folderManager.save();
                    }

                    if (windowMap[key] === folder)
                        delete windowMap[key];
                    Qt.callLater(function() { folder.destroy(); });
                });
            }
        }
    }

    Component.onCompleted: {
        syncFolders();
    }
}
