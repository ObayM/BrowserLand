import QtQuick
import BrowserLand


Text {
    property date now: new Date()

    text: Qt.formatTime(now, Config.clock.format)
    color: Config.appearance.accent
    font.pixelSize: Config.appearance.font_size

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: parent.now = new Date()
    }
}