import QtQuick
import QtQuick.Window

Window {
    id: root

    // 当前文件夹数据对象
    property var folderData

    property string folderName: folderData ? folderData.name : "开发工具"

    width: 350

    height: 250

    // 初始隐藏, 等恢复位置后再显示, 避免闪烁 & 位置竞态
    visible: false

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    color: "transparent"

    // ====== 外部文件拖放接收层(最底层, Qt 内部 OLE 翻译) ======
    DropArea {
        id: fileDropArea

        anchors.fill: parent

        keys: ["text/uri-list"]

        onEntered: function (drag) {
            drag.accept();
        }

        onDropped: function (drop) {
            if (!root.folderData)
                return;

            for (let i = 0; i < drop.urls.length; i++) {
                root.folderData.addFile(drop.urls[i]);
            }
        }
    }

    // ====== 文件夹主体 ======
    Rectangle {
        id: folder

        anchors.fill: parent

        radius: 30

        color: "#CC202020"

        border.width: 1

        border.color: "#40ffffff"

        // ---- 标题 ----
        Text {
            x: 25
            y: 20

            text: root.folderName

            color: "white"

            font.pixelSize: 26
        }

        // ---- 图标区(可拖放排序) ----
        Item {
            anchors.fill: parent

            anchors.margins: 20

            anchors.topMargin: 70

            Repeater {
                model: folderData ? folderData.items : []

                delegate: AppIcon {
                    item: modelData

                    itemIndex: index

                    // 单击 / 右键菜单 → 打开文件
                    onOpenRequest: {
                        if (modelData) {
                            modelData.open();
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
                        let items = folderData.items;

                        let draggedItem = items[index];

                        if (draggedItem.x === x && draggedItem.y === y) {
                            return;
                        }

                        // 检查目标位置是否被占用
                        let targetIndex = -1;

                        for (let i = 0; i < items.length; i++) {
                            if (i === index)
                                continue;

                            let other = items[i];

                            if (other.x === x && other.y === y) {
                                targetIndex = i;
                                break;
                            }
                        }

                        if (targetIndex >= 0) {
                            // 交换位置
                            let targetItem = items[targetIndex];

                            let oldX = draggedItem.x;
                            let oldY = draggedItem.y;

                            draggedItem.x = targetItem.x;
                            draggedItem.y = targetItem.y;

                            targetItem.x = oldX;
                            targetItem.y = oldY;
                        } else {
                            // 移到空位
                            draggedItem.x = x;
                            draggedItem.y = y;
                        }

                        // 保存当前文件夹
                        folderData.save();
                    }
                }
            }
        }
    }

    // ====== 窗口拖动条(顶部) ======
    MouseArea {
        id: dragArea

        width: parent.width

        height: 40

        property real startX

        property real startY

        onPressed: function (mouse) {
            startX = mouse.x;
            startY = mouse.y;

            console.log(
                "[FolderWindow] 开始拖动:",
                root.folderName,
                "window=(" + root.x + "," + root.y + ")"
            );
        }

        onPositionChanged: function (mouse) {
            if (mouse.buttons & Qt.LeftButton) {
                root.x += mouse.x - startX;
                root.y += mouse.y - startY;

                // 实时同步位置到内存(不写盘, 关闭时才持久化)
                if (root.folderData) {
                    root.folderData.setWindowPosition(root.x, root.y);
                }
            }
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
    }
}
