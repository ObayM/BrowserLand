import QtQuick
import BrowserLand

Rectangle {
    id: popover

    required property Item anchorItem
    property bool open: false
    property bool alignRight: false
    property bool closeOnOutsideClick: false
    property bool attached: false

    parent: anchorItem.Window.contentItem
    opacity: open ? 1 : 0
    visible: opacity > 0
    enabled: open
    z: 90
    radius: Theme.radius
    topLeftRadius: attached ? 0 : radius
    topRightRadius: attached ? 0 : radius
    color: Theme.overlay
    border.width: attached ? 0 : 1
    border.color: Theme.border

    transform: Translate {
        y: popover.open || popover.attached ? 0 : -6

        Behavior on y { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    }

    Behavior on opacity {
        enabled: !popover.attached
        NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic }
    }

    function place() {
        if (!parent)
            return
        const below = anchorItem.mapToItem(parent, 0, anchorItem.height + (attached ? 0 : 4))
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
        acceptedButtons: Qt.AllButtons
    }
}
