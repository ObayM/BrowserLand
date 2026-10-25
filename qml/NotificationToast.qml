import QtQuick
import BrowserLand

Rectangle {
    id: toast

    property var notification: null
    property bool open: false

    opacity: open ? 1 : 0
    visible: opacity > 0
    width: 320
    height: column.implicitHeight + 20
    radius: Theme.radius
    color: Theme.overlay
    border.width: 1
    border.color: Theme.border

    transform: Translate {
        x: toast.open ? 0 : 24

        Behavior on x {
            NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } 
        }
    }

    Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

    Connections {
        target: Browser
        function onNotificationPresented(notification) {
            toast.notification = notification
            toast.open = true
            notification.show()
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 6000
        onTriggered: toast.open = false
    }

    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        spacing: 3

        UiText {
            width: parent.width
            text: toast.notification ? toast.notification.title : ""
            font.bold: true
            elide: Text.ElideRight
        }

        UiText {
            width: parent.width
            text: toast.notification ? toast.notification.message : ""
            wrapMode: Text.Wrap
            maximumLineCount: 4
        }
        
        UiText {
            width: parent.width
            text: toast.notification ? Browser.hostOf(toast.notification.origin) : ""
            color: Theme.muted
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (toast.open && toast.notification)
                toast.notification.click()
            toast.open = false
        }
    }
}
