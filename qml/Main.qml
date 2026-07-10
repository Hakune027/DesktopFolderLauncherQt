import QtQuick
import QtQuick.Window

Window {
    id: root

    width: 350
    height: 250

    x: settings.value("x", 300)

    y: settings.value("y", 200)

    visible: true

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    color: "transparent"

    FolderWindow {

        anchors.fill: parent

        folderName: "开发工具"
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

                settings.setValue("x", root.x);

                settings.setValue("y", root.y);
            }
        }
    }
}
