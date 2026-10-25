import QtQuick
import BrowserLand

// lives on the window's content item so it can float over the web page
Rectangle {
    id: popover

    required property Item anchorItem
    property bool open: false
    property bool alignRight: false
    property bool closeOnOutsideClick: false

    parent: anchorItem.Window.contentItem
    visible: open
    z: 90
    radius: 8
    color: Qt.lighter(Config.appearance.background, 1.25)
    border.width: 1
    border.color: Qt.lighter(Config.appearance.background, 1.9)

    function place() {
        if (!parent)
            return
        const below = anchorItem.mapToItem(parent, 0, anchorItem.height + 4)
        x = alignRight ? below.x + anchorItem.width - width : below.x
        y = below.y
    }

    onOpenChanged: if (open) place()
    onWidthChanged: if (open) place()

    MouseArea {
        parent: popover.parent
        anchors.fill: parent
        z: popover.z - 1
        enabled: popover.open && popover.closeOnOutsideClick
        visible: enabled
        onPressed: popover.open = false
    }
}
