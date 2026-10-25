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

        UiText {
            text: banner.errors.length === 1 ? "BrowserLand: 1 error"
                                            : "BrowserLand: " + banner.errors.length + " errors"
            color: "white"
            font.bold: true
        }

        Repeater {
            model: Math.min(banner.errors.length, banner.maxShown)
            
            delegate: UiText {
                required property int index
                width: column.width
                text: banner.errors[index]
                color: "white"
                font.family: "monospace"
                elide: Text.ElideRight
            }
        }

        UiText {
            visible: banner.errors.length > banner.maxShown
            text: "...and " + (banner.errors.length - banner.maxShown) + " more"
            color: "white"
        }

        UiText {
            text: "Fix the config and save then run browserland --check-config  to check your config :)"
            color: "#ffd8d4"
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    Icon {
        id: closeButton
        anchors { right: parent.right; top: parent.top; margins: 8 }
        name: "x"
        color: "white"

        MouseArea {
            anchors { fill: parent; margins: -6 }
            onClicked: banner.dismissed = true
        }
    }
}