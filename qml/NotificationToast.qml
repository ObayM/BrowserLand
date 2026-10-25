import QtQuick
import BrowserLand

Rectangle {
    id: toast

    property var notification: null

    visible: !!notification
    width: 320
    height: column.implicitHeight + 20
    radius: 8
    color: Qt.lighter(Config.appearance.background, 1.35)
    border.width: 1
    border.color: Config.appearance.accent

    Connections {
        target: Browser
        function onNotificationPresented(notification) {
            toast.notification = notification
            notification.show()
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 6000
        onTriggered: toast.notification = null
    }

    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        spacing: 3

        Text {
            width: parent.width
            text: toast.notification ? toast.notification.title : ""
            color: Config.appearance.foreground
            font.bold: true
            font.pixelSize: Config.appearance.font_size
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: toast.notification ? toast.notification.message : ""
            color: Config.appearance.foreground
            font.pixelSize: Config.appearance.font_size
            wrapMode: Text.Wrap
            maximumLineCount: 4
        }
        Text {
            width: parent.width
            text: toast.notification ? Browser.hostOf(toast.notification.origin) : ""
            color: Config.appearance.foreground
            opacity: 0.5
            font.pixelSize: Config.appearance.font_size - 2
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (toast.notification)
                toast.notification.click()
            toast.notification = null
        }
    }
}
