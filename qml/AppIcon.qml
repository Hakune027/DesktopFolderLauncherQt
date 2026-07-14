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
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: Math.max(0, appIcon.parent.width - appIcon.width)
        drag.maximumY: Math.max(0, appIcon.parent.height - appIcon.height)

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // 区分点击与拖拽
        property point pressScenePosition
        property bool wasDragged: false

        onPressed: function (mouse) {
            // 右键按下 → 立即弹出菜单(标准右键行为)
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup();
                return;
            }

            // 左键按下 → 记录起点用于拖拽判断
            pressScenePosition = appIcon.mapToItem(null, mouse.x, mouse.y);
            wasDragged = false;
        }

        onPositionChanged: function(mouse) {
            let p = appIcon.mapToItem(null, mouse.x, mouse.y);
            if (Math.abs(p.x - pressScenePosition.x) >= 5 ||
                Math.abs(p.y - pressScenePosition.y) >= 5)
                wasDragged = true;
        }

        onReleased: function (mouse) {
            // 仅处理左键释放
            if (mouse.button !== Qt.LeftButton)
                return;

            if (!wasDragged) {
                // 左键单击 → 打开文件
                appIcon.openRequest();
                return;
            }

            // ---- 拖拽结束: 吸附网格 & 触发排序 ----
            let gridSize = 100;
            let nx = Math.max(0, Math.min(Math.round(appIcon.x / gridSize) * gridSize,
                                          appIcon.parent.width - appIcon.width));
            let ny = Math.max(0, Math.min(Math.round(appIcon.y / gridSize) * gridSize,
                                          appIcon.parent.height - appIcon.height));

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
