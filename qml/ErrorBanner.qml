import QtQuick
import BrowserLand


Rectangle {
    id: banner

    readonly property int maxShown: 5

    visible: Config.errors.length > 0
    height: visible ? column.implicitHeight + 16: 0
    color: "#b22f28"

    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
        spacing: 2

        Text {
            text: Config.errors.length === 1 ? "BrowserLand: 1 config error"
                                             : "BrowserLand: " + Config.errors.length + " config errors"
            color: "white"
            font.bold: true
        }

        Repeater {
            model: Math.min(Config.errors.length, banner.maxShown)
            Text {
                required property int index
                width: column.width
                text: Config.errors[index]
                color: "white"
                font.family: "monospace"
                elide: Text.ElideRight
            }
        }

        Text {
            visible: Config.errors.length > banner.maxShown
            text: "...and " + (Config.errors.length - banner.maxShown) + " more"
            color: "white"
        }

        Text {
            text: "Run  browserland --check-config  to see everything :)"
            color: "#ffd8d4"
            font.pixelSize: 11
        }
    }
}