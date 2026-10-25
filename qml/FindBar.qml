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

    opacity: target ? 1 : 0
    visible: opacity > 0
    width: 340
    height: 40
    radius: Theme.radius
    color: Theme.overlay
    border.width: 1
    border.color: Theme.border

    transform: Translate {
        y: findBar.target ? 0 : -6

        Behavior on y { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    }

    Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

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
            color: Theme.foreground
            selectionColor: Theme.accent
            selectedTextColor: Theme.background
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize

            onTextEdited: Browser.find(text)
            Keys.onReturnPressed: event => Browser.find(text, event.modifiers & Qt.ShiftModifier)
            Keys.onEnterPressed: event => Browser.find(text, event.modifiers & Qt.ShiftModifier)
            Keys.onEscapePressed: findBar.close()

            UiText {
                anchors.fill: parent
                visible: input.text === ""
                text: "Find in page"
                color: Theme.muted
            }
        }

        UiText {
            visible: input.text !== ""
            text: Browser.findResult.activeMatch + "/" + Browser.findResult.numberOfMatches
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 1
        }

        IconButton {
            implicitWidth: 30
            implicitHeight: 30
            
            iconSize: 16
            icon: "chevron-up"
            tip: "Previous"
            onClicked: Browser.find(input.text, true)
        }
        
        IconButton {
            implicitWidth: 30
            implicitHeight: 30
            iconSize: 16
            icon: "chevron-down"
            tip: "Next"
            onClicked: Browser.find(input.text, false)
        }
        IconButton {
            implicitWidth: 30
            implicitHeight: 30
            iconSize: 16
            icon: "x"
            onClicked: findBar.close()
        }
    }
}
