import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    property var folderData
    property var borderStyleValues: ["none", "subtle", "solid", "accent", "double"]
    property var expansionDirectionValues: ["down", "up", "right", "left"]

    width: 700
    height: 590
    minimumWidth: 620
    minimumHeight: 460
    visible: false
    flags: Qt.Window | Qt.FramelessWindowHint
    title: folderData ? folderData.name + " - 文件夹设置" : "文件夹设置"
    color: Qt.rgba(0.055, 0.06, 0.075, 0.62)
    palette.window: "#17181d"
    palette.windowText: "#f5f5f5"
    palette.base: "#23252b"
    palette.text: "#f5f5f5"
    palette.button: "#2c2e35"
    palette.buttonText: "#f5f5f5"
    palette.highlight: "#7b83ff"
    palette.highlightedText: "white"

    function applyGlass() {
        if (typeof windowEffects !== "undefined") {
            windowEffects.applyFrostedGlass(root, root.visible, false);
        }
    }
    function persist() {
        if (typeof folderManager !== "undefined")
            folderManager.save();
    }
    property int pendingGridColumns: 1
    property int pendingGridRows: 2

    function applyGridSize(columns, rows) {
        if (!root.folderData)
            return;
        root.folderData.gridColumns = columns;
        root.folderData.gridRows = rows;
        columnsSpin.value = root.folderData.gridColumns;
        rowsSpin.value = root.folderData.gridRows;
        root.persist();
    }

    function requestGridSize(columns, rows, changedAxis) {
        if (!root.folderData)
            return;
        if (columns * rows < 2) {
            if (changedAxis === "columns")
                rows = 2;
            else
                columns = 2;
        }
        if (!root.folderData.overflowMode
                && columns * rows < root.folderData.itemCount) {
            root.pendingGridColumns = columns;
            root.pendingGridRows = rows;
            overflowPrompt.open();
            return;
        }
        root.applyGridSize(columns, rows);
    }
    function openForFolderWindow() {
        let owner = root.transientParent;
        let targetScreen = owner && owner.screen ? owner.screen : root.screen;
        let desiredX = owner ? owner.x + Math.round((owner.width - root.width) / 2) : root.x;
        let desiredY = owner ? owner.y + Math.round((owner.height - root.height) / 2) : root.y;
        if (targetScreen) {
            let area = targetScreen.availableGeometry;
            let areaX = area && area.x !== undefined ? area.x : (targetScreen.virtualX || 0);
            let areaY = area && area.y !== undefined ? area.y : (targetScreen.virtualY || 0);
            let areaWidth = area && area.width !== undefined
                    ? area.width : (targetScreen.desktopAvailableWidth || targetScreen.width || root.width);
            let areaHeight = area && area.height !== undefined
                    ? area.height : (targetScreen.desktopAvailableHeight || targetScreen.height || root.height);
            desiredX = Math.max(areaX, Math.min(desiredX,
                                areaX + Math.max(0, areaWidth - root.width)));
            desiredY = Math.max(areaY, Math.min(desiredY,
                                areaY + Math.max(0, areaHeight - root.height)));
        }
        root.x = desiredX;
        root.y = desiredY;
        root.show();
        root.raise();
        root.requestActivate();
        Qt.callLater(root.applyGlass);
    }

    onVisibleChanged: Qt.callLater(root.applyGlass)

    Dialog {
        id: overflowPrompt
        title: "容量不足"
        modal: true
        anchors.centerIn: parent
        width: Math.min(360, root.width - 48)
        height: 190
        standardButtons: Dialog.Ok | Dialog.Cancel

        Label {
            width: overflowPrompt.availableWidth
            text: "新容量小于当前图标数量。是否开启溢出收纳模式，并将多余图标收纳到最后一个格子？"
            color: "#e7e7ea"
            wrapMode: Text.WordWrap
            lineHeight: 1.35
        }

        onAccepted: {
            if (root.folderData) {
                root.folderData.overflowMode = true;
                root.applyGridSize(root.pendingGridColumns, root.pendingGridRows);
            }
        }
        onRejected: {
            if (root.folderData) {
                columnsSpin.value = root.folderData.gridColumns;
                rowsSpin.value = root.folderData.gridRows;
            }
        }
    }

    // ═══════════════════════════════════════════
    // Custom Toggle Switch
    // ═══════════════════════════════════════════
    component ToggleSwitch: Item {
        id: toggle
        property bool checked: false
        signal toggled(bool checked)
        implicitWidth: 42; implicitHeight: 24

        Rectangle {
            width: 42; height: 24; radius: 12
            color: toggle.checked ? "#7b83ff" : "#3affffff"
            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Rectangle {
                width: 20; height: 20; radius: 10
                x: toggle.checked ? 20 : 2
                y: 2
                color: "white"
                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: toggle.toggled(!toggle.checked)
            }
        }
    }

    // ═══════════════════════════════════════════
    // Section Card
    // ═══════════════════════════════════════════
    component SectionCard: Rectangle {
        property string sectionTitle: ""
        Layout.fillWidth: true
        Layout.preferredHeight: cardContent.implicitHeight + 40
        radius: 14
        color: "#0cffffff"
        border.color: "#14ffffff"

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                visible: sectionTitle !== ""
                spacing: 8
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: "#8D9AFF"
                    Layout.alignment: Qt.AlignVCenter
                }
                Label {
                    text: sectionTitle
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: "#e7e7ea"
                }
            }

            ColumnLayout {
                id: cardFields
                spacing: 14
                Layout.fillWidth: true
            }
        }

        property alias fields: cardFields.data
    }

    // ═══════════════════════════════════════════
    // Info Callout (blue hint box)
    // ═══════════════════════════════════════════
    component InfoCallout: Rectangle {
        property alias calloutText: calloutLabel.text
        Layout.fillWidth: true
        Layout.preferredHeight: calloutLabel.implicitHeight + 18
        radius: 7
        color: "#143b82f6"
        border.width: 1
        border.color: "#306aa9ff"

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3; radius: 2
            color: "#77a7ff"
        }

        Label {
            id: calloutLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 13
            anchors.rightMargin: 10
            textFormat: Text.MarkdownText
            color: "#c9d9f6"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    // ═══════════════════════════════════════════
    // Setting Row (label + control)
    // ═══════════════════════════════════════════
    component SettingRow: RowLayout {
        property alias title: rowLabel.text
        spacing: 16
        Layout.fillWidth: true
        clip: true

        Label {
            id: rowLabel
            Layout.preferredWidth: 140
            color: "#c5c5cc"
            font.pixelSize: 13
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
    }

    // ═══════════════════════════════════════════
    // Slider value label
    // ═══════════════════════════════════════════
    component SliderValue: Label {
        Layout.preferredWidth: 52
        horizontalAlignment: Text.AlignRight
        color: "#b7b8c0"
        font.pixelSize: 13
    }

    // ═══════════════════════════════════════════
    // Custom-styled Slider factory
    // ═══════════════════════════════════════════
    component StyledSlider: Slider {
        id: slider
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - 2
            implicitWidth: 200; implicitHeight: 4
            width: slider.availableWidth; height: 4
            radius: 2
            color: slider.enabled ? "#2affffff" : "#10ffffff"

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height; radius: 2
                color: slider.enabled ? "#7b83ff" : "#30ffffff"
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 18; implicitHeight: 18
            radius: 9
            color: slider.enabled ? "white" : "#50ffffff"
        }
    }

    // ═══════════════════════════════════════════
    // Main Layout
    // ═══════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        spacing: 0

        // ── Custom Title Bar ────────────────
        Rectangle {
            id: titleBar
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                property point clickPos: Qt.point(0, 0)
                onPressed: function(mouse) {
                    clickPos = Qt.point(mouse.x, mouse.y);
                }
                onPositionChanged: function(mouse) {
                    root.x += mouse.x - clickPos.x;
                    root.y += mouse.y - clickPos.y;
                }
                onReleased: {
                    if (root.folderData) {
                        // settings window position not persisted; no-op
                    }
                }
                onDoubleClicked: root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 8
                spacing: 10

                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: "#32ffffff"
                    FluentIcon { anchors.centerIn: parent; name: "folder"; width: 21; height: 21 }
                }

                Label {
                    Layout.fillWidth: true
                    text: root.folderData ? root.folderData.name + " · 文件夹设置" : "文件夹设置"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: "#f0f0f5"
                    elide: Text.ElideRight
                }

                // Close button
                Rectangle {
                    width: 28; height: 28; radius: 6
                    color: closeHover.hovered ? "#25ff6b6b" : "transparent"
                    Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    HoverHandler { id: closeHover }

                    FluentIcon { anchors.centerIn: parent; name: "close"; width: 15; height: 15; opacity: closeHover.hovered ? 1 : 0.72 }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }
        }

        // ── Divider ────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#14ffffff"
        }

        // ── Body: Sidebar + Content ────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 14
            Layout.bottomMargin: 16
            spacing: 12

            // ── Sidebar ──────────────────────
            Rectangle {
                Layout.preferredWidth: 150
                Layout.fillHeight: true
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    // Subtitle
                    Label {
                        text: "独立调整此桌面文件夹"
                        color: "#7e7f88"
                        font.pixelSize: 12
                        Layout.leftMargin: 2
                        Layout.bottomMargin: 14
                    }

                    // Nav items
                    Repeater {
                        model: [
                            { icon: "appearance", label: "外观", page: 0 },
                            { icon: "layout", label: "布局", page: 1 },
                            { icon: "behavior", label: "行为", page: 2 }
                        ]

                        delegate: Rectangle {
                            id: navItem
                            property bool isActive: sidebarNav.currentIndex === modelData.page
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 8
                            color: isActive ? "#1a7b83ff" : (navHover.hovered ? "#0affffff" : "transparent")
                            Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }

                            HoverHandler { id: navHover }

                            Rectangle {
                                visible: isActive
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3; height: 20; radius: 2
                                color: "#7b83ff"
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                spacing: 10

                                FluentIcon { name: modelData.icon; width: 18; height: 18; opacity: isActive ? 1 : 0.72 }
                                Label {
                                    text: modelData.label
                                    color: isActive ? "#f0f0f5" : "#a0a1ac"
                                    font.pixelSize: 13
                                    font.weight: isActive ? Font.DemiBold : Font.Normal
                                    Behavior on color { ColorAnimation { duration: 160 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sidebarNav.currentIndex = modelData.page
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ── Separator ────────────────────
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                color: "#14ffffff"
            }

            // ── Content Area ─────────────────
            StackLayout {
                id: sidebarNav
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 22
                currentIndex: 0

                // Page 0: Appearance
                ScrollView {
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 4; radius: 2
                            color: "#30ffffff"
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: 14

                        SectionCard {
                            sectionTitle: "窗口材质"
                            fields: ColumnLayout {
                                spacing: 12

                                SettingRow {
                                    title: "磨砂玻璃"
                                    Layout.preferredHeight: 28
                                    ToggleSwitch {
                                        id: frostedToggle
                                        checked: root.folderData && root.folderData.frostedGlass
                                        onToggled: function(c) {
                                            if (root.folderData) root.folderData.frostedGlass = c;
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Label {
                                        text: frostedToggle.checked ? "已启用" : "已关闭"
                                        color: frostedToggle.checked ? "#8D9AFF" : "#7e7f88"
                                        font.pixelSize: 12
                                        Layout.alignment: Qt.AlignVCenter
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }

                                InfoCallout {
                                    visible: frostedToggle.checked
                                    calloutText: "**提示**  ·  磨砂模式使用 Windows 系统圆角，并自动隐藏醒目的窗口边框。"
                                    Layout.leftMargin: 0
                                }

                                SettingRow {
                                    title: "背景色"
                                    RadioButton {
                                        text: "深色"
                                        font.pixelSize: 13
                                        checked: !root.folderData || root.folderData.backgroundStyle === "black"
                                        onClicked: {
                                            if (root.folderData) root.folderData.backgroundStyle = "black";
                                            root.persist();
                                        }
                                    }
                                    RadioButton {
                                        text: "浅色"
                                        font.pixelSize: 13
                                        checked: root.folderData && root.folderData.backgroundStyle === "white"
                                        onClicked: {
                                            if (root.folderData) root.folderData.backgroundStyle = "white";
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                SettingRow {
                                    title: root.folderData && root.folderData.frostedGlass ? "颜色浓度" : "不透明度"
                                    StyledSlider {
                                        id: opacitySlider
                                        Layout.fillWidth: true
                                        from: 0.1; to: 1.0; stepSize: 0.05
                                        value: root.folderData ? root.folderData.backgroundOpacity : 0.8
                                        onMoved: if (root.folderData) root.folderData.backgroundOpacity = value
                                        onPressedChanged: if (!pressed) root.persist()
                                    }
                                    SliderValue { text: Math.round(opacitySlider.value * 100) + "%" }
                                }
                            }
                        }

                        SectionCard {
                            sectionTitle: "形状与边框"
                            fields: ColumnLayout {
                                spacing: 12

                                SettingRow {
                                    title: "圆角"
                                    StyledSlider {
                                        id: radiusSlider
                                        Layout.fillWidth: true
                                        from: 0; to: 60; stepSize: 1
                                        value: root.folderData ? root.folderData.cornerRadius : 30
                                        enabled: !root.folderData || !root.folderData.frostedGlass
                                        onMoved: if (root.folderData) root.folderData.cornerRadius = value
                                        onPressedChanged: if (!pressed) root.persist()
                                    }
                                    SliderValue {
                                        text: Math.round(radiusSlider.value) + " px"
                                        opacity: radiusSlider.enabled ? 1.0 : 0.35
                                    }
                                }

                                SettingRow {
                                    title: "边框样式"
                                    ComboBox {
                                        Layout.fillWidth: true
                                        enabled: !root.folderData || !root.folderData.frostedGlass
                                        model: ["无边框", "轻描边", "实线", "强调色", "双层边框"]
                                        currentIndex: root.folderData ? Math.max(0, root.borderStyleValues.indexOf(root.folderData.borderStyle)) : 1
                                        onActivated: function(index) {
                                            if (root.folderData) root.folderData.borderStyle = root.borderStyleValues[index];
                                            root.persist();
                                        }

                                        background: Rectangle {
                                            radius: 6
                                            color: "#18ffffff"
                                            border.color: "#20ffffff"
                                        }

                                        contentItem: Label {
                                            leftPadding: 12
                                            rightPadding: 30
                                            verticalAlignment: Text.AlignVCenter
                                            text: parent.displayText
                                            color: parent.enabled ? "#f5f5f5" : "#50f5f5f5"
                                            font.pixelSize: 13
                                        }

                                        indicator: Label {
                                            x: parent.width - width - 10
                                            y: parent.topPadding + (parent.availableHeight - height) / 2
                                            text: "▾"
                                            color: parent.enabled ? "#b7b8c0" : "#40b7b8c0"
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Page 1: Layout
                ScrollView {
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 4; radius: 2
                            color: "#30ffffff"
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: 14

                        SectionCard {
                            sectionTitle: "图标网格"
                            fields: ColumnLayout {
                                spacing: 14

                                SettingRow {
                                    title: "图标大小"
                                    StyledSlider {
                                        id: iconSizeSlider
                                        Layout.fillWidth: true
                                        from: 32; to: 96; stepSize: 4
                                        value: root.folderData ? root.folderData.iconSize : 64
                                        onMoved: if (root.folderData) root.folderData.iconSize = value
                                        onPressedChanged: if (!pressed) root.persist()
                                    }
                                    SliderValue { text: Math.round(iconSizeSlider.value) + " px" }
                                }

                                SettingRow {
                                    title: "图标间距"
                                    StyledSlider {
                                        id: spacingSlider
                                        Layout.fillWidth: true
                                        from: 24; to: 80; stepSize: 4
                                        value: root.folderData ? root.folderData.iconSpacing : 36
                                        onMoved: if (root.folderData) root.folderData.iconSpacing = value
                                        onPressedChanged: if (!pressed) root.persist()
                                    }
                                    SliderValue { text: Math.round(spacingSlider.value) + " px" }
                                }

                                SettingRow {
                                    title: "边缘间距"
                                    StyledSlider {
                                        id: edgeSlider
                                        Layout.fillWidth: true
                                        from: 0; to: 80; stepSize: 4
                                        value: root.folderData ? root.folderData.edgePadding : 20
                                        onMoved: if (root.folderData) root.folderData.edgePadding = value
                                        onPressedChanged: if (!pressed) root.persist()
                                    }
                                    SliderValue { text: Math.round(edgeSlider.value) + " px" }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: "#12ffffff"
                                }

                                SettingRow {
                                    title: "文件夹容量"
                                    SpinBox {
                                        id: columnsSpin
                                        from: 1; to: 12; editable: true
                                        value: root.folderData ? root.folderData.gridColumns : 3
                                        onValueModified: {
                                            root.requestGridSize(value, rowsSpin.value, "columns");
                                        }
                                    }
                                    Label { text: "×"; font.pixelSize: 18; color: "#b7b8c0" }
                                    SpinBox {
                                        id: rowsSpin
                                        from: 1; to: 12; editable: true
                                        value: root.folderData ? root.folderData.gridRows : 2
                                        onValueModified: {
                                            root.requestGridSize(columnsSpin.value, value, "rows");
                                        }
                                    }
                                    Label { text: "图标"; color: "#7e7f88"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                }

                                InfoCallout {
                                    calloutText: "**说明**  ·  窗口会根据图标大小、间距和网格容量自动调整。"
                                }
                            }
                        }
                    }
                }

                // Page 2: Behavior
                ScrollView {
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 4; radius: 2
                            color: "#30ffffff"
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: 14

                        SectionCard {
                            sectionTitle: "显示内容"
                            fields: ColumnLayout {
                                spacing: 4

                                SettingRow {
                                    title: "图标色调"
                                    Layout.preferredHeight: 38
                                    ComboBox {
                                        id: iconToneCombo
                                        Layout.preferredWidth: 126
                                        model: ["原色", "灰度"]
                                        currentIndex: {
                                            if (!root.folderData) return 0;
                                            const tones = ["original", "grayscale"];
                                            return Math.max(0, tones.indexOf(root.folderData.iconTone));
                                        }
                                        onActivated: function(index) {
                                            if (root.folderData) {
                                                root.folderData.iconTone = ["original", "grayscale"][index];
                                                root.persist();
                                            }
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                SettingRow {
                                    title: "文件夹名称"
                                    Layout.preferredHeight: 32
                                    ToggleSwitch {
                                        id: showFolderNameToggle
                                        checked: !root.folderData || root.folderData.showFolderName
                                        onToggled: function(c) {
                                            if (root.folderData) root.folderData.showFolderName = c;
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                SettingRow {
                                    title: "图标名称"
                                    Layout.preferredHeight: 32
                                    ToggleSwitch {
                                        id: showIconNamesToggle
                                        checked: !root.folderData || root.folderData.showIconNames
                                        onToggled: function(c) {
                                            if (root.folderData) root.folderData.showIconNames = c;
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                SettingRow {
                                    title: "图标外边缘"
                                    Layout.preferredHeight: 32
                                    ToggleSwitch {
                                        id: autoFillToggle
                                        checked: root.folderData && root.folderData.showIconBorder
                                        onToggled: function(c) {
                                            if (root.folderData) root.folderData.showIconBorder = c;
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                InfoCallout {
                                    calloutText: "**图标色调**  ·  灰度模式统一图标色调并保留明暗层次。\n\n**图标外边缘**  ·  为所有图标添加统一圆角边缘，并将图标缩进显示在边缘内部。"
                                }
                            }
                        }

                        SectionCard {
                            sectionTitle: "窗口行为"
                            fields: ColumnLayout {
                                spacing: 4

                                SettingRow {
                                    title: "允许空位"
                                    Layout.preferredHeight: 32
                                    ToggleSwitch {
                                        id: allowGapsToggle
                                        checked: !root.folderData || root.folderData.allowIconGaps
                                        onToggled: function(c) {
                                            if (root.folderData) root.folderData.allowIconGaps = c;
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                InfoCallout {
                                    calloutText: "**说明**  ·  关闭后图标会自动从左到右、从上到下补齐。"
                                }

                                SettingRow {
                                    title: "溢出收纳"
                                    Layout.preferredHeight: 32
                                    Layout.topMargin: 6
                                    ToggleSwitch {
                                        id: overflowModeToggle
                                        checked: root.folderData && root.folderData.overflowMode
                                        onToggled: function(c) {
                                            if (root.folderData) root.folderData.overflowMode = c;
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                SettingRow {
                                    title: "展开方向"
                                    Layout.preferredHeight: 36
                                    ComboBox {
                                        Layout.preferredWidth: 170
                                        enabled: root.folderData && root.folderData.overflowMode
                                        model: ["向下", "向上", "向右", "向左"]
                                        currentIndex: root.folderData
                                                      ? Math.max(0, root.expansionDirectionValues
                                                                 .indexOf(root.folderData.expansionDirection)) : 0
                                        onActivated: function(index) {
                                            if (root.folderData)
                                                root.folderData.expansionDirection
                                                        = root.expansionDirectionValues[index];
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                InfoCallout {
                                    calloutText: "**说明**  ·  自动使用布局的最后一个格子收纳多余图标；展开后点击空白处即可收起。"
                                }

                                SettingRow {
                                    title: "锁定位置"
                                    Layout.preferredHeight: 32
                                    Layout.topMargin: 6
                                    ToggleSwitch {
                                        id: lockToggle
                                        checked: root.folderData && root.folderData.lockPosition
                                        onToggled: function(c) {
                                            if (root.folderData) root.folderData.lockPosition = c;
                                            root.persist();
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
