import QtQuick
import BrowserLand

Rectangle {
    id: bar

    readonly property bool overflowing: row.implicitWidth > width - 12
    readonly property real room: width - 12 - (overflowing ? more.width + 4 : 0)

    function open(url, background) {
        if (background)
            Browser.newTab(url, true)
        else
            Browser.navigate(url)
    }

    function barItem() {
        return { text: Browser.bookmarksBar ? "Hide bookmarks bar" : "Always show bookmarks bar", run: () => Browser.run("toggle-bookmarks-bar") }
    }

    implicitHeight: 34
    color: Theme.background

    TapHandler {
        acceptedButtons: Qt.RightButton
        gesturePolicy: TapHandler.WithinBounds
        onTapped: point => Browser.menuRequested([[bar.barItem()]], parent, point.position.x, point.position.y)
    }

    UiText {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        visible: Bookmarks.items.length === 0
        text: "Click the star in the address bar to bookmark a page"
        color: Theme.muted
        font.pixelSize: Theme.fontSizeSmall
    }

    Row {
        id: row
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 2

        Repeater {
            id: repeater
            model: Bookmarks.items

            delegate: Rectangle {
                id: chip

                required property int index
                required property var modelData
                readonly property bool fits: x + width <= bar.room
                property bool tipShown: false

                width: 40 + label.width
                height: 26
                radius: Theme.radiusSmall
                opacity: fits ? 1 : 0
                enabled: fits
                color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.duration / 2 } }

                Image {
                    id: favicon
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    width: 16
                    height: 16
                    sourceSize: Qt.size(16, 16)
                    source: chip.modelData.icon
                }

                Icon {
                    anchors.centerIn: favicon
                    visible: favicon.status !== Image.Ready
                    name: "globe"
                    size: 14
                    color: Theme.muted
                }

                UiText {
                    id: label
                    anchors { left: favicon.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
                    width: Math.min(implicitWidth, 160)
                    text: chip.modelData.title || Browser.hostOf(chip.modelData.url) || chip.modelData.url
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onPressed: chip.tipShown = false
                    onContainsMouseChanged: if (!containsMouse) chip.tipShown = false
                    onClicked: event => bar.open(chip.modelData.url, event.button === Qt.MiddleButton || (event.modifiers & Qt.ControlModifier))
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    gesturePolicy: TapHandler.WithinBounds
                    onTapped: point => {
                        const url = chip.modelData.url
                        Browser.menuRequested([
                            [
                                { text: "Open", run: () => bar.open(url, false) },
                                { text: "Open in new tab", run: () => bar.open(url, true) }
                            ],
                            [
                                { text: "Move left", enabled: chip.index > 0, run: () => Bookmarks.move(chip.index, chip.index - 1) },
                                { text: "Move right", enabled: chip.index < Bookmarks.items.length - 1, run: () => Bookmarks.move(chip.index, chip.index + 1) }
                            ],
                            [
                                { text: "Edit", run: () => editor.edit(chip, url, false) },
                                { text: "Delete", run: () => Bookmarks.remove(url) }
                            ],
                            [bar.barItem()]
                        ], parent, point.position.x, point.position.y)
                    }
                }

                Timer {
                    interval: 600
                    running: mouse.containsMouse && !mouse.pressed && !chip.tipShown
                    onTriggered: chip.tipShown = true
                }

                Tooltip {
                    target: chip
                    text: chip.modelData.url
                    show: chip.tipShown
                }
            }
        }
    }

    IconButton {
        id: more
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        implicitWidth: 26
        implicitHeight: 26
        iconSize: 14
        icon: "chevrons-right"
        tip: "More bookmarks"
        visible: bar.overflowing
        onClicked: Browser.menuRequested([
            Bookmarks.items
                .filter((item, index) => repeater.itemAt(index) && !repeater.itemAt(index).fits)
                .map(item => ({ text: item.title || Browser.hostOf(item.url) || item.url, run: () => bar.open(item.url, false) }))
        ], more, 0, more.height + 4)
    }

    BookmarkEditor {
        id: editor
        anchorItem: bar
    }
}
