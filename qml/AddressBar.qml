import QtQuick
import BrowserLand

Rectangle {
    id: bar

    readonly property string pageUrl: Browser.current ? Browser.current.url.toString() : ""

    implicitHeight: 30
    radius: 8
    color: Qt.lighter(Config.appearance.background, 1.35)
    border.width: input.activeFocus ? 2 : 0
    border.color: Config.appearance.accent

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        selectByMouse: true
        color: Config.appearance.foreground
        selectionColor: Config.appearance.accent
        selectedTextColor: Config.appearance.background
        font.pixelSize: Config.appearance.font_size

        onAccepted: {
            Browser.navigate(text)
            if (Browser.current)
                Browser.current.forceActiveFocus()
        }
        Keys.onEscapePressed: {
            text = bar.pageUrl
            if (Browser.current)
                Browser.current.forceActiveFocus()
        }
        onActiveFocusChanged: {
            if (activeFocus)
                Qt.callLater(input.selectAll)
            else
                text = bar.pageUrl
        }
        Component.onCompleted: text = bar.pageUrl
    }

    Text {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: "Search or type an address"
        color: Config.appearance.foreground
        opacity: 0.4
        font.pixelSize: Config.appearance.font_size
    }

    Rectangle {
        anchors { left: parent.left; leftMargin: 4; bottom: parent.bottom }
        height: 2
        radius: 1
        width: Browser.current && Browser.current.loading ? (bar.width - 8) * Browser.current.loadProgress / 100 : 0
        visible: width > 0
        color: Config.appearance.accent
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