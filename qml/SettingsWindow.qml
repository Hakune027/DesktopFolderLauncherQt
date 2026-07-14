import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    objectName: "settingsWindow"
    transientParent: null
    width: 740
    height: 640
    minimumWidth: 620
    minimumHeight: 480
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

        ColumnLayout {
            width: 320
            spacing: 10
            Label {
                text: "为桌面文件夹输入一个名称"
                color: "#b7b8c0"
                Layout.fillWidth: true
            }
            TextField {
                id: folderNameInput
                Layout.fillWidth: true
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

    // ═══════════════════════════════════════════
    // Main Layout
    // ═══════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 56
        anchors.bottomMargin: 24
        spacing: 15

        // ── Header ───────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 13

            Rectangle {
                width: 42; height: 42; radius: 10
                color: "#e7e9ff"
                FluentIcon { anchors.centerIn: parent; name: "app"; width: 32; height: 32 }
            }

            ColumnLayout {
                spacing: 1
                Label {
                    text: "桌面文件夹"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    color: "#f5f5f5"
                }
                Label {
                    text: "管理文件夹、外观与窗口行为"
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

                scale: cardHover.hovered ? 1.01 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 160 } }

                HoverHandler { id: cardHover }

                FolderSettingsWindow {
                    id: perFolderSettings
                    folderData: model.folderData
                    transientParent: root
                }

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

                        onClicked: perFolderSettings.openForFolderWindow()
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

                        onClicked: folderManager.removeFolder(index)
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
            radius: 14
            color: "#0affffff"
            border.width: 1
            border.color: "#14ffffff"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 18

                ColumnLayout {
                    spacing: 3
                    Label {
                        text: "关于"
                        color: "#f5f5f5"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: "DesktopFolderLauncher  1.0"
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
}
