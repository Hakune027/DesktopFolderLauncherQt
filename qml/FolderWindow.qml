import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: root

    // 当前文件夹数据对象
    property var folderData

    property string folderName: folderData ? folderData.name : "开发工具"
    property bool nativeDropRegistered: false

    FolderSettingsWindow {
        id: folderSettingsWindow
        folderData: root.folderData
        transientParent: root
    }

    Menu {
        id: folderContextMenu
        MenuItem {
            text: "文件夹设置"
            onTriggered: {
                folderSettingsWindow.openForFolderWindow();
            }
        }
    }

    property int layoutEffectiveSpacing: folderData
                                         ? (folderData.showIconNames
                                            ? folderData.iconSpacing
                                            : Math.max(4, folderData.iconSpacing - 20))
                                         : 36
    property int layoutCellSize: layoutIconSize + layoutEffectiveSpacing
    property int layoutEdgePadding: folderData ? folderData.edgePadding : 20
    property int layoutColumns: folderData ? folderData.gridColumns : 3
    property int layoutRows: folderData ? folderData.gridRows : 2
    property int layoutIconSize: folderData ? folderData.iconSize : 64
    property bool showFolderHeader: !folderData || folderData.showFolderName
    property bool showIconLabels: !folderData || folderData.showIconNames
    property int layoutHeaderHeight: showFolderHeader ? 50 : 0
    property int layoutVerticalSpacing: layoutEffectiveSpacing
    property int layoutVerticalCellSize: layoutIconSize + layoutVerticalSpacing
    property int layoutGridWidth: layoutColumns * layoutIconSize
                                  + Math.max(0, layoutColumns - 1) * (layoutCellSize - layoutIconSize)
    property int layoutGridHeight: layoutRows * layoutIconSize
                                   + Math.max(0, layoutRows - 1) * layoutVerticalSpacing
    property bool lightTheme: folderData && folderData.backgroundStyle === "white"
    property color foregroundColor: lightTheme ? "#E6202430" : "#F5FFFFFF"
    property color mutedColor: lightTheme ? "#991A1E28" : "#A8FFFFFF"
    property bool frostedGlassEnabled: folderData && folderData.frostedGlass

    width: layoutGridWidth + layoutEdgePadding * 2

    height: layoutHeaderHeight + layoutGridHeight + layoutEdgePadding * 2

    // 初始隐藏, 等恢复位置后再显示, 避免闪烁 & 位置竞态
    visible: false
    opacity: 0

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    color: "transparent"

    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    ParallelAnimation {
        id: windowEnterAnimation
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: folder; property: "scale"; from: 0.96; to: 1; duration: 280; easing.type: Easing.OutBack }
    }

    function clampToAvailableScreen() {
        if (!root.screen)
            return;
        let area = root.screen.availableGeometry;
        root.x = Math.max(area.x, Math.min(root.x,
                                           area.x + Math.max(0, area.width - root.width)));
        root.y = Math.max(area.y, Math.min(root.y,
                                           area.y + Math.max(0, area.height - root.height)));
    }

    function applyWindowEffects() {
        if (root.visible && typeof windowEffects !== "undefined")
            windowEffects.applyFrostedGlass(root, root.frostedGlassEnabled,
                                            root.lightTheme);
    }

    onFrostedGlassEnabledChanged: Qt.callLater(applyWindowEffects)
    onLightThemeChanged: Qt.callLater(applyWindowEffects)

    onScreenChanged: Qt.callLater(clampToAvailableScreen)

    // ====== 外部文件拖放接收层(最底层, Qt 内部 OLE 翻译) ======
    DropArea {
        id: fileDropArea

        anchors.fill: parent
        z: 1000

        onEntered: function (drag) {
            if (drag.hasUrls)
                drag.acceptProposedAction();
        }

        onDropped: function (drop) {
            if (!root.folderData || !drop.hasUrls)
                return;

            for (let i = 0; i < drop.urls.length; i++) {
                root.folderData.addFile(drop.urls[i]);
            }
            drop.acceptProposedAction();
        }
    }

    // ====== 文件夹主体 ======
    Rectangle {
        id: folder

        anchors.fill: parent

        radius: root.frostedGlassEnabled ? 0
                                         : (root.folderData ? root.folderData.cornerRadius : 30)

        color: {
            if (root.frostedGlassEnabled) {
                let glassTint = (root.folderData ? root.folderData.backgroundOpacity : 0.8) * 0.28;
                return root.lightTheme
                       ? Qt.rgba(1, 1, 1, glassTint)
                       : Qt.rgba(0.04, 0.04, 0.055, glassTint);
            }
            let opacity = root.folderData ? root.folderData.backgroundOpacity : 0.8;
            return root.folderData && root.folderData.backgroundStyle === "white"
                   ? Qt.rgba(1, 1, 1, opacity)
                   : Qt.rgba(0.125, 0.125, 0.125, opacity);
        }

        border.width: root.frostedGlassEnabled ? 0 : 1

        border.color: root.lightTheme ? "#26000000" : "#36ffffff"

        Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, folder.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: root.lightTheme ? "#20ffffff" : "#16ffffff"
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: folderContextMenu.popup()
        }

        // ---- 标题栏 ----
        Row {
            x: root.layoutEdgePadding
            y: 12
            height: 30
            visible: root.showFolderHeader
            spacing: 10

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: root.lightTheme ? "#5B6CFF" : "#8D9AFF"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.folderName
                color: root.foregroundColor
                visible: root.showFolderHeader
                font.pixelSize: 18
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                width: Math.max(0, root.width - root.layoutEdgePadding * 2 - 82)
            }

            Rectangle {
                width: countText.implicitWidth + 14
                height: 24
                radius: 12
                color: root.lightTheme ? "#10000000" : "#18ffffff"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.folderData ? root.folderData.itemCount : 0
                    color: root.mutedColor
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }

        // ---- 图标区(可拖放排序) ----
        Item {
            x: root.layoutEdgePadding
            y: root.layoutHeaderHeight + root.layoutEdgePadding
            width: root.layoutGridWidth
            height: root.layoutGridHeight

            Repeater {
                model: folderData ? folderData.items : null

                delegate: AppIcon {
                    item: model.item
                    iconSize: root.folderData ? root.folderData.iconSize : 64
                    cellSize: root.layoutCellSize
                    verticalCellSize: root.layoutVerticalCellSize
                    showName: root.folderData ? root.folderData.showIconNames : true
                    labelColor: root.folderData && root.folderData.backgroundStyle === "white"
                                ? "#202020" : "white"
                    lightTheme: root.lightTheme
                    showIconShadow: root.folderData ? root.folderData.showIconShadow : true

                    itemIndex: index

                    // 单击 / 右键菜单 → 打开文件
                    onOpenRequest: {
                        if (item) {
                            item.open();
                        }
                    }

                    // 右键菜单 → 打开文件位置
                    onOpenLocationRequest: function (path) {
                        folderData.openLocation(path);
                    }

                    // 右键菜单 → 删除
                    onRemoveRequest: function (index) {
                        folderData.removeFile(index);
                    }

                    // 拖拽排序: 交换位置或移动到空位
                    onRequestMove: function (index, x, y) {
                        folderData.moveItemToPosition(index, x, y);
                    }
                }
            }
        }
    }

    // ====== 窗口拖动条(顶部) ======
    MouseArea {
        id: dragArea
        z: 1001
        enabled: !root.folderData || !root.folderData.lockPosition

        width: parent.width

        height: root.showFolderHeader ? 46 : Math.min(16, root.layoutEdgePadding)

        onPressed: function (mouse) {
            root.startSystemMove();

            console.log(
                "[FolderWindow] 开始拖动:",
                root.folderName,
                "window=(" + root.x + "," + root.y + ")"
            );
        }

        onReleased: function (mouse) {
            // 松手时立即写盘, 防止 onClosing 未触发导致位置丢失
            console.log(
                "[FolderWindow] 拖动结束, 保存位置:",
                root.folderName,
                "(" + root.x + "," + root.y + ")"
            );

            if (root.folderData) {
                root.folderData.setWindowPosition(root.x, root.y);
            }
            if (typeof folderManager !== 'undefined') {
                folderManager.save();
            }
        }
    }

    // ====== 延迟恢复+显示: 先设位置再 visible=true, 消除位置竞态 ======
    Timer {
        id: restoreTimer

        interval: 0
        repeat: false

        onTriggered: {
            console.log(
                "[FolderWindow] Timer触发:",
                root.folderName,
                "saved=(" +
                    (root.folderData ? root.folderData.windowX : "?") + "," +
                    (root.folderData ? root.folderData.windowY : "?") + ")",
                "current=(" + root.x + "," + root.y + ")"
            );

            if (root.folderData &&
                root.folderData.windowX >= 0 &&
                root.folderData.windowY >= 0)
            {
                root.x = root.folderData.windowX;
                root.y = root.folderData.windowY;

                console.log(
                    "[FolderWindow] 已恢复位置:",
                    root.folderName,
                    "(" + root.x + "," + root.y + ")"
                );
            } else {
                console.log(
                    "[FolderWindow] 无保存位置, 使用默认:",
                    root.folderName
                );
            }

            // 最终显示窗口(位置已确定, 不会闪烁)
            root.visible = true;
            windowEnterAnimation.start();
            Qt.callLater(root.applyWindowEffects);
            Qt.callLater(root.clampToAvailableScreen);
            Qt.callLater(function() {
                if (!root.nativeDropRegistered && root.folderData) {
                    dropHandler.registerWindowTarget(root, root.folderData, "addFile");
                    root.nativeDropRegistered = true;
                }
            });
        }
    }

    Component.onCompleted: {
        console.log(
            "[FolderWindow] Component.onCompleted:",
            root.folderName,
            "saved=(" +
                (root.folderData ? root.folderData.windowX : "?") + "," +
                (root.folderData ? root.folderData.windowY : "?") + ")"
        );
        restoreTimer.start();
    }

    // ====== 关闭时持久化窗口位置 ======
    onClosing: function () {
        console.log(
            "[FolderWindow] onClosing:",
            root.folderName,
            "position=(" + root.x + "," + root.y + ")"
        );

        if (root.folderData) {
            root.folderData.setWindowPosition(root.x, root.y);
        }
        if (typeof folderManager !== 'undefined') {
            folderManager.save();
        }
        if (root.nativeDropRegistered) {
            dropHandler.unregisterWindowTarget(root);
            root.nativeDropRegistered = false;
        }
        if (typeof windowEffects !== "undefined")
            windowEffects.applyFrostedGlass(root, false, root.lightTheme);
    }
}
