import QtQuick
import BrowserLand


Rectangle {
    color: Theme.background

    Column {
        anchors.centerIn: parent
        spacing: 18

        UiText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "BrowserLand"
            font.pixelSize: 32
        }

        Rectangle {
            width: 520
            height: 44

            radius: Theme.radius > 0 ? height / 2 : 0
            color: Theme.field

            TextInput {
                anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                verticalAlignment: TextInput.AlignVCenter

                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 2

                onAccepted: {
                    Browser.navigate(text)
                    text = ""
                }
            }
        }
    }
}