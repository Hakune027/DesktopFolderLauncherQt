import QtQuick
import QtQuick.Controls

Window {
    id: root

    width: 500
    height: 400

    visible: true

    title: "DesktopFolderLauncher 设置"

    // 用 QML 原生列表替代 QQmlListProperty 绑定,
    // 每次 foldersChanged 时重建列表以触发 Repeater 刷新
    property var folderList: []

    Connections {
        target: folderManager
        function onFoldersChanged() {
            rebuildFolderList();
        }
    }

    function rebuildFolderList() {
        let list = [];
        let count = folderManager.folderCount();
        for (let i = 0; i < count; i++) {
            let data = folderManager.folderAt(i);
            if (data) {
                list.push(data);
            }
        }
        folderList = list;
    }

    Component.onCompleted: {
        rebuildFolderList();
    }

    // 新建文件夹弹出对话框
    Dialog {
        id: newFolderDialog

        title: "新建文件夹"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        anchors.centerIn: parent

        Column {
            spacing: 10

            Label {
                text: "请输入文件夹名称:"
            }

            TextField {
                id: folderNameInput
                width: 250
                placeholderText: "文件夹名称"
            }
        }

        onAccepted: {
            let name = folderNameInput.text.trim();
            if (name !== "") {
                folderManager.createFolder(name);
            }
            folderNameInput.text = "";
        }

        onRejected: {
            folderNameInput.text = "";
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "文件夹管理"
            font.pixelSize: 30
        }

        Button {
            text: "新增文件夹"

            onClicked: {
                newFolderDialog.open();
            }
        }

        // 文件夹列表
        ListView {
            width: 350
            height: 200

            model: folderList

            delegate: Rectangle {
                width: 350
                height: 50
                color: "#eeeeee"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    spacing: 15
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        font.pixelSize: 16
                    }
                }

                // 删除按钮
                Button {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    text: "删除"
                    width: 60
                    height: 30

                    onClicked: {
                        folderManager.removeFolder(index);
                    }
                }

                // 底部分隔线
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#cccccc"
                }
            }
        }

        // 空状态提示
        Text {
            visible: root.folderList.length === 0
            text: "暂无文件夹, 点击上方按钮创建"
            color: "#888888"
            font.pixelSize: 14
        }
    }
}
