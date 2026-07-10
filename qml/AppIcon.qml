import QtQuick

Item {
    id: icon

    width: 80
    height: 100

    // 接收 C++ AppItem
    property var item

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

                source: icon.item ? icon.item.icon : ""

                fillMode: Image.PreserveAspectFit
            }
        }

        Text {

            width: 80

            text: icon.item ? icon.item.name : ""

            horizontalAlignment: Text.AlignHCenter

            color: "white"

            font.pixelSize: 14

            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true

        onClicked: {
            if (icon.item) {
                icon.item.open();
            }
        }
    }

    scale: mouseArea.containsMouse ? 1.12 : 1

    Behavior on scale {

        NumberAnimation {

            duration: 150
        }
    }
}
