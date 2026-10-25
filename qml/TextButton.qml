import QtQuick
import BrowserLand

Rectangle {
    id: button

    property alias text: label.text
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: Theme.radiusSmall
    color: primary ? Theme.accent : Theme.hover

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.duration / 2 } }
    }

    UiText {
        id: label
        anchors.centerIn: parent
        color: button.primary ? Theme.background : Theme.foreground
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
