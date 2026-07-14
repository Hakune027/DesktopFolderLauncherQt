import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    property var folderData

    width: 420
    height: 650
    minimumWidth: 380
    minimumHeight: 500
    visible: false
    title: folderData ? folderData.name + " - 文件夹设置" : "文件夹设置"

    function persist() {
        if (typeof folderManager !== "undefined")
            folderManager.save();
    }

    function openForFolderWindow() {
        let folderWindow = root.transientParent;
        let targetScreen = folderWindow && folderWindow.screen
                           ? folderWindow.screen : root.screen;
        let desiredX = folderWindow
                       ? folderWindow.x + Math.round((folderWindow.width - root.width) / 2)
                       : root.x;
        let desiredY = folderWindow
                       ? folderWindow.y + Math.round((folderWindow.height - root.height) / 2)
                       : root.y;

        if (targetScreen) {
            let area = targetScreen.availableGeometry;
            let areaX = area ? area.x : (targetScreen.virtualX || 0);
            let areaY = area ? area.y : (targetScreen.virtualY || 0);
            let areaWidth = area ? area.width
                                 : (targetScreen.desktopAvailableWidth || targetScreen.width || root.width);
            let areaHeight = area ? area.height
                                  : (targetScreen.desktopAvailableHeight || targetScreen.height || root.height);
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
    }

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"

        Flickable {
            id: settingsFlickable
            anchors.fill: parent
            contentWidth: width
            contentHeight: settingsColumn.implicitHeight + 48
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            ColumnLayout {
                id: settingsColumn
                x: 24
                y: 24
                width: settingsFlickable.width - 48
                spacing: 18

            Label {
                text: root.folderData ? root.folderData.name : ""
                font.pixelSize: 22
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: "圆角"; Layout.preferredWidth: 110 }
                Slider {
                    id: radiusSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 60
                    stepSize: 1
                    value: root.folderData ? root.folderData.cornerRadius : 30
                    onMoved: if (root.folderData) root.folderData.cornerRadius = value
                    onPressedChanged: if (!pressed) root.persist()
                }
                Label {
                    text: Math.round(radiusSlider.value) + " px"
                    Layout.preferredWidth: 52
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: "背景样式"; Layout.preferredWidth: 110 }
                RadioButton {
                    text: "黑色透明"
                    checked: !root.folderData || root.folderData.backgroundStyle === "black"
                    onClicked: {
                        if (root.folderData) root.folderData.backgroundStyle = "black";
                        root.persist();
                    }
                }
                RadioButton {
                    text: "白色透明"
                    checked: root.folderData && root.folderData.backgroundStyle === "white"
                    onClicked: {
                        if (root.folderData) root.folderData.backgroundStyle = "white";
                        root.persist();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: "不透明度"; Layout.preferredWidth: 110 }
                Slider {
                    id: opacitySlider
                    Layout.fillWidth: true
                    from: 0.1
                    to: 1.0
                    stepSize: 0.05
                    value: root.folderData ? root.folderData.backgroundOpacity : 0.8
                    onMoved: if (root.folderData) root.folderData.backgroundOpacity = value
                    onPressedChanged: if (!pressed) root.persist()
                }
                Label {
                    text: Math.round(opacitySlider.value * 100) + "%"
                    Layout.preferredWidth: 44
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: "图标大小"; Layout.preferredWidth: 110 }
                Slider {
                    id: iconSizeSlider
                    Layout.fillWidth: true
                    from: 32
                    to: 96
                    stepSize: 4
                    value: root.folderData ? root.folderData.iconSize : 64
                    onMoved: if (root.folderData) root.folderData.iconSize = value
                    onPressedChanged: if (!pressed) root.persist()
                }
                Label {
                    text: Math.round(iconSizeSlider.value) + " px"
                    Layout.preferredWidth: 52
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: "图标间间距"; Layout.preferredWidth: 110 }
                Slider {
                    id: iconSpacingSlider
                    Layout.fillWidth: true
                    from: 24
                    to: 80
                    stepSize: 4
                    value: root.folderData ? root.folderData.iconSpacing : 36
                    onMoved: if (root.folderData) root.folderData.iconSpacing = value
                    onPressedChanged: if (!pressed) root.persist()
                }
                Label {
                    text: Math.round(iconSpacingSlider.value) + " px"
                    Layout.preferredWidth: 52
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: "图标距边缘"; Layout.preferredWidth: 110 }
                Slider {
                    id: edgePaddingSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 80
                    stepSize: 4
                    value: root.folderData ? root.folderData.edgePadding : 20
                    onMoved: if (root.folderData) root.folderData.edgePadding = value
                    onPressedChanged: if (!pressed) root.persist()
                }
                Label {
                    text: Math.round(edgePaddingSlider.value) + " px"
                    Layout.preferredWidth: 52
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: "文件夹尺寸"; Layout.preferredWidth: 110 }
                SpinBox {
                    id: columnsSpinBox
                    from: 1
                    to: 12
                    editable: true
                    value: root.folderData ? root.folderData.gridColumns : 3
                    onValueModified: {
                        if (root.folderData) {
                            root.folderData.gridColumns = value;
                            value = root.folderData.gridColumns;
                            rowsSpinBox.value = root.folderData.gridRows;
                        }
                        root.persist();
                    }
                }
                Label { text: "×"; font.pixelSize: 18 }
                SpinBox {
                    id: rowsSpinBox
                    from: 1
                    to: 12
                    editable: true
                    value: root.folderData ? root.folderData.gridRows : 2
                    onValueModified: {
                        if (root.folderData) {
                            root.folderData.gridRows = value;
                            value = root.folderData.gridRows;
                        }
                        root.persist();
                    }
                }
                Label { text: "个图标"; Layout.fillWidth: true }
            }

            CheckBox {
                text: "显示文件夹名称"
                checked: !root.folderData || root.folderData.showFolderName
                onClicked: {
                    if (root.folderData) root.folderData.showFolderName = checked;
                    root.persist();
                }
            }

            CheckBox {
                text: "显示图标名称"
                checked: !root.folderData || root.folderData.showIconNames
                onClicked: {
                    if (root.folderData) root.folderData.showIconNames = checked;
                    root.persist();
                }
            }

            CheckBox {
                text: "显示图标背景阴影"
                checked: !root.folderData || root.folderData.showIconShadow
                onClicked: {
                    if (root.folderData) root.folderData.showIconShadow = checked;
                    root.persist();
                }
            }

            CheckBox {
                text: "允许图标前有空位"
                checked: !root.folderData || root.folderData.allowIconGaps
                onClicked: {
                    if (root.folderData) root.folderData.allowIconGaps = checked;
                    root.persist();
                }
                ToolTip.visible: hovered
                ToolTip.text: "关闭后图标会从左到右、从上到下自动补齐"
            }

            CheckBox {
                text: "锁定文件夹位置"
                checked: root.folderData && root.folderData.lockPosition
                onClicked: {
                    if (root.folderData) root.folderData.lockPosition = checked;
                    root.persist();
                }
            }

                Item { Layout.preferredHeight: 1 }
            }
        }
    }
}
