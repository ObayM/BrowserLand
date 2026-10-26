import QtQuick
import QtQuick.Layouts
import BrowserLand

Popover {
    id: editor

    property string url
    property bool added: false
    readonly property var bookmark: Bookmarks.items.find(item => item.url === url) || null

    function edit(item, link, justAdded) {
        anchorItem = item
        alignRight = item.mapToItem(null, item.width / 2, 0).x > item.Window.width / 2
        url = link
        added = !!justAdded
        open = true
    }

    closeOnOutsideClick: true
    width: 320
    height: content.implicitHeight + 28

    onOpenChanged: {
        if (open) {
            name.text = bookmark ? bookmark.title : ""
            name.forceActiveFocus()
            name.selectAll()
        } else if (name.activeFocus && Browser.current) {
            Browser.current.forceActiveFocus()
        }
    }
    
    onBookmarkChanged: if (!bookmark) open = false

    Shortcut {
        sequence: "Esc"
        enabled: editor.open
        onActivated: editor.open = false
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        UiText {
            text: editor.added ? "Bookmark added" : "Edit bookmark"
            font.pixelSize: Theme.fontSize + 2
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: Theme.radiusSmall
            color: Theme.field
            border.width: 1
            border.color: name.activeFocus ? Theme.accent : Theme.border

            TextInput {
                id: name
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                selectByMouse: true
                color: Theme.foreground
                selectionColor: Theme.accent
                selectedTextColor: Theme.background
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize

                onTextEdited: Bookmarks.rename(editor.url, text)
                onAccepted: editor.open = false
            }
        }

        UiText {
            Layout.fillWidth: true
            text: editor.url
            color: Theme.muted
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideMiddle
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 6

            TextButton {
                text: "Remove"
                onClicked: Bookmarks.remove(editor.url)
            }
            TextButton {
                text: "Done"
                primary: true
                onClicked: editor.open = false
            }
        }
    }
}
