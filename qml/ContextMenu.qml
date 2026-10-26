import QtQuick
import QtWebEngine
import BrowserLand

Item {
    id: menu

    property bool open: false
    property var items: []
    readonly property real contentHeight: items.reduce((height, item) => height + (item.separator ? 9 : 30), 12)

    function bound(action) {
        const bind = Array.from(Config.binds).find(bind => bind.action === action && !bind.args)
        return bind ? bind.sequence : ""
    }

    function quoted(text) {
        const line = text.replace(/\s+/g, " ")
        return "“" + (line.length > 20 ? line.slice(0, 20) + "…" : line) + "”"
    }

    function copyText(text) {
        clipboard.text = text
        clipboard.selectAll()
        clipboard.copy()
    }

    function build(view, request) {
        const act = action => () => view.triggerWebAction(action)
        const can = flag => !!(request.editFlags & flag)
        const media = flag => !!(request.mediaFlags & flag)
        
        const mediaUrl = request.mediaUrl.toString()
        const selected = request.selectedText.trim()
        
        const kind = request.mediaType === ContextMenuRequest.MediaTypeVideo ? "video"
                   : request.mediaType === ContextMenuRequest.MediaTypeAudio ? "audio" : ""
        const sections = []
        const link = request.linkUrl.toString()

        if (request.linkUrl.toString() !== "")
            sections.push([
                { text: "Open link in new tab", run: act(WebEngineView.OpenLinkInNewTab) },
                { text: "Download link", run: act(WebEngineView.DownloadLinkToDisk) },
                { text: "Copy link address", run: act(WebEngineView.CopyLinkToClipboard) },
                { text: "Copy link as Markdown", run: () => copyText("[" + request.linkText + "](" + link + ")") },
                Bookmarks.has(link) ? { text: "Remove bookmark", run: () => Bookmarks.remove(link) }
                                    : { text: "Bookmark link", run: () => Bookmarks.add(link, request.linkText, "") }
            ])

        if (request.mediaType === ContextMenuRequest.MediaTypeImage)
            sections.push([
                { text: "Open image in new tab", run: () => Browser.newTab(mediaUrl, true) },
                { text: "Save image", run: act(WebEngineView.DownloadImageToDisk) },
                { text: "Copy image", run: act(WebEngineView.CopyImageToClipboard) },
                { text: "Copy image address", run: act(WebEngineView.CopyImageUrlToClipboard) },
            ])

        if (kind) {
            sections.push([
                { text: media(ContextMenuRequest.MediaPaused) ? "Play" : "Pause", run: act(WebEngineView.ToggleMediaPlayPause) },
                { text: media(ContextMenuRequest.MediaMuted) ? "Unmute" : "Mute", run: act(WebEngineView.ToggleMediaMute) },
                { text: "Loop", checked: media(ContextMenuRequest.MediaLoop), run: act(WebEngineView.ToggleMediaLoop) },
                {
                    text: "Show controls",
                    checked: media(ContextMenuRequest.MediaControls),
                    enabled: media(ContextMenuRequest.MediaCanToggleControls),
                    run: act(WebEngineView.ToggleMediaControls)
                }
            ])
            sections.push([
                { text: "Open " + kind + " in new tab", run: () => Browser.newTab(mediaUrl, true) },
                { text: "Save " + kind, enabled: media(ContextMenuRequest.MediaCanSave), run: act(WebEngineView.DownloadMediaToDisk) },
                { text: "Copy " + kind + " address", run: act(WebEngineView.CopyMediaUrlToClipboard) },

            ])
        }

        if (request.isContentEditable) {
            const suggestions = Array.from(request.spellCheckerSuggestions)
            if (suggestions.length > 0)
                sections.push(suggestions.map(word => ({ text: word, run: () => view.replaceMisspelledWord(word) })))

            sections.push([
                { text: "Undo", enabled: can(ContextMenuRequest.CanUndo), run: act(WebEngineView.Undo) },
                { text: "Redo", enabled: can(ContextMenuRequest.CanRedo), run: act(WebEngineView.Redo) }
            ])
            sections.push([
                { text: "Cut", enabled: can(ContextMenuRequest.CanCut), run: act(WebEngineView.Cut) },
                { text: "Copy", enabled: can(ContextMenuRequest.CanCopy), run: act(WebEngineView.Copy) },
                { text: "Paste", enabled: can(ContextMenuRequest.CanPaste), run: act(WebEngineView.Paste) },
                { text: "Paste as plain text", enabled: can(ContextMenuRequest.CanPaste), run: act(WebEngineView.PasteAndMatchStyle) },
                { text: "Select all", enabled: can(ContextMenuRequest.CanSelectAll), run: act(WebEngineView.SelectAll) },
            ])
        }

        if (selected !== "") {
            const search = {
                text: "Search the web for " + quoted(selected),
                run: () => Browser.newTab(Config.general.search_url.replace("{}", encodeURIComponent(selected)))
            }
            sections.push(request.isContentEditable ? [search] : [{ text: "Copy", run: act(WebEngineView.Copy) }, search])
        }

        if (sections.length === 0) {
            sections.push([
                { text: "Back", shortcut: bound("back"), enabled: view.canGoBack, run: act(WebEngineView.Back) },
                { text: "Forward", shortcut: bound("forward"), enabled: view.canGoForward, run: act(WebEngineView.Forward) },
                { text: "Reload", shortcut: bound("reload"), run: act(WebEngineView.Reload) }
            ])

            sections.push([
                { text: "Save page", run: act(WebEngineView.SavePage) },
                { text: "Select all", run: act(WebEngineView.SelectAll) },
                { text: "View page source", run: act(WebEngineView.ViewSource) },
                { text: "Duplicate tab", run: () => Browser.newTab(view.url.toString()) },
                { text: Bookmarks.has(view.url) ? "Edit bookmark" : "Bookmark page", shortcut: bound("bookmark"), run: () => Browser.run("bookmark") }
            ])
        }

        sections.push([{ text: "Inspect", shortcut: bound("devtools"), run: () => Browser.inspectRequested() }])

        return sections
    }

    function popup(sections, item, x, y) {
        items = sections.filter(section => section.length > 0).reduce(
                (all, section) => all.length > 0 ? all.concat([{separator: true}], section) : section, [])
            
        
        const point = item.mapToItem(menu, x, y)
        
        panel.x = point.x + panel.width > width - 4 ? Math.max(4, point.x - panel.width) : point.x
        panel.y = point.y + panel.height > height - 4 ? Math.max(4, point.y - panel.height) : point.y
        flick.contentY = 0
        open = true
    }

    opacity: open ? 1 : 0
    visible: opacity > 0
    enabled: open

    Behavior on opacity { NumberAnimation { duration: Theme.duration / 2 } }

    Connections {
        target: Browser
        function onContextMenuRequested(view, request) { 
            menu.popup(
                menu.build(view, request), view, request.position.x, request.position.y
            )
        }
        function onCurrentChanged() { menu.open = false }
        function onMenuRequested(sections, item, x, y) { menu.popup(sections, item, x, y) }    
    }

    Shortcut {
        sequence: "Esc"
        enabled: menu.open
        onActivated: menu.open = false
    }

    TextEdit {
        id: clipboard
        visible: false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: menu.open = false
        onWheel: menu.open = false
    }

    Rectangle {
        id: panel

        width: 260
        height: Math.min(menu.contentHeight, menu.height - 8)
        radius: Theme.radius
        color: Theme.overlay
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Flickable {
            id: flick
            anchors.fill: parent
            contentHeight: menu.contentHeight
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: column
                x: 6
                y: 6
                width: flick.width - 12

                Repeater {
                    model: menu.items

                    delegate: Item {
                        id: entry

                        required property var modelData
                        required property int index

                        width: column.width
                        height: modelData.separator ? 9 : 30
                        enabled: modelData.enabled !== false
                        opacity: enabled ? 1 : 0.35

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
                            visible: !entry.modelData.separator

                            UiText {
                                anchors { left: parent.left; leftMargin: 12; right: hint.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                text: entry.modelData.text || ""
                                elide: Text.ElideRight
                            }

                            UiText {
                                id: hint
                                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                text: entry.modelData.shortcut || ""
                                color: Theme.muted
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Icon {
                                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                name: "check"
                                size: 14
                                visible: !!entry.modelData.checked
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: {
                                    menu.open = false
                                    menu.items[entry.index].run()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
