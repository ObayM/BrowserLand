import QtQuick
import BrowserLand

Rectangle {
    id: bar

    readonly property string pageUrl: Browser.current ? Browser.current.url.toString() : ""
    property var suggestions: []
    property int selected: -1
    property bool typing: false

    function go(text) {
        typing = false
        Browser.navigate(text)
        if (Browser.current)
            Browser.current.forceActiveFocus()
    }

    implicitHeight: 32
    radius: Theme.radius
    color: Theme.raised
    border.width: 2
    border.color: input.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0)

    Behavior on border.color { ColorAnimation { duration: Theme.duration } }

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        selectByMouse: true
        
        color: Theme.foreground
        selectionColor: Theme.accent
        selectedTextColor: Theme.background
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize

        onTextEdited: {
            bar.typing = true
            bar.selected = -1
            bar.suggestions = text.trim() !== "" ? History.search(text, 6) : []
        }
        onAccepted: bar.go(bar.selected >= 0 ? bar.suggestions[bar.selected].url : text)

        Keys.onDownPressed: bar.selected = Math.min(bar.selected + 1, bar.suggestions.length - 1)
        Keys.onUpPressed: bar.selected = Math.max(bar.selected - 1, -1)
        Keys.onEscapePressed: {
            if (dropdown.open) {
                bar.typing = false
                return
            }
            text = bar.pageUrl
            if (Browser.current)
                Browser.current.forceActiveFocus()
        }
        onActiveFocusChanged: {
            if (activeFocus) {
                Qt.callLater(input.selectAll)
            } else {
                bar.typing = false
                text = bar.pageUrl
            }
        }
        Component.onCompleted: text = bar.pageUrl
    }

    UiText {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: "Search or type an address"
        color: Theme.muted
    }

    Rectangle {
        id: progressLine

        readonly property bool loading: !!Browser.current && Browser.current.loading
        property real progress: loading ? Browser.current.loadProgress / 100 : 1

        anchors { left: parent.left; leftMargin: bar.radius / 2 + 2; bottom: parent.bottom; bottomMargin: 1 }
        width: (bar.width - anchors.leftMargin * 2) * progress
        height: 2
        radius: 1
        color: Theme.accent
        opacity: loading ? 1 : 0
        visible: opacity > 0

        Behavior on progress {
            enabled: progressLine.opacity > 0.99
            NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.duration * 2 } }
    }

    Popover {
        id: dropdown
        anchorItem: bar
        open: bar.typing && input.activeFocus && bar.suggestions.length > 0
        width: bar.width
        height: list.implicitHeight + 8

        Column {
            id: list
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }

            Repeater {
                model: bar.suggestions

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    width: list.width
                    height: 32
                    radius: Theme.radiusSmall
                    color: index === bar.selected || mouse.containsMouse ? Theme.hover : "transparent"

                    UiText {
                        id: title
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        width: Math.min(implicitWidth, parent.width * 0.55)
                        text: row.modelData.title || row.modelData.url
                        elide: Text.ElideRight
                    }

                    UiText {
                        anchors { left: title.right; leftMargin: 10; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        text: row.modelData.url
                        color: Theme.accent
                        opacity: 0.8
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSize - 1
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: bar.go(row.modelData.url)
                    }
                }
            }
        }
    }

    onPageUrlChanged: if (!input.activeFocus) input.text = pageUrl

    Connections {
        target: Browser
        function onFocusUrlRequested() {
            input.forceActiveFocus()
            input.selectAll()
        }
    }
}
