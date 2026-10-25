import QtQuick
import BrowserLand


Rectangle {
    id: banner

    readonly property var errors: Browser.errors
    readonly property int maxShown: 5
    property bool dismissed: false

    visible: errors.length > 0 && !dismissed
    height: visible ? column.implicitHeight + 16: 0
    color: "#b22f28"

    Connections {
        target: Config
        function onReloaded(){
            banner.dismissed = false
        }
    }
    

    Column {
        id: column
        anchors { left: parent.left; right: closeButton.left; top: parent.top; margins: 8 }
        spacing: 2

        Text {
            text: banner.errors.length === 1 ? "BrowserLand: 1 error"
                                            : "BrowserLand: " + banner.errors.length + " errors"
            color: "white"
            font.bold: true
        }

        Repeater {
            model: Math.min(banner.errors.length, banner.maxShown)
            
            delegate: Text {
                required property int index
                width: column.width
                text: banner.errors[index]
                color: "white"
                font.family: "monospace"
                elide: Text.ElideRight
            }
        }

        Text {
            visible: banner.errors.length > banner.maxShown
            text: "...and " + (banner.errors.length - banner.maxShown) + " more"
            color: "white"
        }

        Text {
            text: "Fix the config and save then run browserland --check-config  to check your config :)"
            color: "#ffd8d4"
            font.pixelSize: 11
        }
    }

    Text {
        id: closeButton
        anchors { right: parent.right; top: parent.top; margins: 8 }
        text: "×"
        color: "white"
        font.pixelSize: 18

        MouseArea {
            anchors { fill: parent; margins: -6 }
            onClicked: banner.dismissed = true
        }
    }
}