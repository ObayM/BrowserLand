import QtQuick
import BrowserLand

Rectangle {
    id: button

    property alias text: label.text
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 20
    implicitHeight: 26
    radius: 6
    color: primary ? Config.appearance.accent
                   : Qt.lighter(Config.appearance.background, mouse.containsMouse ? 1.9 : 1.6)

    Text {
        id: label
        anchors.centerIn: parent
        color: button.primary ? Config.appearance.background : Config.appearance.foreground
        font.pixelSize: Config.appearance.font_size
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
