import QtQuick
import BrowserLand

Rectangle {
    id: strip

    readonly property real tabWidth: Math.max(90, Math.min(220,
        (width - newTabButton.width - extraWidgets.width - 24) / Math.max(1, Browser.tabs.length)))

    implicitHeight: 38
    color: Qt.darker(Config.appearance.background, 1.25)

    Row {
        id: row
        anchors { left: parent.left; leftMargin: 6; top: parent.top; topMargin: 5; bottom: parent.bottom }
        spacing: 2

        Repeater {
            model: Browser.tabs

            delegate: Rectangle {
                id: tab

                required property var modelData
                required property int index
                readonly property bool active: index === Browser.currentIndex

                width: strip.tabWidth
                height: row.height
                radius: 6
                color: active ? Config.appearance.background
                              : mouse.containsMouse ? Qt.lighter(strip.color, 1.4) : "transparent"

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            Browser.closeTab(tab.index)
                        else
                            Browser.selectTab(tab.index)
                    }
                }

                Image {
                    id: favicon
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 16
                    height: 16
                    sourceSize: Qt.size(16, 16)
                    source: tab.modelData.icon
                    visible: status === Image.Ready
                }

                Text {
                    anchors {
                        left: favicon.visible ? favicon.right : parent.left
                        leftMargin: favicon.visible ? 8 : 10
                        right: closeButton.left
                        rightMargin: 4
                        verticalCenter: parent.verticalCenter
                    }
                    text: tab.modelData.title || tab.modelData.pendingTitle || tab.modelData.url.toString() || tab.modelData.pendingUrl
                    color: Config.appearance.foreground
                    opacity: tab.active ? 1 : 0.65
                    elide: Text.ElideRight
                    font.pixelSize: Config.appearance.font_size
                }

                IconButton {
                    id: closeButton
                    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    implicitWidth: 22
                    implicitHeight: 22
                    text: "×"
                    onClicked: Browser.closeTab(tab.index)
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
                    height: 2
                    radius: 1
                    color: Config.appearance.accent
                    visible: tab.active
                }
            }
        }

        IconButton {
            id: newTabButton
            anchors.verticalCenter: parent.verticalCenter
            text: "+"
            onClicked: Browser.run("new-tab")
        }
    }

    WidgetSlot {
        id: extraWidgets
        name: "tabbar-right"
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
    }
}