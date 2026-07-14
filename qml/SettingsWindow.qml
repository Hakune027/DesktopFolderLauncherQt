import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    objectName: "settingsWindow"
    transientParent: null
    width: 820
    height: 620
    minimumWidth: 720
    minimumHeight: 520
    visible: false
    flags: Qt.Window | Qt.FramelessWindowHint
    title: ""
    color: Qt.rgba(0.055, 0.06, 0.075, 0.62)
    palette.window: "#17181d"
    palette.windowText: "#f5f5f5"
    palette.base: "#23252b"
    palette.text: "#f5f5f5"
    palette.button: "#2c2e35"
    palette.buttonText: "#f5f5f5"
    palette.highlight: "#7b83ff"
    palette.highlightedText: "white"
    property int settingsPage: 0
    property var folderSettingsHost
    property var defaultSettingsHost
    property int pendingDeleteIndex: -1
    property string pendingDeleteName: ""
    property string persistenceErrorText: ""

    Connections {
        target: folderManager
        function onPersistenceError(message) {
            root.persistenceErrorText = message;
            persistenceErrorTimer.restart();
        }
    }

    Timer {
        id: persistenceErrorTimer
        interval: 5000
        onTriggered: root.persistenceErrorText = ""
    }

    // Pastel colors for folder icons — deterministic from name
    property var folderColors: [
        { bg: "#fff4ce", fg: "#8a6500" },
        { bg: "#e8f0fe", fg: "#3c5ca0" },
        { bg: "#fce8e6", fg: "#a1423a" },
        { bg: "#e6f4ea", fg: "#2d6a3f" },
        { bg: "#f3e8fd", fg: "#6b3fa0" },
        { bg: "#fde8d8", fg: "#a0522d" },
        { bg: "#d8f0f8", fg: "#2a6b7a" },
        { bg: "#fde8f0", fg: "#9b3a6b" }
    ]

    function colorForName(name) {
        if (!name) return folderColors[0];
        let h = 0;
        for (let i = 0; i < name.length; i++) h = ((h << 5) - h) + name.charCodeAt(i);
        return folderColors[Math.abs(h) % folderColors.length];
    }

    function applyGlass() {
        if (typeof windowEffects !== "undefined") {
            windowEffects.applyFrostedGlass(root, root.visible, false);
        }
    }

    onVisibleChanged: Qt.callLater(root.applyGlass)

    function syncVisibility() {
        if (folderManager.folderCount() === 0) {
            root.show();
            root.raise();
            root.requestActivate();
        } else {
            root.hide();
        }
    }

    Component.onCompleted: {
        Qt.callLater(root.syncVisibility);
        Qt.callLater(root.applyGlass);
    }

    // ═══════════════════════════════════════════
    // Custom Toggle Switch (shared pattern)
    // ═══════════════════════════════════════════
    component ToggleSwitch: Item {
        id: toggle
        property bool checked: false
        signal toggled(bool checked)
        implicitWidth: 38; implicitHeight: 22

        Rectangle {
            width: 38; height: 22; radius: 11
            color: toggle.checked ? "#7b83ff" : "#3affffff"
            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Rectangle {
                width: 18; height: 18; radius: 9
                x: toggle.checked ? 18 : 2
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
    // New Folder Dialog
    // ═══════════════════════════════════════════
    Dialog {
        id: newFolderDialog
        title: "新建文件夹"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        width: Math.min(420, root.width - 48)

        contentItem: ColumnLayout {
            width: newFolderDialog.availableWidth
            spacing: 12
            Label {
                text: "为桌面文件夹输入一个名称"
                color: "#b7b8c0"
                Layout.fillWidth: true
            }
            TextField {
                id: folderNameInput
                Layout.fillWidth: true
                Layout.preferredWidth: newFolderDialog.availableWidth
                Layout.maximumWidth: newFolderDialog.availableWidth
                placeholderText: "文件夹名称"
                selectByMouse: true
                onAccepted: newFolderDialog.accept()
            }
        }

        onOpened: {
            folderNameInput.forceActiveFocus();
            folderNameInput.selectAll();
        }
        onAccepted: {
            let name = folderNameInput.text.trim();
            if (name !== "")
                folderManager.createFolder(name);
            folderNameInput.clear();
        }
        onRejected: folderNameInput.clear()
    }

    function openDefaultFolderSettings() {
        if (!root.defaultSettingsHost)
            return;
        root.defaultSettingsHost.openForFolderWindow(root);
    }

    Dialog {
        id: deleteFolderDialog
        title: "删除文件夹"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: Math.min(420, root.width - 48)

        contentItem: Label {
            width: deleteFolderDialog.availableWidth
            text: "确定删除“" + root.pendingDeleteName + "”吗？此操作不会删除原始文件。"
            color: "#e7e7ea"
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            if (root.pendingDeleteIndex >= 0)
                folderManager.removeFolder(root.pendingDeleteIndex);
            root.pendingDeleteIndex = -1;
            root.pendingDeleteName = "";
        }
        onRejected: {
            root.pendingDeleteIndex = -1;
            root.pendingDeleteName = "";
        }
    }

    Rectangle {
        id: titleBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 42
        color: "transparent"
        z: 100

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            property point clickPos: Qt.point(0, 0)
            onPressed: function(mouse) { clickPos = Qt.point(mouse.x, mouse.y); }
            onPositionChanged: function(mouse) {
                root.x += mouse.x - clickPos.x;
                root.y += mouse.y - clickPos.y;
            }
            onDoubleClicked: root.visibility === Window.Maximized
                             ? root.showNormal() : root.showMaximized()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 8
            spacing: 10

            Rectangle {
                width: 32; height: 32; radius: 8
                color: "#32ffffff"
                FluentIcon { anchors.centerIn: parent; name: "app"; width: 23; height: 23 }
            }

            Label {
                Layout.fillWidth: true
                text: "DesktopFolderLauncher · 总设置"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: "#f0f0f5"
                elide: Text.ElideRight
            }

            Rectangle {
                width: 28; height: 28; radius: 6
                color: mainCloseHover.hovered ? "#25ff6b6b" : "transparent"
                Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                HoverHandler { id: mainCloseHover }
                FluentIcon { anchors.centerIn: parent; name: "close"; width: 15; height: 15; opacity: mainCloseHover.hovered ? 1 : 0.72 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 42
        height: 1
        color: "#14ffffff"
    }

    Rectangle {
        x: 16
        y: 57
        width: 142
        height: root.height - y - 16
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            Label {
                text: "设置"
                color: "#7e7f88"
                font.pixelSize: 12
                Layout.leftMargin: 12
                Layout.bottomMargin: 8
            }

            Repeater {
                model: [
                    { icon: "folder", label: "文件夹", page: 0 },
                    { icon: "settings", label: "新建默认值", page: 2 },
                    { icon: "info", label: "应用与关于", page: 1 }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: root.settingsPage === modelData.page
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 8
                    color: active ? "#1a7b83ff" : (totalNavHover.hovered ? "#0affffff" : "transparent")

                    Rectangle {
                        visible: parent.active
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; height: 20; radius: 2
                        color: "#7b83ff"
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        spacing: 10
                        FluentIcon { name: modelData.icon; width: 18; height: 18; opacity: parent.parent.active ? 1 : 0.7 }
                        Label {
                            text: modelData.label
                            color: parent.parent.active ? "#f0f0f5" : "#a0a1ac"
                            font.pixelSize: 13
                            font.weight: parent.parent.active ? Font.DemiBold : Font.Normal
                        }
                    }
                    HoverHandler { id: totalNavHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.settingsPage = modelData.page;
                            if (modelData.page === 2)
                                root.openDefaultFolderSettings();
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    // ═══════════════════════════════════════════
    // Main Layout
    // ═══════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 174
        anchors.rightMargin: 16
        anchors.topMargin: 57
        anchors.bottomMargin: 16
        spacing: 12

        // ── Header ───────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 13

            Rectangle {
                width: 38; height: 38; radius: 9
                color: "#1a7b83ff"
                FluentIcon { anchors.centerIn: parent; name: "app"; width: 26; height: 26 }
            }

            ColumnLayout {
                spacing: 1
                Label {
                    text: root.settingsPage === 0 ? "桌面文件夹"
                          : root.settingsPage === 2 ? "新建默认值" : "应用设置"
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                    color: "#f5f5f5"
                }
                Label {
                    text: root.settingsPage === 0
                          ? "管理文件夹并进入每个文件夹的独立设置"
                          : root.settingsPage === 2
                            ? "这些参数只应用于之后创建的文件夹"
                            : "启动选项、版本信息与应用说明"
                    color: "#7e7f88"
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                id: aboutNavButton
                text: root.settingsPage === 0 ? "关于" : "返回文件夹"
                flat: true
                font.pixelSize: 13
                visible: false
                onClicked: root.settingsPage = root.settingsPage === 0 ? 1 : 0
                contentItem: Row {
                    spacing: 7
                    FluentIcon { name: root.settingsPage === 0 ? "info" : "folder"; width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: aboutNavButton.text; color: aboutNavButton.hovered ? "#f5f5f5" : "#b7b8c0"; anchors.verticalCenter: parent.verticalCenter }
                }
                background: Rectangle {
                    radius: 8
                    color: aboutNavButton.hovered ? "#14ffffff" : "transparent"
                }
            }

            Button {
                id: newFolderBtn
                text: "新建文件夹"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                visible: root.settingsPage === 0
                onClicked: newFolderDialog.open()

                contentItem: Row {
                    spacing: 7
                    FluentIcon { name: "add"; width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: newFolderBtn.text; font: newFolderBtn.font; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                }

                background: Rectangle {
                    radius: 8
                    color: newFolderBtn.hovered ? "#8a91ff" : "#7b83ff"
                    Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }
            }
        }

        // ── Divider ──────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#18ffffff"
        }

        // ── Section label ────────────────────
        RowLayout {
            visible: root.settingsPage === 0
            spacing: 8
            Label {
                text: "文件夹列表"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: "#a0a1ac"
            }
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#0cffffff"
            }
            Label {
                text: folderManager.folderCount() + " 个文件夹"
                font.pixelSize: 12
                color: "#7e7f88"
            }
        }

        // ── Folder List ──────────────────────
        ListView {
            id: folderList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.settingsPage === 0
            spacing: 8
            clip: true
            model: folderManager
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4; radius: 2
                    color: "#30ffffff"
                }
            }

            // Smooth add/remove
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 240; easing.type: Easing.OutBack }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
            }
            displaced: Transition {
                NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
            }

            delegate: Rectangle {
                id: card
                width: folderList.width - (folderList.ScrollBar.vertical.visible ? 12 : 0)
                height: 84
                radius: 12
                color: cardHover.hovered ? "#0effffff" : "#0affffff"
                border.width: 1
                border.color: cardHover.hovered ? "#22ffffff" : "#12ffffff"

                Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 160 } }

                HoverHandler { id: cardHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 12

                    // Folder icon with deterministic color
                    Rectangle {
                        width: 40; height: 40; radius: 9
                        property var clr: root.colorForName(model.folderData.name)
                        color: clr.bg
                        FluentIcon { anchors.centerIn: parent; name: "folder"; width: 24; height: 24 }
                    }

                    // Info column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
                            text: model.folderData.name
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            color: "#f0f0f5"
                            elide: Text.ElideRight
                        }
                        Label {
                            text: model.folderData.itemCount + " 个项目"
                            color: "#7e7f88"
                            font.pixelSize: 12
                        }
                    }

                    // Lock toggle
                    RowLayout {
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter
                        Label {
                            text: "锁定"
                            color: "#a0a1ac"
                            font.pixelSize: 12
                        }
                        ToggleSwitch {
                            id: lockSwitch
                            checked: model.folderData.lockPosition
                            onToggled: function(c) {
                                model.folderData.lockPosition = c;
                                folderManager.save();
                            }
                        }
                    }

                    // Action buttons
                    Button {
                        id: settingsBtn
                        text: "设置"
                        font.pixelSize: 12
                        Layout.preferredWidth: 64

                        contentItem: Row {
                            spacing: 5
                            FluentIcon { name: "settings"; width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: settingsBtn.text; font: settingsBtn.font; color: "#d8dcff"; anchors.verticalCenter: parent.verticalCenter }
                        }

                        background: Rectangle {
                            radius: 6
                            color: settingsBtn.hovered ? "#227b83ff" : "#147b83ff"
                            Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }

                        onClicked: {
                            if (!root.folderSettingsHost)
                                return;
                            root.folderSettingsHost.folderData = model.folderData;
                            root.folderSettingsHost.openForFolderWindow(root);
                        }
                    }

                    Button {
                        id: deleteBtn
                        text: "删除"
                        font.pixelSize: 12
                        Layout.preferredWidth: 56

                        contentItem: Row {
                            spacing: 4
                            FluentIcon { name: "delete"; width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: deleteBtn.text; font: deleteBtn.font; color: deleteBtn.hovered ? "#ffb0b5" : "#b0a0a5"; anchors.verticalCenter: parent.verticalCenter }
                        }

                        background: Rectangle {
                            radius: 6
                            color: deleteBtn.hovered ? "#20ff6b6b" : "transparent"
                            Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }

                        onClicked: {
                            root.pendingDeleteIndex = index;
                            root.pendingDeleteName = model.folderData.name;
                            deleteFolderDialog.open();
                        }
                    }
                }
            }

            // ── Empty State ──────────────────
            Rectangle {
                anchors.centerIn: parent
                width: folderList.width
                visible: folderManager.folderCount() === 0
                color: "transparent"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 64; height: 64; radius: 16
                        color: "#18ffffff"
                        Label {
                            anchors.centerIn: parent
                            text: ""
                            color: "#50ffffff"
                            font.pixelSize: 32
                        }
                        FluentIcon { anchors.centerIn: parent; name: "folder"; width: 44; height: 44; opacity: 0.7 }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "还没有文件夹"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        color: "#a0a1ac"
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "点击右上角「+ 新建文件夹」创建第一个桌面文件夹"
                        color: "#7e7f88"
                        font.pixelSize: 13
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.settingsPage === 1
            radius: 12
            color: "#0affffff"
            border.width: 1
            border.color: "#14ffffff"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                ColumnLayout {
                    spacing: 3
                    Label {
                        text: "关于"
                        color: "#f5f5f5"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: "DesktopFolderLauncher  " + appController.appVersion
                        color: "#8f909a"
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82
                    radius: 11
                    color: "#0cffffff"
                    border.color: "#12ffffff"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 14
                        FluentIcon { name: "startup"; Layout.preferredWidth: 25; Layout.preferredHeight: 25 }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Label { text: "开机自动启动"; color: "#ededf2"; font.pixelSize: 14; font.weight: Font.DemiBold }
                            Label { text: "登录 Windows 后自动运行桌面文件夹"; color: "#8f909a"; font.pixelSize: 12 }
                        }
                        ToggleSwitch {
                            checked: typeof appController !== "undefined" && appController.autoStartEnabled
                            onToggled: function(c) {
                                if (typeof appController !== "undefined")
                                    appController.autoStartEnabled = c;
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 116
                    radius: 11
                    color: "#0cffffff"
                    border.color: "#12ffffff"
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 7
                        RowLayout {
                            spacing: 8
                            FluentIcon {
                                name: "info"
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                            }
                            Label {
                                text: "应用信息"
                                color: "#ededf2"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }
                        Label { text: "基于 Qt 6 构建的 Windows 桌面文件夹启动器"; color: "#a0a1aa"; font.pixelSize: 12 }
                        Label { text: "配置与文件夹布局均保存在当前用户目录中。"; color: "#7e7f88"; font.pixelSize: 12 }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        z: 1000
        visible: root.persistenceErrorText !== ""
        width: Math.min(errorLabel.implicitWidth + 32, root.width - 48)
        height: errorLabel.implicitHeight + 20
        radius: 8
        color: "#e63b2024"
        border.color: "#ff7b83"

        Label {
            id: errorLabel
            anchors.centerIn: parent
            width: parent.width - 32
            text: root.persistenceErrorText
            color: "white"
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.settingsPage === 2
            radius: 12
            color: "#0affffff"
            border.width: 1
            border.color: "#14ffffff"

            ColumnLayout {
                visible: false
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Label {
                    text: "初始网格"
                    color: "#e7e7ea"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Label { text: "文件夹容量"; color: "#c5c5cc"; Layout.preferredWidth: 150 }
                    SpinBox {
                        from: 1; to: 12; editable: true
                        value: folderManager.defaultGridColumns
                        onValueModified: folderManager.defaultGridColumns = value
                    }
                    Label { text: "×"; color: "#8f909a"; font.pixelSize: 18 }
                    SpinBox {
                        from: 1; to: 12; editable: true
                        value: folderManager.defaultGridRows
                        onValueModified: folderManager.defaultGridRows = value
                    }
                    Item { Layout.fillWidth: true }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#12ffffff" }
                Label {
                    text: "图标与留白"
                    color: "#e7e7ea"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "图标大小"; color: "#c5c5cc"; Layout.preferredWidth: 150 }
                    Slider {
                        id: defaultIconSizeSlider
                        Layout.fillWidth: true
                        from: 32; to: 96; stepSize: 4
                        value: folderManager.defaultIconSize
                        onPressedChanged: if (!pressed) folderManager.defaultIconSize = Math.round(value)
                    }
                    Label { text: Math.round(defaultIconSizeSlider.value) + " px"; color: "#b7b8c0"; Layout.preferredWidth: 54 }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "图标间距"; color: "#c5c5cc"; Layout.preferredWidth: 150 }
                    Slider {
                        id: defaultSpacingSlider
                        Layout.fillWidth: true
                        from: 24; to: 80; stepSize: 4
                        value: folderManager.defaultIconSpacing
                        onPressedChanged: if (!pressed) folderManager.defaultIconSpacing = Math.round(value)
                    }
                    Label { text: Math.round(defaultSpacingSlider.value) + " px"; color: "#b7b8c0"; Layout.preferredWidth: 54 }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "边缘间距"; color: "#c5c5cc"; Layout.preferredWidth: 150 }
                    Slider {
                        id: defaultEdgeSlider
                        Layout.fillWidth: true
                        from: 0; to: 80; stepSize: 4
                        value: folderManager.defaultEdgePadding
                        onPressedChanged: if (!pressed) folderManager.defaultEdgePadding = Math.round(value)
                    }
                    Label { text: Math.round(defaultEdgeSlider.value) + " px"; color: "#b7b8c0"; Layout.preferredWidth: 54 }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#12ffffff" }
                Label {
                    text: "初始行为与材质"
                    color: "#e7e7ea"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "溢出收纳"; color: "#c5c5cc"; Layout.preferredWidth: 150 }
                    ToggleSwitch {
                        checked: folderManager.defaultOverflowMode
                        onToggled: function(c) { folderManager.defaultOverflowMode = c }
                    }
                    Item { Layout.fillWidth: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "磨砂玻璃"; color: "#c5c5cc"; Layout.preferredWidth: 150 }
                    ToggleSwitch {
                        checked: folderManager.defaultFrostedGlass
                        onToggled: function(c) { folderManager.defaultFrostedGlass = c }
                    }
                    Item { Layout.fillWidth: true }
                }

                Label {
                    Layout.fillWidth: true
                    text: "修改默认值不会覆盖已有文件夹的独立设置。"
                    color: "#7e7f88"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
                Item { Layout.fillHeight: true }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(420, parent.width - 48)
                spacing: 14
                FluentIcon {
                    name: "settings"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "完整默认文件夹设置"
                    color: "#f0f0f5"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                Label {
                    Layout.fillWidth: true
                    text: "默认设置与独立文件夹设置使用同一套页面，包含外观、网格、图标、封面和交互行为。"
                    color: "#8f909a"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "打开完整设置"
                    onClicked: root.openDefaultFolderSettings()
                }
            }
        }
    }
}
