import QtQuick
import QtQuick.Controls

Item {
    id: icon

    width: 80
    height: 100

    property var item
    property int itemIndex: -1

    signal requestMove(int index, int x, int y)

    x: item ? item.x : 0
    y: item ? item.y : 0

    // 拖动时置于顶层
    z: dragArea.drag.active ? 999 : 0

    Rectangle {
        width: 64
        height: 64
        radius: 16
        color: "#40ffffff"

        // 拖动时半透明
        opacity: dragArea.drag.active ? 0.7 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Image {
            anchors.fill: parent
            source: item ? item.icon : ""
            fillMode: Image.PreserveAspectFit
        }
    }

    Text {
        y: 68
        width: 80
        text: item ? item.name : ""
        color: "white"
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: icon

        onReleased: {
            let gridSize = 100;
            let nx = Math.round(icon.x / gridSize) * gridSize;
            let ny = Math.round(icon.y / gridSize) * gridSize;

            // 先更新 model
            icon.requestMove(icon.itemIndex, nx, ny);

            // 修复被 drag.target 破坏的绑定
            icon.x = Qt.binding(function() { return icon.item ? icon.item.x : 0; });
            icon.y = Qt.binding(function() { return icon.item ? icon.item.y : 0; });
        }
    }

    // 悬停放大 / 拖拽放大
    scale: dragArea.drag.active ? 1.15 : (dragArea.containsMouse ? 1.1 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 150 }
    }
}
