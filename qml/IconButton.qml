import QtQuick
import BrowserLand

Rectangle {
    id: button

    property alias text: label.text
    property alias icon: glyph.name
    property real iconSize: 18
    property alias iconColor: glyph.color
    property alias iconFill: glyph.fill
    property string tip
    property bool tipShown: false
    signal clicked()

    implicitWidth: 34
    implicitHeight: 34
    radius: Theme.radius > 0 ? Math.min(width, height) / 2 : 0
    opacity: enabled ? 1 : 0.35
    color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.duration / 2 } }
    Behavior on opacity { NumberAnimation { duration: Theme.duration } }

    Icon {
        id: glyph
        anchors.centerIn: parent
        size: button.iconSize
        visible: name !== ""
    }

    UiText {
        id: label
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSize + 3
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
        onPressed: button.tipShown = false
        onContainsMouseChanged: if (!containsMouse) button.tipShown = false
    }

    Timer {
        interval: 600
        running: mouse.containsMouse && !mouse.pressed && !button.tipShown && button.tip !== ""
        onTriggered: button.tipShown = true
    }

    Tooltip {
        target: button
        text: button.tip
        show: button.tipShown
    }
}