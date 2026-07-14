import QtQuick
import QtQuick.Controls

Item {
    id: appIcon

    width: 80
    height: 100

    property var item
    property int itemIndex: -1

    // 信号: 由 FolderWindow 处理
    signal requestMove(int index, int x, int y)
    signal openRequest()
    signal openLocationRequest(string path)
    signal removeRequest(int index)

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

    // 右键菜单
    Menu {
        id: contextMenu

        MenuItem {
            text: "打开"
            onTriggered: {
                appIcon.openRequest();
            }
        }

        MenuItem {
            text: "打开文件位置"
            onTriggered: {
                if (appIcon.item) {
                    appIcon.openLocationRequest(appIcon.item.path);
                }
            }
        }

        MenuSeparator {}

        MenuItem {
            text: "删除"
            onTriggered: {
                appIcon.removeRequest(appIcon.itemIndex);
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: appIcon

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // 区分点击与拖拽
        property real pressX: 0
        property real pressY: 0

        onPressed: function (mouse) {
            // 右键按下 → 立即弹出菜单(标准右键行为)
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup();
                return;
            }

            // 左键按下 → 记录起点用于拖拽判断
            pressX = mouse.x;
            pressY = mouse.y;
        }

        onReleased: function (mouse) {
            // 仅处理左键释放
            if (mouse.button !== Qt.LeftButton)
                return;

            let dx = Math.abs(mouse.x - pressX);
            let dy = Math.abs(mouse.y - pressY);

            // 移动距离小于阈值视为点击
            if (dx < 5 && dy < 5) {
                // 左键单击 → 打开文件
                appIcon.openRequest();
                return;
            }

            // ---- 拖拽结束: 吸附网格 & 触发排序 ----
            let gridSize = 100;
            let nx = Math.round(appIcon.x / gridSize) * gridSize;
            let ny = Math.round(appIcon.y / gridSize) * gridSize;

            // 先更新 model
            appIcon.requestMove(appIcon.itemIndex, nx, ny);

            // 修复被 drag.target 破坏的绑定
            appIcon.x = Qt.binding(function() { return appIcon.item ? appIcon.item.x : 0; });
            appIcon.y = Qt.binding(function() { return appIcon.item ? appIcon.item.y : 0; });
        }
    }

    // 悬停放大 / 拖拽放大
    scale: dragArea.drag.active ? 1.15 : (dragArea.containsMouse ? 1.1 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 150 }
    }
}
