import QtQuick

Rectangle {
    id: folder

    width: 350
    height: 250

    property string folderName: "开发工具"

    radius: 30

    color: "#CC202020"

    border.width: 1
    border.color: "#40ffffff"

    // 阴影效果（后续升级真正DropShadow）

    Rectangle {

        anchors.fill: parent

        radius: folder.radius

        color: "transparent"
    }

    Column {

        anchors.fill: parent

        anchors.margins: 25

        spacing: 20

        Text {

            text: folder.folderName

            color: "white"

            font.pixelSize: 26

            font.bold: true
        }

        Grid {

            columns: 3

            spacing: 20

            Repeater {

                model: 3

                Rectangle {

                    width: 70

                    height: 70

                    radius: 18

                    color: "#40ffffff"

                    Text {

                        anchors.centerIn: parent

                        text: "APP"

                        color: "white"

                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
