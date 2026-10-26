import QtQuick
import QtQuick.Layouts
import BrowserLand

// This is the built-in UI, if you want to make your own, copy this file to shell.qml in your config folder
// it replaces this one and reloads every time you save it :)

Rectangle {
    color: Theme.background

    RowLayout {
        anchors.fill: parent
        spacing: 0

        TabSidebar {
            Layout.fillHeight: true
            visible: Browser.verticalTabs
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            TabStrip {
                Layout.fillWidth: true
                visible: !Browser.verticalTabs
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                spacing: 2

                WidgetSlot { name: "toolbar-left" }

                IconButton {
                    icon: "arrow-left"
                    tip: "Back"
                    enabled: !!Browser.current && Browser.current.canGoBack
                    onClicked: Browser.run("back")
                }
                IconButton {
                    icon: "arrow-right"
                    tip: "Forward"
                    enabled: !!Browser.current && Browser.current.canGoForward
                    onClicked: Browser.run("forward")
                }
                IconButton {
                    readonly property bool loading: !!Browser.current && Browser.current.loading
                    icon: loading ? "x" : "rotate-cw"
                    tip: loading ? "Stop" : "Reload"
                    onClicked: Browser.run(loading ? "stop" : "reload")
                }

                AddressBar {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                }

                DownloadsButton {}

                WidgetSlot { name: "toolbar-right" }

                AppMenu {}
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            WebArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                visible: statusbar.count > 0
                color: Theme.sunken

                WidgetSlot {
                    id: statusbar
                    name: "statusbar"
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}