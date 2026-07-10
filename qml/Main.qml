import QtQuick
import QtQuick.Window

Window {
    id: root

    width: 350
    height: 250

    // 保存的位置
    x: settings.value("x", 300)
    y: settings.value("y", 200)

    visible: true

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    color: "transparent"

    Rectangle {

        anchors.fill: parent

        radius: 30

        color: "#CC202020"

        border.width: 1

        border.color: "#40ffffff"

        // 标题

        Text {

            anchors.centerIn: parent

            text: "开发工具"

            color: "white"

            font.pixelSize: 28
        }

        MouseArea {

            anchors.fill: parent

            property real startX
            property real startY

            onPressed: {
                startX = mouse.x;

                startY = mouse.y;
            }

            onPositionChanged: {
                if (mouse.buttons & Qt.LeftButton) {
                    root.x += mouse.x - startX;

                    root.y += mouse.y - startY;

                    // 保存位置

                    settings.setValue("x", root.x);

                    settings.setValue("y", root.y);
                }
            }
        }
    }
}
