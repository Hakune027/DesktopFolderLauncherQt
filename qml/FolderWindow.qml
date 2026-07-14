import QtQuick
import QtQuick.Window

Window {
    id: root

    // 当前文件夹数据对象
    property var folderData

    property string folderName: folderData ? folderData.name : "开发工具"
    property bool nativeDropRegistered: false

    width: 350

    height: 250

    // 初始隐藏, 等恢复位置后再显示, 避免闪烁 & 位置竞态
    visible: false

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    color: "transparent"

    function clampToAvailableScreen() {
        if (!root.screen)
            return;
        let area = root.screen.availableGeometry;
        root.x = Math.max(area.x, Math.min(root.x,
                                           area.x + Math.max(0, area.width - root.width)));
        root.y = Math.max(area.y, Math.min(root.y,
                                           area.y + Math.max(0, area.height - root.height)));
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
                model: folderData ? folderData.items : null

                delegate: AppIcon {
                    item: model.item

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

        width: parent.width

        height: 40

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
    }
}
