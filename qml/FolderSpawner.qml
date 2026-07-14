import QtQuick

Item {
    id: root

    Component {
        id: folderComponent

        FolderWindow {}
    }

    Connections {

        target: folderManager

        function onFoldersChanged() {
            createFolders();
        }
    }

    function createFolders() {
        for (let i = 0; i < folderManager.folders.length; i++) {
            let data = folderManager.folders[i];

            let folder = folderComponent.createObject(null, {
                "folderName": data.name,
                "x": data.x,
                "y": data.y
            });

            if (folder) {
                console.log("创建文件夹:", data.name);
            }
        }
    }

    Component.onCompleted: {
        createFolders();
    }
}
