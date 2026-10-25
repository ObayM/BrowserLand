import QtQuick
import BrowserLand

Rectangle {
    id: tooltip

    required property Item target
    property alias text: label.text
    property bool show: false

    function place() {
        if (!parent)
            return
        
        const below = target.mapToItem(parent, target.width / 2, target.height + 6)
        x = Math.max(4, Math.min(below.x - width / 2, parent.width - width - 4))
        y = below.y
    }

    parent: target.Window.contentItem

    z: 99
    opacity: show ? 1 : 0
    visible: opacity > 0
    width: label.implicitWidth + 16
    height: label.implicitHeight + 8
    radius: Theme.radiusSmall
    color: Theme.overlay

    border.width: 1
    border.color: Theme.border

    Behavior on opacity { 
        NumberAnimation { duration: Theme.duration } 
    }

    onShowChanged: if (show) place()

    UiText {
        id: label
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeSmall
    }
}
