import QtQuick
import BrowserLand

Rectangle {
    id: button

    property alias text: label.text
    signal clicked()

    implicitWidth: 30
    implicitHeight: 30
    radius: 6
    opacity: enabled ? 1 : 0.35
    color: mouse.containsMouse ? Qt.lighter(Config.appearance.background, 1.7) : "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        color: Config.appearance.foreground
        font.pixelSize: Config.appearance.font_size + 3
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}