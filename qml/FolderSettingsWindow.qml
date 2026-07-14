import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    property var folderData
    property var borderStyleValues: ["none", "subtle", "solid", "accent", "double"]

    width: 640
    height: 600
    minimumWidth: 560
    minimumHeight: 500
    visible: false
    flags: Qt.Window
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

    function applyGlass() {
        if (typeof windowEffects !== "undefined") {
            windowEffects.applyFrostedGlass(root, root.visible, false);
        }
    }
    function persist() {
        if (typeof folderManager !== "undefined")
            folderManager.save();
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

    component SettingRow: RowLayout {
        property alias title: rowLabel.text
        spacing: 16
        Layout.fillWidth: true
        Label {
            id: rowLabel
            Layout.preferredWidth: 132
            color: "#e7e7ea"
            font.pixelSize: 14
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 28
        anchors.bottomMargin: 28
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle {
                width: 44; height: 44; radius: 11
                color: "#32ffffff"
                Label { anchors.centerIn: parent; text: "▰"; color: "#d8dcff"; font.pixelSize: 22 }
            }
            ColumnLayout {
                spacing: 1
                Label {
                    Layout.fillWidth: true
                    text: root.folderData ? root.folderData.name : "文件夹设置"
                    font.family: "Segoe UI Variable Display"
                    font.pixelSize: 25
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Label { text: "独立调整这个桌面文件夹"; color: "#b7b8c0"; font.pixelSize: 13 }
            }
            Item { Layout.fillWidth: true }
        }

        TabBar {
            id: tabs
            Layout.fillWidth: true
            TabButton { text: "外观" }
            TabButton { text: "布局" }
            TabButton { text: "行为" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            ScrollView {
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width
                    spacing: 12
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: appearanceColumn.implicitHeight + 40
                        radius: 14; color: "#5030343d"; border.color: "#28ffffff"
                        ColumnLayout {
                            id: appearanceColumn
                            anchors.fill: parent; anchors.margins: 20; spacing: 14
                            Label { text: "窗口材质"; font.pixelSize: 16; font.weight: Font.DemiBold }
                            CheckBox {
                                text: "启用系统磨砂玻璃和圆角"
                                checked: root.folderData && root.folderData.frostedGlass
                                onClicked: { if (root.folderData) root.folderData.frostedGlass = checked; root.persist(); }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 34
                                Layout.preferredHeight: glassHint.implicitHeight + 18
                                radius: 7
                                color: "#183b82f6"
                                border.width: 1
                                border.color: "#426aa9ff"
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    radius: 2
                                    color: "#77a7ff"
                                }
                                Text {
                                    id: glassHint
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 13
                                    anchors.rightMargin: 10
                                    text: "**提示**  ·  磨砂模式使用 Windows 系统圆角，并自动隐藏醒目的窗口边框。"
                                    textFormat: Text.MarkdownText
                                    color: "#c9d9f6"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }
                            }
                            SettingRow {
                                title: "背景色"
                                RadioButton {
                                    text: "深色"
                                    checked: !root.folderData || root.folderData.backgroundStyle === "black"
                                    onClicked: { if (root.folderData) root.folderData.backgroundStyle = "black"; root.persist(); }
                                }
                                RadioButton {
                                    text: "浅色"
                                    checked: root.folderData && root.folderData.backgroundStyle === "white"
                                    onClicked: { if (root.folderData) root.folderData.backgroundStyle = "white"; root.persist(); }
                                }
                            }
                            SettingRow {
                                title: root.folderData && root.folderData.frostedGlass ? "颜色浓度" : "不透明度"
                                Slider {
                                    id: opacitySlider; Layout.fillWidth: true
                                    from: 0.1; to: 1.0; stepSize: 0.05
                                    value: root.folderData ? root.folderData.backgroundOpacity : 0.8
                                    onMoved: if (root.folderData) root.folderData.backgroundOpacity = value
                                    onPressedChanged: if (!pressed) root.persist()
                                }
                                Label { text: Math.round(opacitySlider.value * 100) + "%"; Layout.preferredWidth: 42 }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: shapeColumn.implicitHeight + 40
                        radius: 14; color: "#5030343d"; border.color: "#28ffffff"
                        ColumnLayout {
                            id: shapeColumn
                            anchors.fill: parent; anchors.margins: 20; spacing: 14
                            Label { text: "形状与边框"; font.pixelSize: 16; font.weight: Font.DemiBold }
                            SettingRow {
                                title: "圆角"
                                Slider {
                                    id: radiusSlider; Layout.fillWidth: true
                                    from: 0; to: 60; stepSize: 1
                                    value: root.folderData ? root.folderData.cornerRadius : 30
                                    enabled: !root.folderData || !root.folderData.frostedGlass
                                    onMoved: if (root.folderData) root.folderData.cornerRadius = value
                                    onPressedChanged: if (!pressed) root.persist()
                                }
                                Label { text: Math.round(radiusSlider.value) + " px"; opacity: radiusSlider.enabled ? 1 : 0.4; Layout.preferredWidth: 50 }
                            }
                            SettingRow {
                                title: "边框样式"
                                ComboBox {
                                    Layout.fillWidth: true
                                    enabled: !root.folderData || !root.folderData.frostedGlass
                                    model: ["无边框", "轻描边", "实线", "强调色", "双层边框"]
                                    currentIndex: root.folderData ? Math.max(0, root.borderStyleValues.indexOf(root.folderData.borderStyle)) : 1
                                    onActivated: function(index) { if (root.folderData) root.folderData.borderStyle = root.borderStyleValues[index]; root.persist(); }
                                }
                            }
                        }
                    }
                }
            }

            ScrollView {
                clip: true
                contentWidth: availableWidth
                Rectangle {
                    width: parent.width
                    height: layoutColumn.implicitHeight + 40
                    radius: 14; color: "#5030343d"; border.color: "#28ffffff"
                    ColumnLayout {
                        id: layoutColumn
                        anchors.fill: parent; anchors.margins: 20; spacing: 17
                        Label { text: "图标网格"; font.pixelSize: 16; font.weight: Font.DemiBold }
                        SettingRow {
                            title: "图标大小"
                            Slider { id: iconSizeSlider; Layout.fillWidth: true; from: 32; to: 96; stepSize: 4; value: root.folderData ? root.folderData.iconSize : 64; onMoved: if (root.folderData) root.folderData.iconSize = value; onPressedChanged: if (!pressed) root.persist() }
                            Label { text: Math.round(iconSizeSlider.value) + " px"; Layout.preferredWidth: 50 }
                        }
                        SettingRow {
                            title: "图标间距"
                            Slider { id: spacingSlider; Layout.fillWidth: true; from: 24; to: 80; stepSize: 4; value: root.folderData ? root.folderData.iconSpacing : 36; onMoved: if (root.folderData) root.folderData.iconSpacing = value; onPressedChanged: if (!pressed) root.persist() }
                            Label { text: Math.round(spacingSlider.value) + " px"; Layout.preferredWidth: 50 }
                        }
                        SettingRow {
                            title: "边缘间距"
                            Slider { id: edgeSlider; Layout.fillWidth: true; from: 0; to: 80; stepSize: 4; value: root.folderData ? root.folderData.edgePadding : 20; onMoved: if (root.folderData) root.folderData.edgePadding = value; onPressedChanged: if (!pressed) root.persist() }
                            Label { text: Math.round(edgeSlider.value) + " px"; Layout.preferredWidth: 50 }
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: "#24ffffff" }
                        SettingRow {
                            title: "文件夹容量"
                            SpinBox { id: columnsSpin; from: 1; to: 12; editable: true; value: root.folderData ? root.folderData.gridColumns : 3; onValueModified: { if (root.folderData) root.folderData.gridColumns = value; root.persist(); } }
                            Label { text: "×"; font.pixelSize: 18 }
                            SpinBox { from: 1; to: 12; editable: true; value: root.folderData ? root.folderData.gridRows : 2; onValueModified: { if (root.folderData) root.folderData.gridRows = value; root.persist(); } }
                            Label { text: "图标"; color: "#b7b8c0" }
                        }
                        Label { text: "窗口会根据图标大小、间距和网格容量自动调整。"; color: "#b7b8c0"; font.pixelSize: 12; Layout.leftMargin: 148 }
                    }
                }
            }

            ScrollView {
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width
                    spacing: 12
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: displayColumn.implicitHeight + 40
                        radius: 14; color: "#5030343d"; border.color: "#28ffffff"
                        ColumnLayout {
                            id: displayColumn
                            anchors.fill: parent; anchors.margins: 20; spacing: 8
                            Label { text: "显示内容"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.bottomMargin: 4 }
                            CheckBox { text: "显示文件夹名称"; checked: !root.folderData || root.folderData.showFolderName; onClicked: { if (root.folderData) root.folderData.showFolderName = checked; root.persist(); } }
                            CheckBox { text: "显示图标名称"; checked: !root.folderData || root.folderData.showIconNames; onClicked: { if (root.folderData) root.folderData.showIconNames = checked; root.persist(); } }
                            CheckBox { text: "显示图标背景阴影"; checked: !root.folderData || root.folderData.showIconShadow; onClicked: { if (root.folderData) root.folderData.showIconShadow = checked; root.persist(); } }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: behaviorColumn.implicitHeight + 40
                        radius: 14; color: "#5030343d"; border.color: "#28ffffff"
                        ColumnLayout {
                            id: behaviorColumn
                            anchors.fill: parent; anchors.margins: 20; spacing: 8
                            Label { text: "窗口行为"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.bottomMargin: 4 }
                            CheckBox { text: "允许图标前有空位"; checked: !root.folderData || root.folderData.allowIconGaps; onClicked: { if (root.folderData) root.folderData.allowIconGaps = checked; root.persist(); } ToolTip.visible: hovered; ToolTip.text: "关闭后会自动从左到右、从上到下补齐" }
                            CheckBox { text: "锁定文件夹位置"; checked: root.folderData && root.folderData.lockPosition; onClicked: { if (root.folderData) root.folderData.lockPosition = checked; root.persist(); } }
                        }
                    }
                }
            }
        }
    }

}
