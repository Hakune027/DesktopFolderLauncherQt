import QtQuick

Rectangle {
    id: folder

    property string folderName: "开发工具"

    width: 350
    height: 250
    radius: 30
    color: "#CC202020"
    border.width: 1
    border.color: "#40ffffff"

    Text {
        x: 25
        y: 20
        text: folder.folderName
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

                    // 位置没变，无需操作
                    if (draggedItem.x === x && draggedItem.y === y) return;

                    // 查找目标位置是否已被占用
                    let targetIndex = -1;
                    for (let i = 0; i < fileManager.items.length; i++) {
                        if (i === index) continue;
                        let other = fileManager.items[i];
                        if (other.x === x && other.y === y) {
                            targetIndex = i;
                            break;
                        }
                    }

                    if (targetIndex >= 0) {
                        // 与目标位置的图标交换位置
                        let targetItem = fileManager.items[targetIndex];
                        let oldX = draggedItem.x;
                        let oldY = draggedItem.y;
                        draggedItem.x = targetItem.x;
                        draggedItem.y = targetItem.y;
                        targetItem.x = oldX;
                        targetItem.y = oldY;
                    } else {
                        // 移动到空白位置
                        draggedItem.x = x;
                        draggedItem.y = y;
                    }
                    fileManager.save();
                }
            }
        }
    }
}
