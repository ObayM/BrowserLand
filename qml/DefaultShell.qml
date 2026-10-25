import QtQuick
import QtQuick.Layouts
import BrowserLand

// This is the built-in UI, if you want to make your own, copy this file to shell.qml in your config folder
// it replaces this one and reloads every time you save it :)

Rectangle {
    color: Config.appearance.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabStrip {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            Layout.leftMargin: 6
            Layout.rightMargin: 10
            spacing: 4

            WidgetSlot { name: "toolbar-left" }

            IconButton {
                text: "←"
                enabled: !!Browser.current && Browser.current.canGoBack
                onClicked: Browser.run("back")
            }
            IconButton {
                text: "→"
                enabled: !!Browser.current && Browser.current.canGoForward
                onClicked: Browser.run("forward")
            }
            IconButton {
                readonly property bool loading: !!Browser.current && Browser.current.loading
                text: loading ? "×" : "↻"
                onClicked: Browser.run(loading ? "stop" : "reload")
            }

            AddressBar {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 8
            }

            DownloadsButton {}

            WidgetSlot { name: "toolbar-right" }
        }

        WebArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            visible: statusbar.count > 0
            color: Qt.darker(Config.appearance.background, 1.25)

            WidgetSlot {
                id: statusbar
                name: "statusbar"
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            }
        }
    }
}