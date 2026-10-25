import QtQuick
import QtQuick.Layouts
import BrowserLand

Rectangle {
    id: prompt

    readonly property var request: Browser.permissionRequests.find(r => r.view === Browser.current) || null

    visible: !!request
    implicitWidth: row.implicitWidth + 24
    implicitHeight: row.implicitHeight + 16
    radius: Theme.radius
    color: Theme.overlay
    border.width: 1
    border.color: Theme.accent

    transform: Translate { id: slide }

    onVisibleChanged: if (visible) appear.restart()

    ParallelAnimation {
        id: appear
        NumberAnimation { target: prompt; property: "opacity"; from: 0; to: 1; duration: Theme.duration }
        NumberAnimation { target: slide; property: "y"; from: -8; to: 0; duration: Theme.duration; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        UiText {
            Layout.rightMargin: 6
            text: prompt.request ? prompt.request.site + " wants to " + prompt.request.what : ""
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
