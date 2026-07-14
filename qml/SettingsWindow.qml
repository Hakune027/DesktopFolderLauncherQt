import QtQuick
import QtQuick.Controls

Window {
    id: root
    objectName: "settingsWindow"
    transientParent: null

    width: 500
    height: 400

    visible: false

    title: "DesktopFolderLauncher 设置"

    function syncVisibility() {
        if (folderManager.folderCount() === 0) {
            root.show();
            root.raise();
            root.requestActivate();
        } else {
            root.hide();
        }
    }

    Component.onCompleted: Qt.callLater(root.syncVisibility)


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
            width: 460
            height: 240

            model: folderManager

            delegate: Rectangle {
                width: 460
                height: 88
                color: "#eeeeee"

                FolderSettingsWindow {
                    id: perFolderSettings
                    folderData: model.folderData
                    transientParent: root
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 8

                        Text {
                            width: Math.max(80, parent.width - 142)
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.folderData.name
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Button {
                            text: "设置"
                            width: 60
                            height: 30
                            onClicked: perFolderSettings.openForFolderWindow()
                        }

                        Button {
                            text: "删除"
                            width: 60
                            height: 30
                            onClicked: folderManager.removeFolder(index)
                        }
                    }

                    Row {
                        height: 34
                        spacing: 16

                        CheckBox {
                            text: "锁定位置"
                            checked: model.folderData.lockPosition
                            onClicked: {
                                model.folderData.lockPosition = checked;
                                folderManager.save();
                            }
                        }
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
            visible: folderManager.folderCount() === 0
            text: "暂无文件夹, 点击上方按钮创建"
            color: "#888888"
            font.pixelSize: 14
        }
    }
}
