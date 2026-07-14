import QtQuick
import QtQuick.Controls

Item {
    id: appIcon

    property int iconSize: 64
    property int cellSize: 100
    property int verticalCellSize: cellSize

    width: iconSize
    height: showName ? iconSize + Math.min(24, Math.max(0, verticalCellSize - iconSize)) : iconSize

    property var item
    property int itemIndex: -1
    property bool showName: true
    property color labelColor: "white"
    property bool lightTheme: false
    property bool autoFillTransparentIcons: false
    property bool indexedLayout: false
    property int layoutIndex: itemIndex
    property int layoutColumns: 1
    property int layoutRows: 1
    property bool horizontalLayout: false
    property real layoutOffsetX: 0
    property real layoutOffsetY: 0
    property bool draggable: true
    readonly property bool contextMenuOpen: contextMenu.visible
    property real entryScale: 0.88

    // 信号: 由 FolderWindow 处理
    signal requestMove(int index, int x, int y)
    signal openRequest()
    signal openLocationRequest(string path)
    signal removeRequest(int index)

    x: indexedLayout ? (horizontalLayout
                        ? Math.floor(layoutIndex / Math.max(1, layoutRows)) * cellSize
                        : (layoutIndex % Math.max(1, layoutColumns)) * cellSize) + layoutOffsetX
                     : (item ? item.x : 0)
    y: indexedLayout ? (horizontalLayout
                        ? (layoutIndex % Math.max(1, layoutRows)) * verticalCellSize
                        : Math.floor(layoutIndex / Math.max(1, layoutColumns)) * verticalCellSize) + layoutOffsetY
                     : (item ? item.y : 0)

    opacity: 0

    Component.onCompleted: enterAnimation.start()

    ParallelAnimation {
        id: enterAnimation
        NumberAnimation { target: appIcon; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: appIcon; property: "entryScale"; to: 1; duration: 260; easing.type: Easing.OutBack }
    }

    // 拖动时置于顶层
    z: dragArea.drag.active ? 999 : 0

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: 14
        color: dragArea.drag.active
               ? (appIcon.lightTheme ? "#28000000" : "#35ffffff")
               : dragArea.containsMouse
                 ? (appIcon.lightTheme ? "#14000000" : "#20ffffff")
                 : "transparent"
        border.width: dragArea.drag.active ? 1 : 0
        border.color: appIcon.lightTheme ? "#30000000" : "#45ffffff"
        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.width { NumberAnimation { duration: 100 } }
    }

    Item {
        width: appIcon.iconSize
        height: appIcon.iconSize

        // 拖动时半透明
        opacity: dragArea.drag.active ? 0.82 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Rectangle {
            anchors.fill: parent
            radius: Math.max(10, width * 0.22)
            visible: appIcon.autoFillTransparentIcons
                     && appIcon.item && appIcon.item.iconHasTransparency
            color: appIcon.lightTheme ? "#24000000" : "#32ffffff"
            border.width: 1
            border.color: appIcon.lightTheme ? "#18000000" : "#20ffffff"
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Image {
            anchors.fill: parent
            anchors.margins: Math.max(2, appIcon.iconSize * 0.04)
            source: item ? item.icon : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            sourceSize.width: 256
            sourceSize.height: 256
        }
    }

    Text {
        y: appIcon.iconSize + 4
        width: appIcon.width
        text: item ? item.name : ""
        color: appIcon.labelColor
        visible: appIcon.showName
        font.pixelSize: 12
        font.weight: dragArea.containsMouse ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
        maximumLineCount: 1
        horizontalAlignment: Text.AlignHCenter
        opacity: dragArea.containsMouse ? 1.0 : 0.88
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // 右键菜单
    Menu {
        id: contextMenu
        popupType: Popup.Window

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
        hoverEnabled: true
        drag.target: appIcon.draggable ? appIcon : null
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
                contextMenu.popup(mouse.x, mouse.y);
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

            if (!wasDragged || !appIcon.draggable) {
                // 左键单击 → 打开文件
                appIcon.openRequest();
                return;
            }

            // ---- 拖拽结束: 吸附网格 & 触发排序 ----
            let gridSize = appIcon.cellSize;
            let nx = Math.max(0, Math.min(Math.round(appIcon.x / gridSize) * gridSize,
                                          appIcon.parent.width - appIcon.width));
            let ny = Math.max(0, Math.min(Math.round(appIcon.y / appIcon.verticalCellSize) * appIcon.verticalCellSize,
                                          appIcon.parent.height - appIcon.height));

            // 先更新 model
            appIcon.requestMove(appIcon.itemIndex, nx, ny);

            // 修复被 drag.target 破坏的绑定
            appIcon.x = Qt.binding(function() { return appIcon.item ? appIcon.item.x : 0; });
            appIcon.y = Qt.binding(function() { return appIcon.item ? appIcon.item.y : 0; });
        }
    }

    // 悬停放大 / 拖拽放大
    scale: entryScale * (dragArea.drag.active ? 1.10
                         : (dragArea.pressed && (dragArea.pressedButtons & Qt.LeftButton)) ? 0.96
                         : (dragArea.containsMouse || contextMenu.visible) ? 1.04 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
}
