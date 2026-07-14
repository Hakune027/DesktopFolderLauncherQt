import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Effects

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
        onVisibleChanged: {
            if (!visible && !root.active && root.overflowExpanded)
                desktopCollapseTimer.restart();
        }
    }

    Menu {
        id: folderContextMenu
        popupType: Popup.Window
        MenuItem {
            text: "溢出收纳模式"
            checkable: true
            checked: root.folderData && root.folderData.overflowMode
            onTriggered: {
                if (root.folderData) {
                    root.folderData.overflowMode = checked;
                    folderManager.save();
                }
            }
        }
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
    property int configuredColumns: folderData ? folderData.gridColumns : 3
    property int configuredRows: folderData ? folderData.gridRows : 2
    property string expansionDirection: folderData ? folderData.expansionDirection : "down"
    property bool horizontalExpansion: expansionDirection === "left"
                                       || expansionDirection === "right"
    property bool overflowEnabled: folderData && folderData.overflowMode
    property int compactVisibleCount: Math.max(1, configuredColumns * configuredRows - 1)
    property int overflowClusterSlot: expansionDirection === "up"
                                      ? Math.max(0, configuredColumns - 1)
                                      : expansionDirection === "left"
                                        ? Math.max(0, (configuredRows - 1) * configuredColumns)
                                        : Math.max(0, configuredColumns * configuredRows - 1)
    property bool overflowExpanded: false
    property bool iconContextMenuOpen: false
    property int totalItems: folderData ? folderData.itemCount : 0
    property bool hasOverflow: overflowEnabled && totalItems > compactVisibleCount
    property int collapsedSlots: Math.min(totalItems, compactVisibleCount) + (hasOverflow ? 1 : 0)
    property int layoutColumns: overflowEnabled && overflowExpanded && horizontalExpansion
                                ? Math.max(configuredColumns,
                                           Math.ceil(totalItems / Math.max(1, configuredRows)))
                                : configuredColumns
    property int layoutRows: overflowEnabled && overflowExpanded && !horizontalExpansion
                             ? Math.max(configuredRows,
                                        Math.ceil(totalItems / Math.max(1, configuredColumns)))
                             : configuredRows
    property real collapsedAnchorX: 0
    property real collapsedAnchorY: 0
    property real expansionAnchorRight: 0
    property real expansionAnchorBottom: 0
    property string activeExpansionDirection: "down"
    property bool hasCollapsedAnchor: false
    function compactSlotForIndex(index) {
        return index >= overflowClusterSlot ? index + 1 : index;
    }
    function expandedSlotForIndex(index) {
        let extraRows = Math.max(0, layoutRows - configuredRows);
        let extraColumns = Math.max(0, layoutColumns - configuredColumns);
        let baseRowOffset = expansionDirection === "up" ? extraRows : 0;
        let baseColumnOffset = expansionDirection === "left" ? extraColumns : 0;

        if (index < compactVisibleCount) {
            let compactSlot = compactSlotForIndex(index);
            let baseRow = Math.floor(compactSlot / configuredColumns);
            let baseColumn = compactSlot % configuredColumns;
            return baseRow * layoutColumns + baseColumn;
        }

        let overflowIndex = index - compactVisibleCount;
        let clusterRow = Math.floor(overflowClusterSlot / configuredColumns) + baseRowOffset;
        let clusterColumn = overflowClusterSlot % configuredColumns + baseColumnOffset;
        if (overflowIndex === 0)
            return clusterRow * layoutColumns + clusterColumn;

        let remaining = overflowIndex - 1;
        if (expansionDirection === "up") {
            for (let row = extraRows - 1; row >= 0; --row)
                for (let column = 0; column < layoutColumns; ++column)
                    if (remaining-- === 0) return row * layoutColumns + column;
        } else if (expansionDirection === "left") {
            for (let column = extraColumns - 1; column >= 0; --column)
                for (let row = 0; row < layoutRows; ++row)
                    if (remaining-- === 0) return row * layoutColumns + column;
        } else if (expansionDirection === "right") {
            for (let column = configuredColumns; column < layoutColumns; ++column)
                for (let row = 0; row < layoutRows; ++row)
                    if (remaining-- === 0) return row * layoutColumns + column;
        } else {
            for (let row = configuredRows; row < layoutRows; ++row)
                for (let column = 0; column < layoutColumns; ++column)
                    if (remaining-- === 0) return row * layoutColumns + column;
        }
        return clusterRow * layoutColumns + clusterColumn;
    }
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
    property int targetWindowWidth: layoutGridWidth + layoutEdgePadding * 2
    property int targetWindowHeight: layoutHeaderHeight + layoutGridHeight + layoutEdgePadding * 2
    property bool geometryReady: false
    property bool lightTheme: folderData && folderData.backgroundStyle === "white"
    property color foregroundColor: lightTheme ? "#E6202430" : "#F5FFFFFF"
    property color mutedColor: lightTheme ? "#991A1E28" : "#A8FFFFFF"
    property bool frostedGlassEnabled: folderData && folderData.frostedGlass
    property string currentBorderStyle: folderData ? folderData.borderStyle : "subtle"

    width: 1
    height: 1

    // 初始隐藏, 等恢复位置后再显示, 避免闪烁 & 位置竞态
    visible: false
    opacity: 0

    // Desktop widgets must remain interactive without becoming the active
    // top-level window. Otherwise Windows raises them above normal apps as
    // soon as the user clicks an icon.
    flags: Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint
           | Qt.WindowDoesNotAcceptFocus

    color: "transparent"

    ParallelAnimation {
        id: windowEnterAnimation
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: folder; property: "scale"; from: 0.96; to: 1; duration: 280; easing.type: Easing.OutBack }
    }

    function clampToAvailableScreen() {
        if (!root.screen)
            return;
        let area = root.screen.availableGeometry;
        let areaX = area && area.x !== undefined ? area.x : (root.screen.virtualX || 0);
        let areaY = area && area.y !== undefined ? area.y : (root.screen.virtualY || 0);
        let areaWidth = area && area.width !== undefined
                ? area.width : (root.screen.desktopAvailableWidth || root.screen.width || root.width);
        let areaHeight = area && area.height !== undefined
                ? area.height : (root.screen.desktopAvailableHeight || root.screen.height || root.height);
        root.x = Math.max(areaX, Math.min(root.x,
                                         areaX + Math.max(0, areaWidth - root.width)));
        root.y = Math.max(areaY, Math.min(root.y,
                                         areaY + Math.max(0, areaHeight - root.height)));
    }

    function applyWindowEffects() {
        if (root.visible && typeof windowEffects !== "undefined")
            windowEffects.applyFrostedGlass(root, root.frostedGlassEnabled,
                                            root.lightTheme, false);
    }

    function animateToTargetGeometry() {
        if (!geometryReady || typeof windowEffects === "undefined")
            return;
        let targetX = hasCollapsedAnchor && activeExpansionDirection === "left"
                ? (overflowExpanded ? expansionAnchorRight - targetWindowWidth : collapsedAnchorX)
                : root.x;
        let targetY = hasCollapsedAnchor && activeExpansionDirection === "up"
                ? (overflowExpanded ? expansionAnchorBottom - targetWindowHeight : collapsedAnchorY)
                : root.y;
        if (!overflowExpanded && hasCollapsedAnchor) {
            targetX = collapsedAnchorX;
            targetY = collapsedAnchorY;
        }
        windowEffects.animateGeometry(root, targetX, targetY,
                                      targetWindowWidth, targetWindowHeight, 240);
    }

    onTargetWindowWidthChanged: if (geometryReady) Qt.callLater(animateToTargetGeometry)
    onTargetWindowHeightChanged: if (geometryReady) Qt.callLater(animateToTargetGeometry)

    onFrostedGlassEnabledChanged: Qt.callLater(applyWindowEffects)
    onLightThemeChanged: Qt.callLater(applyWindowEffects)
    onOverflowEnabledChanged: if (!overflowEnabled) overflowExpanded = false
    onHasOverflowChanged: if (!hasOverflow) overflowExpanded = false
    onOverflowExpandedChanged: {
        if (overflowExpanded) {
            collapsedAnchorX = root.x;
            collapsedAnchorY = root.y;
            expansionAnchorRight = root.x + root.width;
            expansionAnchorBottom = root.y + root.height;
            activeExpansionDirection = expansionDirection;
            hasCollapsedAnchor = true;
            // Keep the component on the desktop layer even while expanded.
            // Menus and the settings window are independent popup windows and
            // can still activate normally.
            if (typeof windowEffects !== "undefined")
                windowEffects.sendToDesktopLayer(root);
        }
        Qt.callLater(root.animateToTargetGeometry);
        geometrySettleTimer.restart();
    }
    Timer {
        id: geometrySettleTimer
        interval: 260
        repeat: false
        onTriggered: {
            if (!root.overflowExpanded) {
                root.hasCollapsedAnchor = false;
                Qt.callLater(root.clampToAvailableScreen);
                if (typeof windowEffects !== "undefined")
                    windowEffects.sendToDesktopLayer(root);
            }
        }
    }
    onExpansionDirectionChanged: if (overflowExpanded) overflowExpanded = false
    onActiveChanged: {
        if (!active && overflowExpanded)
            desktopCollapseTimer.restart();
    }

    Connections {
        target: typeof windowEffects !== "undefined" ? windowEffects : null
        function onDesktopClicked() {
            if (root.overflowExpanded
                    && !folderContextMenu.visible
                    && !root.iconContextMenuOpen
                    && !folderSettingsWindow.visible)
                root.overflowExpanded = false;
        }
    }

    Timer {
        id: desktopCollapseTimer
        interval: 140
        repeat: false
        onTriggered: {
            if (!root.active && root.overflowExpanded
                    && !folderContextMenu.visible
                    && !root.iconContextMenuOpen
                    && !folderSettingsWindow.visible)
                root.overflowExpanded = false;
        }
    }

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
            let configuredOpacity = root.folderData ? root.folderData.backgroundOpacity : 0.8;
            let effectiveOpacity = root.overflowExpanded
                    ? Math.max(configuredOpacity, 0.86) : configuredOpacity;
            if (root.frostedGlassEnabled) {
                let glassTint = effectiveOpacity * (root.overflowExpanded ? 0.62 : 0.28);
                return root.lightTheme
                       ? Qt.rgba(1, 1, 1, glassTint)
                       : Qt.rgba(0.04, 0.04, 0.055, glassTint);
            }
            return root.folderData && root.folderData.backgroundStyle === "white"
                   ? Qt.rgba(1, 1, 1, effectiveOpacity)
                   : Qt.rgba(0.125, 0.125, 0.125, effectiveOpacity);
        }

        border.width: {
            if (root.frostedGlassEnabled || root.currentBorderStyle === "none")
                return 0;
            return root.currentBorderStyle === "accent" ? 2 : 1;
        }

        border.color: {
            if (root.currentBorderStyle === "accent")
                return root.lightTheme ? "#785B6CFF" : "#A08D9AFF";
            if (root.currentBorderStyle === "solid")
                return root.lightTheme ? "#50000000" : "#70ffffff";
            return root.lightTheme ? "#26000000" : "#36ffffff";
        }

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
            visible: !root.frostedGlassEnabled && root.currentBorderStyle === "double"
        }


        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: folderContextMenu.popup()
        }

        // Declared behind the interactive children, so only a genuine click
        // on empty folder space collapses the expanded grid.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            enabled: root.hasOverflow && root.overflowExpanded
            onClicked: root.overflowExpanded = false
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
                    autoFillTransparentIcons: root.folderData
                                              ? root.folderData.autoFillTransparentIcons : false
                    iconTone: root.folderData ? root.folderData.iconTone : "original"

                    itemIndex: index
                    visible: !root.overflowEnabled || root.overflowExpanded
                             || index < root.compactVisibleCount
                    indexedLayout: root.overflowEnabled
                    layoutIndex: root.overflowEnabled
                                 ? (root.overflowExpanded
                                    ? root.expandedSlotForIndex(index)
                                    : root.compactSlotForIndex(index))
                                 : index
                    layoutColumns: root.layoutColumns
                    layoutRows: root.layoutRows
                    horizontalLayout: false
                    layoutOffsetX: index < root.compactVisibleCount
                                   && root.activeExpansionDirection === "left"
                                   && root.hasCollapsedAnchor
                                   ? root.width - (root.expansionAnchorRight - root.collapsedAnchorX) : 0
                    layoutOffsetY: index < root.compactVisibleCount
                                   && root.activeExpansionDirection === "up"
                                   && root.hasCollapsedAnchor
                                   ? root.height - (root.expansionAnchorBottom - root.collapsedAnchorY) : 0
                    draggable: !root.overflowEnabled
                    onContextMenuOpenChanged: root.iconContextMenuOpen = contextMenuOpen

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

            Rectangle {
                id: overflowCluster
                visible: root.hasOverflow && !root.overflowExpanded
                x: (root.overflowClusterSlot % Math.max(1, root.configuredColumns))
                   * root.layoutCellSize
                y: Math.floor(root.overflowClusterSlot / Math.max(1, root.configuredColumns))
                   * root.layoutVerticalCellSize
                width: root.layoutIconSize
                height: root.layoutIconSize
                radius: Math.max(10, width * 0.22)
                color: clusterHover.hovered
                       ? (root.lightTheme ? "#22000000" : "#32ffffff")
                       : (root.lightTheme ? "#14000000" : "#22ffffff")
                border.width: 1
                border.color: root.lightTheme ? "#18000000" : "#28ffffff"
                z: 50

                Repeater {
                    model: Math.min(4, Math.max(0, root.totalItems - root.compactVisibleCount))
                    Item {
                        required property int index
                        readonly property var overflowItem: root.folderData
                                                            ? root.folderData.items.itemAt(root.compactVisibleCount + index)
                                                            : null
                        width: overflowCluster.width * 0.31
                        height: width
                        x: overflowCluster.width * (index % 2 === 0 ? 0.16 : 0.53)
                        y: overflowCluster.height * (index < 2 ? 0.16 : 0.53)
                        Image {
                            id: overflowSourceIcon
                            anchors.fill: parent
                            source: parent.overflowItem ? parent.overflowItem.icon : ""
                            sourceSize.width: 96
                            sourceSize.height: 96
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                        ShaderEffectSource {
                            id: overflowToneSource
                            anchors.fill: overflowSourceIcon
                            sourceItem: overflowSourceIcon
                            hideSource: root.folderData && root.folderData.iconTone !== "original"
                            live: true
                            smooth: true
                        }
                        MultiEffect {
                            anchors.fill: overflowSourceIcon
                            source: overflowToneSource
                            visible: root.folderData && root.folderData.iconTone === "grayscale"
                            saturation: -1
                        }
                    }
                }

                HoverHandler { id: clusterHover }
                TapHandler { onTapped: root.overflowExpanded = true }
                Behavior on color { ColorAnimation { duration: 130 } }
                scale: clusterHover.hovered ? 1.05 : 1
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
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
            root.width = root.targetWindowWidth;
            root.height = root.targetWindowHeight;
            root.geometryReady = true;
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
                if (typeof windowEffects !== "undefined")
                    windowEffects.sendToDesktopLayer(root);
            });
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
