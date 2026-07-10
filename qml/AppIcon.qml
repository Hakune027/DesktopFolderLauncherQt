import QtQuick

Item {
    id: icon

    width: 80
    height: 100

    property string name: "应用"

    Column {

        anchors.centerIn: parent

        spacing: 8

        Rectangle {

            width: 64

            height: 64

            radius: 16

            color: "#40ffffff"

            Image {

                width: 64
                height: 64

                source: modelData.icon

                fillMode: Image.PreserveAspectFit
            }
        }

        Text {

            width: 80

            text: icon.name

            horizontalAlignment: Text.AlignHCenter

            color: "white"

            font.pixelSize: 14

            elide: Text.ElideRight
        }
    }

    // 鼠标悬浮动画

    scale: mouseArea.containsMouse ? 1.12 : 1

    Behavior on scale {

        NumberAnimation {

            duration: 150
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true
    }
}
