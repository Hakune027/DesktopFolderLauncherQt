import QtQuick

Image {
    property string name: "folder"
    source: Qt.resolvedUrl("../assets/icons/" + name + ".svg")
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    asynchronous: false
    cache: true
}
