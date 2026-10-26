import QtQuick
import QtQuick.Layouts
import BrowserLand

IconButton {
    id: button

    function shortcut(action) {
        const bind = Array.from(Config.binds).find(bind => bind.action === action && !bind.args)
        return bind ? bind.sequence : ""
    }

    icon: "ellipsis-vertical"
    tip: "Menu"
    onClicked: menu.open = !menu.open

    Popover {
        id: menu
        anchorItem: button
        alignRight: true
        closeOnOutsideClick: true
        width: 280
        height: column.implicitHeight + 12

        Column {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }

            Repeater {
                model: [
                    { text: "New tab", action: "new-tab" },
                    { text: "Reopen closed tab", action: "reopen-closed-tab" },
                    { separator: true },
                    { text: "Find", action: "find" },
                    { zoom: true },
                    { separator: true },
                    { text: "Clear history", action: "clear-history" },
                    { text: "Developer tools", action: "devtools" },
                    { text: "Reload config", action: "reload-config" },
                    { separator: true },
                    { text: "Quit", action: "quit" },

                    { text: Browser.verticalTabs ? "Horizontal tabs" : "Vertical tabs", action: "toggle-tabs" }
                ]

                delegate: Item {
                    id: entry

                    required property var modelData

                    width: column.width
                    height: modelData.separator ? 9 : 32

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
                        height: 1
                        color: Theme.border
                        visible: !!entry.modelData.separator
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusSmall
                        color: rowMouse.containsMouse ? Theme.hover : "transparent"
                        visible: !!entry.modelData.action

                        UiText {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            text: entry.modelData.text || ""
                        }

                        UiText {
                            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            text: entry.modelData.action ? button.shortcut(entry.modelData.action) : ""
                            color: Theme.muted
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                menu.open = false
                                Browser.run(entry.modelData.action)
                            }
                        }
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 4 }
                        visible: !!entry.modelData.zoom
                        spacing: 2

                        UiText {
                            Layout.fillWidth: true
                            text: "Zoom"
                        }
                        IconButton {
                            implicitWidth: 28
                            implicitHeight: 28
                            iconSize: 16
                            icon: "minus"
                            enabled: !!Browser.current
                            onClicked: Browser.run("zoom-out")
                        }
                        
                        UiText {
                            Layout.preferredWidth: 48
                            horizontalAlignment: Text.AlignHCenter
                            text: Browser.current ? Math.round(Browser.current.zoomFactor * 100) + "%" : ""
                        }

                        IconButton {
                            implicitWidth: 28
                            implicitHeight: 28
                            iconSize: 16
                            icon: "plus"
                            enabled: !!Browser.current
                            onClicked: Browser.run("zoom-in")
                        }
                    }
                }
            }
        }
    }
}
