import QtQuick
import BrowserLand

Rectangle {
    id: bar

    readonly property string pageUrl: Browser.current && !Browser.current.newTabPage ? Browser.current.url.toString() : ""
    readonly property var parts: split(pageUrl)
    property var suggestions: []
    property int selected: -1
    property bool typing: false

    function go(text) {
        typing = false
        Browser.navigate(text)
        if (Browser.current)
            Browser.current.forceActiveFocus()
    }

    function split(url) {
        if (url === "" || url === "about:blank")
            return { scheme: "", host: "", rest: "" }
        const match = url.match(/^(https?):\/\/(?:www\.)?([^\/?#]*)(.*)$/i)
        if (!match)
            return { scheme: "", host: url, rest: "" }
        let rest = match[3] === "/" ? "" : match[3]
        try {
            rest = decodeURI(rest).replace(/[\u0000-\u001f\u007f]/g, encodeURIComponent)
        } catch (error) {
        }
        return { scheme: match[1].toLowerCase(), host: match[2], rest }
    }

    implicitHeight: 34
    radius: Theme.radius > 0 ? height / 2 : 0
    bottomLeftRadius: dropdown.open ? 0 : radius
    bottomRightRadius: dropdown.open ? 0 : radius
    color: dropdown.open ? Theme.overlay
         : input.activeFocus ? Theme.raised
         : hover.hovered ? Qt.tint(Theme.field, Theme.hover) : Theme.field

    Behavior on color {
        enabled: !dropdown.open
        ColorAnimation { duration: Theme.duration / 2 }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.IBeamCursor
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        gesturePolicy: TapHandler.WithinBounds

        onTapped: point => Browser.menuRequested([
            [
                { text: "Cut", enabled: input.activeFocus && input.selectedText !== "", run: () => input.cut() },
                { text: "Copy", enabled: input.selectedText !== "", run: () => input.copy() },
                { text: "Paste", enabled: input.activeFocus && input.canPaste, run: () => input.paste() },
                { text: "Paste and go", enabled: input.canPaste, run: () => { input.selectAll(); input.paste(); bar.go(input.text.replace(/\s+/g, " ")) } }
            ],
            [
                { text: "Copy address", enabled: bar.pageUrl !== "",
                  run: () => { input.text = bar.pageUrl; input.selectAll(); input.copy(); input.deselect() } },
                { text: "Site info", enabled: bar.parts.scheme !== "", run: () => siteInfo.open = true }
            ]
        ], parent, point.position.x, point.position.y)
    }

    Rectangle {
        id: site
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        width: siteRow.implicitWidth + 12
        height: parent.height - 8
        radius: Theme.radius > 0 ? height / 2 : 0
        color: siteMouse.pressed ? Theme.pressed : siteMouse.containsMouse || siteInfo.open ? Theme.hover : "transparent"

        readonly property bool insecure: bar.parts.scheme === "http" && !input.activeFocus

        Behavior on color { ColorAnimation { duration: Theme.duration / 2 } }

        Row {
            id: siteRow
            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: input.activeFocus || bar.parts.scheme === "" ? "search"
                    : bar.parts.scheme === "https" ? "settings-2" : "triangle-alert"
                color: site.insecure ? Theme.muted : Theme.foreground
            }

            UiText {
                anchors.verticalCenter: parent.verticalCenter
                visible: site.insecure
                text: "Not secure!"
                color: Theme.muted
            }
        }

        MouseArea {
            id: siteMouse
            anchors.fill: parent
            enabled: bar.parts.scheme !== "" && !input.activeFocus
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: siteInfo.open = !siteInfo.open
        }
    }

    SiteInfo {
        id: siteInfo
        anchorItem: site
    }

    TextInput {
        id: input
        anchors { left: site.right; leftMargin: 4; right: parent.right; rightMargin: 14; top: parent.top; bottom: parent.bottom }
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        selectByMouse: true
        color: activeFocus ? Theme.foreground : "transparent"
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
                siteInfo.open = false
                Qt.callLater(input.selectAll)
            } else {
                bar.typing = false
                text = bar.pageUrl
            }
        }
        Component.onCompleted: text = bar.pageUrl
    }

    Row {
        anchors { left: input.left; right: input.right; verticalCenter: parent.verticalCenter }
        visible: !input.activeFocus && bar.parts.host !== ""
        clip: true

        UiText {
            id: host
            text: bar.parts.host
        }

        UiText {
            width: Math.max(0, parent.width - host.width)
            text: bar.parts.rest
            color: Theme.muted
            elide: Text.ElideRight
        }
    }

    UiText {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: "Search or type an address"
        color: Theme.muted
    }

    Popover {
        id: dropdown
        anchorItem: bar
        attached: true
        open: bar.typing && input.activeFocus && bar.suggestions.length > 0
        width: bar.width
        height: list.implicitHeight + 14
        radius: bar.radius

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 14; rightMargin: 14 }
            height: 1
            color: Theme.border
        }

        Column {
            id: list
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 6; leftMargin: 6; rightMargin: 6 }

            Repeater {
                model: bar.suggestions

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    width: list.width
                    height: 36
                    radius: Theme.radius
                    color: index === bar.selected || mouse.containsMouse ? Theme.hover : "transparent"

                    Icon {
                        id: rowIcon
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        name: "history"
                        color: Theme.muted
                    }

                    UiText {
                        id: title
                        anchors { left: rowIcon.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        width: Math.min(implicitWidth, parent.width * 0.55)
                        text: row.modelData.title || row.modelData.url
                        elide: Text.ElideRight
                    }

                    UiText {
                        anchors { left: title.right; leftMargin: 10; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        text: row.modelData.url
                        color: Theme.muted
                        elide: Text.ElideRight
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
