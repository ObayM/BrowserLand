import QtQuick
import QtQuick.Layouts
import BrowserLand

Rectangle {
    id: prompt

    readonly property var request: Browser.permissionRequests.find(r => r.view === Browser.current) || null

    visible: !!request
    implicitWidth: row.implicitWidth + 24
    implicitHeight: row.implicitHeight + 16
    radius: 8
    color: Qt.lighter(Config.appearance.background, 1.35)
    border.width: 1
    border.color: Config.appearance.accent

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            Layout.rightMargin: 6
            text: prompt.request ? prompt.request.site + " wants to " + prompt.request.what : ""
            color: Config.appearance.foreground
            font.pixelSize: Config.appearance.font_size
        }

        TextButton {
            text: "Allow"
            primary: true
            onClicked: Browser.answerPermission(prompt.request, true)
        }

        TextButton {
            text: "Deny"
            onClicked: Browser.answerPermission(prompt.request, false)
        }
    }
}
