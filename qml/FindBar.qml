import QtQuick
import QtQuick.Layouts
import QtWebEngine
import BrowserLand

Rectangle {
    id: findBar

    property WebEngineView target: null

    function close() {
        if (target)
            target.findText("")
        target = null
        if (Browser.current)
            Browser.current.forceActiveFocus()
    }

    visible: !!target
    width: 340
    height: 38
    radius: 8
    color: Qt.lighter(Config.appearance.background, 1.35)
    border.width: 1
    border.color: Config.appearance.accent

    Connections {
        target: Browser
        function onFindRequested() {
            if (!Browser.current)
                return
            findBar.target = Browser.current
            input.forceActiveFocus()
            input.selectAll()
            if (input.text !== "")
                Browser.find(input.text)
        }
        function onCurrentChanged() {
            if (findBar.target && findBar.target !== Browser.current)
                findBar.close()
        }
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 4 }
        spacing: 2

        TextInput {
            id: input
            Layout.fillWidth: true
            clip: true
            selectByMouse: true
            color: Config.appearance.foreground
            selectionColor: Config.appearance.accent
            selectedTextColor: Config.appearance.background
            font.pixelSize: Config.appearance.font_size

            onTextEdited: Browser.find(text)
            Keys.onReturnPressed: event => Browser.find(text, event.modifiers & Qt.ShiftModifier)
            Keys.onEnterPressed: event => Browser.find(text, event.modifiers & Qt.ShiftModifier)
            Keys.onEscapePressed: findBar.close()

            Text {
                anchors.fill: parent
                visible: input.text === ""
                text: "Find in page"
                color: Config.appearance.foreground
                opacity: 0.4
                font.pixelSize: Config.appearance.font_size
            }
        }

        Text {
            visible: input.text !== ""
            text: Browser.findResult.activeMatch + "/" + Browser.findResult.numberOfMatches
            color: Config.appearance.foreground
            opacity: 0.6
            font.pixelSize: Config.appearance.font_size - 1
        }

        IconButton {
            text: "↑"
            onClicked: Browser.find(input.text, true)
        }
        IconButton {
            text: "↓"
            onClicked: Browser.find(input.text, false)
        }
        IconButton {
            text: "×"
            onClicked: findBar.close()
        }
    }
}
