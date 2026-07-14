import QtQuick
import QtQuick.Window

Window {
    id: root

    property string folderName: "开发工具"

    width: 350

    height: 250

    visible: true

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    color: "transparent"

    Rectangle {
        id: folder

        anchors.fill: parent

        radius: 30

        color: "#CC202020"

        border.width: 1

        border.color: "#40ffffff"

        Text {

            x: 25

            y: 20

            text: root.folderName

            color: "white"

            font.pixelSize: 26
        }

        Item {

            anchors.fill: parent

            anchors.margins: 20

            anchors.topMargin: 70

            Repeater {

                model: fileManager.items

                delegate: AppIcon {

                    item: modelData

                    itemIndex: index

                    onRequestMove: function (index, x, y) {
                        let draggedItem = fileManager.items[index];

                        if (draggedItem.x === x && draggedItem.y === y) {
                            return;
                        }

                        let targetIndex = -1;

                        for (let i = 0; i < fileManager.items.length; i++) {
                            if (i === index)
                                continue;

                            let other = fileManager.items[i];

                            if (other.x === x && other.y === y) {
                                targetIndex = i;

                                break;
                            }
                        }

                        if (targetIndex >= 0) {
                            let targetItem = fileManager.items[targetIndex];

                            let oldX = draggedItem.x;

                            let oldY = draggedItem.y;

                            draggedItem.x = targetItem.x;

                            draggedItem.y = targetItem.y;

                            targetItem.x = oldX;

                            targetItem.y = oldY;
                        } else {
                            draggedItem.x = x;

                            draggedItem.y = y;
                        }

                        fileManager.save();
                    }
                }
            }
        }
    }

    // 文件拖入

    DropArea {

        anchors.fill: parent

        keys: ["text/uri-list"]

        onEntered: function (drag) {
            drag.accept();
        }

        onDropped: function (drop) {
            for (let url of drop.urls) {
                fileManager.addFile(url);
            }
        }
    }

    // 移动窗口

    MouseArea {
        id: dragArea

        width: parent.width

        height: 40

        property real startX

        property real startY

        onPressed: function (mouse) {
            startX = mouse.x;

            startY = mouse.y;
        }

        onPositionChanged: function (mouse) {
            if (mouse.buttons & Qt.LeftButton) {
                root.x += mouse.x - startX;

                root.y += mouse.y - startY;
            }
        }
    }
}
