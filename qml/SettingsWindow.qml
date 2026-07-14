import QtQuick
import QtQuick.Controls

Window {
    id: root

    width: 500

    height: 400

    visible: true

    title: "DesktopFolderLauncher 设置"

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
                folderManager.createFolder("新文件夹");
            }
        }

        Repeater {

            model: folderManager.folders

            delegate: Rectangle {

                width: 300

                height: 50

                color: "#eeeeee"

                Text {

                    anchors.centerIn: parent

                    text: modelData.name
                }
            }
        }
    }
}
