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
    opacity: open ? 1 : 0
    visible: opacity > 0
    enabled: open
    z: 90
    radius: Theme.radius
    color: Theme.overlay
    border.width: 1
    border.color: Theme.border

    transform: Translate {
        y: popover.open ? 0 : -6

        Behavior on y { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    }

    Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

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
