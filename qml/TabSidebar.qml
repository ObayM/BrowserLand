import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import BrowserLand


Rectangle {
    id: sidebar
    
    readonly property int rowHeight: 38
    property var draggedView: null
    property real dragTop: 0
    property real grab: 0

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
    }

    function reveal() {
        const index = modelIndexOf(Browser.current)
        if (index >= 0)
            list.positionViewAtIndex(index, ListView.Contain)
    }


    function dragTo(cursorY) {
        const count = Browser.tabs.length
        dragTop = Math.max(0, Math.min(cursorY - grab, (count - 1) * rowHeight))
        
        const from = Browser.tabs.indexOf(draggedView)
        const to = Math.max(0, Math.min(count - 1, Math.round(dragTop / rowHeight)))
        if (from >= 0 && to !== from)
            Browser.moveTab(from, to)
    }

    implicitWidth: 240
    color: Theme.sunken

    Connections {
        target: Browser
        function onTabsChanged() { sidebar.sync() }
        function onCurrentChanged() { Qt.callLater(sidebar.reveal) }
    }

    Component.onCompleted: sync()

    ListView {
        id: list

        anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
        topMargin: 8
        bottomMargin: 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 100000
        model: tabModel

        move: Transition { NumberAnimation { property: "y"; duration: Theme.duration; easing.type: Easing.OutCubic } }
        moveDisplaced: Transition { NumberAnimation { property: "y"; duration: Theme.duration; easing.type: Easing.OutCubic } }

        footer: Item {
            width: list.width
            height: sidebar.rowHeight

            Rectangle {
                anchors { fill: parent; topMargin: 2; bottomMargin: 2 }
                radius: Theme.radius
                color: newTabMouse.containsMouse ? Theme.hover : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.duration / 2 } }

                Icon {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    name: "plus"
                    color: Theme.muted
                }

                UiText {
                    x: 38
                    anchors.verticalCenter: parent.verticalCenter
                    text: "New tab"
                    color: Theme.muted
                }

                MouseArea {
                    id: newTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Browser.run("new-tab")
                }
            }
        }

        delegate: Item {
            id: tab

            required property var view
            required property bool closing
            required property int index

            readonly property bool active: !closing && view === Browser.current
            readonly property bool hovered: hover.hovered && !closing && !sidebar.draggedView
            readonly property bool dragged: !!sidebar.draggedView && sidebar.draggedView === view

            property real grow: 0
            property real settleOffset: 0
            property string title
            property url icon
            property bool loading

            function drop() {
                if (!dragged)
                    return
                settleOffset = sidebar.dragTop - y
                sidebar.draggedView = null
                snapBack.restart()
            }

            Binding on title {
                when: !!tab.view && !tab.closing
                value: !tab.view ? "" : tab.view.newTabPage ? "New Tab" : tab.view.title || tab.view.pendingTitle || tab.view.url.toString() || tab.view.pendingUrl
                restoreMode: Binding.RestoreNone
            }
            Binding on icon {
                when: !!tab.view && !tab.closing
                value: tab.view ? tab.view.icon : ""
                restoreMode: Binding.RestoreNone
            }
            Binding on loading {
                when: !!tab.view && !tab.closing
                value: tab.view ? tab.view.loading : false
                restoreMode: Binding.RestoreNone
            }

            width: list.width
            height: sidebar.rowHeight * grow
            clip: grow < 1
            z: dragged ? 2 : 1

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

            NumberAnimation {
                id: snapBack
                target: tab
                property: "settleOffset"
                to: 0
                duration: Theme.duration
                easing.type: Easing.OutCubic
            }

            Item {
                id: body
                y: tab.dragged ? sidebar.dragTop - tab.y : tab.settleOffset
                width: tab.width
                height: sidebar.rowHeight
                opacity: tab.grow

                HoverHandler { id: hover }

                Rectangle {
                    anchors { fill: parent; topMargin: 2; bottomMargin: 2 }
                    radius: Theme.radius
                    color: tab.active ? Theme.background : tab.hovered ? Theme.hover : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.duration / 2 } }

                    RectangularShadow {
                        anchors.fill: parent
                        z: -1
                        radius: parent.radius
                        blur: 6
                        offset.y: 1
                        color: Qt.rgba(0, 0, 0, Theme.dark ? 0.3 : 0.08)
                        opacity: tab.active ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: Theme.duration / 2 } }
                    }
                }

                MouseArea {
                    id: mouse

                    property real pressY: 0

                    anchors.fill: parent
                    enabled: !tab.closing
                    preventStealing: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                    onPressed: event => {
                        if (event.button !== Qt.LeftButton)
                            return
                        pressY = mapToItem(list.contentItem, 0, event.y).y
                        Browser.selectTab(Browser.tabs.indexOf(tab.view))
                    }
                    onPositionChanged: event => {
                        if (!(pressedButtons & Qt.LeftButton))
                            return
                        const y = mapToItem(list.contentItem, 0, event.y).y
                        if (!tab.dragged) {
                            if (Math.abs(y - pressY) < 8)
                                return
                            sidebar.grab = pressY - tab.y
                            sidebar.draggedView = tab.view
                        }
                        sidebar.dragTo(y)
                    }
                    onReleased: tab.drop()
                    onCanceled: tab.drop()
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            Browser.closeTab(Browser.tabs.indexOf(tab.view))
                    }
                }

                Item {
                    id: content
                    anchors { fill: parent; leftMargin: 12; rightMargin: 6 }

                    Image {
                        id: favicon
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        source: tab.icon
                        visible: !tab.loading && status === Image.Ready
                    }

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "globe"
                        color: Theme.muted
                        visible: !tab.loading && favicon.status !== Image.Ready
                    }

                    Shape {
                        id: spinner
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        visible: tab.loading
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeColor: Theme.accent
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            PathAngleArc { centerX: 8; centerY: 8; radiusX: 6; radiusY: 6; startAngle: 0; sweepAngle: 270 }
                        }

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                            running: spinner.visible
                        }
                    }

                    UiText {
                        anchors {
                            left: parent.left
                            leftMargin: 26
                            right: closeButton.visible ? closeButton.left : parent.right
                            rightMargin: 6
                            verticalCenter: parent.verticalCenter
                        }
                        text: tab.title
                        color: tab.active ? Theme.foreground : Theme.muted
                        elide: Text.ElideRight
                    }

                    IconButton {
                        id: closeButton
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        implicitWidth: 22
                        implicitHeight: 22
                        icon: "x"
                        iconSize: 12
                        visible: tab.active || tab.hovered
                        onClicked: Browser.closeTab(Browser.tabs.indexOf(tab.view))
                    }
                }
            }
        }
    }
}
