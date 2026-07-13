import QtQuick
import QtQuick.Controls

Item {
    id: icon

    width: 80
    height: 100

    // C++ AppItem对象

    property var item

    property int itemIndex: -1

    Column {

        anchors.centerIn: parent

        spacing: 8

        Rectangle {

            width: 64
            height: 64

            radius: 16

            color: "#40ffffff"

            Image {

                anchors.fill: parent

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

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        hoverEnabled: true

        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                menu.popup();
            } else {
                if (icon.item)
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

    Menu {
        id: menu

        MenuItem {

            text: "打开"

            onTriggered: {
                if (icon.item)
                    icon.item.open();
            }
        }

        MenuItem {

            text: "打开文件位置"

            onTriggered: {
                fileManager.openLocation(icon.item.path);
            }
        }

        MenuSeparator {}

        MenuItem {

            text: "删除"

            onTriggered: {
                fileManager.removeFile(icon.itemIndex);
            }
        }
    }
}
