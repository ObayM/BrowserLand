import QtQuick
import BrowserLand

Rectangle {
    id: strip

    property int liveCount: 0
    property bool animateWidth: false

    readonly property real tabWidth: Math.max(90, Math.min(220,
        (flick.width - newTabButton.width - 8) / Math.max(1, liveCount)))
    property real smoothTabWidth: tabWidth

    ListModel { id: tabModel }

    function modelIndexOf(view) {
        for (let i = 0; i < tabModel.count; ++i) {
            const entry = tabModel.get(i)
            if (!entry.closing && entry.view === view)
                return i
        }
        return -1
    }

    function sync() {
        const tabs = Browser.tabs
        
        for (let i = 0; i < tabModel.count; ++i) {
            const entry = tabModel.get(i)
            if (!entry.closing && !tabs.includes(entry.view))
                tabModel.setProperty(i, "closing", true)
        }

        let at = 0
        for (const view of tabs) {
            while (at < tabModel.count && tabModel.get(at).closing)
                at++
            const from = modelIndexOf(view)
            if (from < 0)
                tabModel.insert(at, { view, closing: false })
            else if (from !== at)
                tabModel.move(from, at, 1)
            at++
        }

        animateWidth = true
        liveCount = tabs.length
        settle.restart()
        scrollLater.restart()
    }

    function scrollToCurrent() {
        const item = repeater.itemAt(modelIndexOf(Browser.current))
        if (!item)
            return
        row.forceLayout()
        const left = item.x - 8
        const right = item.x + tabWidth + newTabButton.width + 8
        let target = flick.contentX
        if (left < target)
            target = left
        else if (right > target + flick.width)
            target = right - flick.width
        scroll.to = Math.max(0, target)
        scroll.restart()
    }

    implicitHeight: 40
    color: Theme.sunken

    Behavior on smoothTabWidth {
        enabled: strip.animateWidth
        NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic }
    }

    Timer {
        id: settle
        interval: Theme.duration + 50
        onTriggered: strip.animateWidth = false
    }

    Timer {
        id: scrollLater
        interval: 0
        onTriggered: strip.scrollToCurrent()
    }

    Connections {
        target: Browser
        function onTabsChanged() { strip.sync() }
        function onCurrentChanged() { scrollLater.restart() }
    }

    Component.onCompleted: sync()

    Flickable {
        id: flick

        anchors { left: parent.left; leftMargin: 6; right: extraWidgets.left; rightMargin: 6; top: parent.top; topMargin: 6; bottom: parent.bottom }
        contentWidth: row.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        clip: true

        NumberAnimation {
            id: scroll
            target: flick
            property: "contentX"
            duration: Theme.duration
            easing.type: Easing.OutCubic
        }

        Row {
            id: row
            height: flick.height
            spacing: 2

            Repeater {
                id: repeater
                model: tabModel

                delegate: Item {
                    id: tab

                    required property var view
                    required property bool closing
                    required property int index

                    readonly property bool active: !closing && view === Browser.current
                    readonly property bool hovered: mouse.containsMouse && !closing
                    property real grow: 0
                    property string title
                    property url icon

                    Binding on title {
                        when: !!tab.view && !tab.closing
                        value: tab.view ? tab.view.title || tab.view.pendingTitle || tab.view.url.toString() || tab.view.pendingUrl : ""
                        restoreMode: Binding.RestoreNone
                    }
                    Binding on icon {
                        when: !!tab.view && !tab.closing
                        value: tab.view ? tab.view.icon : ""
                        restoreMode: Binding.RestoreNone
                    }

                    width: strip.smoothTabWidth * grow
                    height: row.height
                    clip: true

                    NumberAnimation on grow { from: 0; to: 1; duration: Theme.duration; easing.type: Easing.OutCubic }

                    NumberAnimation {
                        target: tab
                        property: "grow"
                        to: 0
                        duration: Theme.duration
                        easing.type: Easing.OutCubic
                        running: tab.closing
                        onFinished: tabModel.remove(tab.index)
                    }

                    Rectangle {
                        anchors.fill: parent
                        topLeftRadius: Theme.radius
                        topRightRadius: Theme.radius
                        color: Theme.background
                        opacity: tab.active ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: Theme.duration } }
                    }

                    Rectangle {
                        anchors { fill: parent; margins: 2; bottomMargin: 6 }
                        radius: Theme.radiusSmall
                        color: Theme.hover
                        opacity: tab.hovered && !tab.active ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: Theme.duration / 2 } }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !tab.closing
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: event => {
                            const index = Browser.tabs.indexOf(tab.view)
                            if (event.button === Qt.MiddleButton)
                                Browser.closeTab(index)
                            else
                                Browser.selectTab(index)
                        }
                    }

                    Image {
                        id: favicon
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter; verticalCenterOffset: -2 }
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        source: tab.icon
                        visible: status === Image.Ready
                    }

                    UiText {
                        anchors {
                            left: favicon.visible ? favicon.right : parent.left
                            leftMargin: favicon.visible ? 8 : 10
                            right: closeButton.left
                            rightMargin: 4
                            verticalCenter: favicon.verticalCenter
                        }
                        text: tab.title
                        color: tab.active ? Theme.foreground : Theme.muted
                        elide: Text.ElideRight
                    }

                    IconButton {
                        id: closeButton
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: favicon.verticalCenter }
                        implicitWidth: 22
                        implicitHeight: 22
                        icon: "x"
                        iconSize: 14
                        opacity: tab.active || tab.hovered ? 1 : 0
                        onClicked: Browser.closeTab(Browser.tabs.indexOf(tab.view))
                    }
                }
            }

            IconButton {
                id: newTabButton
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -2
                icon: "plus"
                tip: "New tab"
                onClicked: Browser.run("new-tab")
            }
        }
    }

    WidgetSlot {
        id: extraWidgets
        name: "tabbar-right"
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
    }
}
