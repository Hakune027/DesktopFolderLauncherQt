import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    objectName: "settingsWindow"
    transientParent: null
    width: 680
    height: 620
    minimumWidth: 600
    minimumHeight: 500
    visible: false
    flags: Qt.Window
    title: ""
    color: Qt.rgba(0.055, 0.06, 0.075, 0.62)
    palette.window: "#17181d"
    palette.windowText: "#f5f5f5"
    palette.base: "#23252b"
    palette.text: "#f5f5f5"
    palette.button: "#2c2e35"
    palette.buttonText: "#f5f5f5"
    palette.highlight: "#7b83ff"
    palette.highlightedText: "white"

    function applyGlass() {
        if (typeof windowEffects !== "undefined") {
            windowEffects.applyFrostedGlass(root, root.visible, false);
        }
    }

    onVisibleChanged: Qt.callLater(root.applyGlass)

    function syncVisibility() {
        if (folderManager.folderCount() === 0) {
            root.show();
            root.raise();
            root.requestActivate();
        } else {
            root.hide();
        }
    }

    Component.onCompleted: {
        Qt.callLater(root.syncVisibility);
        Qt.callLater(root.applyGlass);
    }

    Dialog {
        id: newFolderDialog
        title: "新建文件夹"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent

        ColumnLayout {
            width: 320
            spacing: 10
            Label {
                text: "为桌面文件夹输入一个名称"
                color: "#b7b8c0"
                Layout.fillWidth: true
            }
            TextField {
                id: folderNameInput
                Layout.fillWidth: true
                placeholderText: "文件夹名称"
                selectByMouse: true
                onAccepted: newFolderDialog.accept()
            }
        }

        onOpened: {
            folderNameInput.forceActiveFocus();
            folderNameInput.selectAll();
        }
        onAccepted: {
            let name = folderNameInput.text.trim();
            if (name !== "")
                folderManager.createFolder(name);
            folderNameInput.clear();
        }
        onRejected: folderNameInput.clear()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 32
        anchors.bottomMargin: 32
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                width: 42
                height: 42
                radius: 10
                color: "#e7e9ff"
                Label {
                    anchors.centerIn: parent
                    text: "▦"
                    color: "#4f5bd5"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
            }

            ColumnLayout {
                spacing: 1
                Label {
                    text: "桌面文件夹"
                    font.family: "Segoe UI Variable Display"
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                }
                Label {
                    text: "管理文件夹、外观与窗口行为"
                    color: "#b7b8c0"
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "+  新建文件夹"
                highlighted: true
                onClicked: newFolderDialog.open()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#28ffffff"
        }

        Label {
            text: "文件夹列表"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        ListView {
            id: folderList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true
            model: folderManager
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            delegate: Rectangle {
                width: folderList.width - (folderList.ScrollBar.vertical.visible ? 12 : 0)
                height: 94
                radius: 10
                color: rowHover.hovered ? "#70363a45" : "#5030343d"
                border.width: 1
                border.color: rowHover.hovered ? "#50ffffff" : "#28ffffff"

                Behavior on color { ColorAnimation { duration: 120 } }

                HoverHandler { id: rowHover }

                FolderSettingsWindow {
                    id: perFolderSettings
                    folderData: model.folderData
                    transientParent: root
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 12

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 9
                        color: "#fff4ce"
                        Label {
                            anchors.centerIn: parent
                            text: "□"
                            color: "#8a6500"
                            font.pixelSize: 21
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label {
                            Layout.fillWidth: true
                            text: model.folderData.name
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Label {
                            text: model.folderData.itemCount + " 个项目"
                            color: "#b7b8c0"
                            font.pixelSize: 12
                        }
                        CheckBox {
                            text: "锁定窗口位置"
                            checked: model.folderData.lockPosition
                            onClicked: {
                                model.folderData.lockPosition = checked;
                                folderManager.save();
                            }
                        }
                    }

                    Button {
                        text: "设置"
                        onClicked: perFolderSettings.openForFolderWindow()
                    }
                    Button {
                        text: "删除"
                        flat: true
                        onClicked: folderManager.removeFolder(index)
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: folderManager.folderCount() === 0
                text: "还没有文件夹\n点击右上角创建第一个文件夹"
                horizontalAlignment: Text.AlignHCenter
                color: "#b7b8c0"
                lineHeight: 1.5
            }
        }
    }

}
