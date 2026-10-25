import QtQuick
import QtQuick.Shapes
import BrowserLand

Rectangle {
    id: strip

    readonly property int maxTabWidth: 240
    readonly property int minTabWidth: 48
    readonly property int inset: 4
    readonly property real topRadius: Theme.radius * 1.5
    readonly property real earRadius: Theme.radius * 1.25
    readonly property int footerWidth: 40

    property int liveCount: 0
    property bool animateWidth: false
    property real frozenWidth: 0
    readonly property real fitWidth: Math.max(minTabWidth, Math.min(maxTabWidth,
        (list.width - list.leftMargin - list.rightMargin - footerWidth) / Math.max(1, liveCount)))
    
    readonly property real tabWidth: frozenWidth > 0 ? frozenWidth : fitWidth
    property real smoothTabWidth: tabWidth

    property var draggedView: null
    property real dragLeft: 0
    property real grab: 0

    property int currentModelIndex: -1
    property int hoverModelIndex: -1
    property Item hoverTab: null

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
            if (from < 0) {
                tabModel.insert(at, { view, closing: false })
                frozenWidth = 0
            } else if (from !== at) {
                tabModel.move(from, at, 1)
            }
            at++
        }

        animateWidth = true
        liveCount = tabs.length
        widthSettle.restart()
        updateCurrent()
    }

    function updateCurrent() {
        currentModelIndex = modelIndexOf(Browser.current)
        list.currentIndex = currentModelIndex
    }

    function tabPath(w, h) {
        const a = inset
        const b = w - inset

        if (b - a < 1)
            return ""
        const R = Math.min(topRadius, (b - a) / 2)
        const r = earRadius
        return `M${a - r} ${h + 1}L${a - r} ${h}A${r} ${r} 0 0 0 ${a} ${h - r}L${a} ${R}A${R} ${R} 0 0 1 ${a + R} 0`
             + `L${b - R} 0A${R} ${R} 0 0 1 ${b} ${R}L${b} ${h - r}A${r} ${r} 0 0 0 ${b + r} ${h}L${b + r} ${h + 1}Z`
    }

    function closeFromMouse(view) {
        if (fitWidth < maxTabWidth)
            frozenWidth = tabWidth
        Browser.closeTab(Browser.tabs.indexOf(view))
    }

    function dragTo(cursorX) {
        dragLeft = Math.max(0, Math.min(cursorX - grab, (liveCount - 1) * tabWidth))
        const from = Browser.tabs.indexOf(draggedView)
        const to = Math.max(0, Math.min(liveCount - 1, Math.round(dragLeft / tabWidth)))
        if (from >= 0 && to !== from)
            Browser.moveTab(from, to)
    }

    function tabHovered(item, on) {
        if (on) {
            hoverTab = item
            hoverModelIndex = item.index
            cardHide.stop()

            if (card.shown)
                card.place()
            else
                cardDelay.restart()
        } else if (hoverTab === item) {
            hoverModelIndex = -1
            cardDelay.stop()
            cardHide.restart()
        }
    }

    function hideCard() {
        cardDelay.stop()
        card.shown = false
    }

    implicitHeight: 44
    color: Theme.sunken

    Behavior on smoothTabWidth {
        enabled: strip.animateWidth
        NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic }
    }

    Timer {
        id: widthSettle
        interval: Theme.duration + 50
        onTriggered: strip.animateWidth = false
    }

    Timer {
        id: cardDelay
        interval: 500
        onTriggered: card.shown = true
    }

    Timer {
        id: cardHide
        interval: 100
        onTriggered: {
            if (!strip.hoverTab || !strip.hoverTab.hovered) {
                card.shown = false
                strip.hoverTab = null
            }
        }
    }

    Connections {
        target: Browser
        function onTabsChanged() { strip.sync() }
        function onCurrentChanged() { strip.updateCurrent() }
    }

    Component.onCompleted: sync()

    HoverHandler {
        onHoveredChanged: {
            if (!hovered && strip.frozenWidth > 0) {
                strip.animateWidth = true
                widthSettle.restart()
                strip.frozenWidth = 0
            }
        }
    }

    MouseArea {
        property real pending: 0

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            pending -= wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
            
            while (pending >= 120) {
                pending -= 120
                Browser.selectTab(Browser.currentIndex + 1)
            }
            
            while (pending <= -120) {
                pending += 120
                Browser.selectTab(Browser.currentIndex - 1)
            }
        }
    }

    ListView {
        id: list

        anchors { left: parent.left; right: extraWidgets.left; top: parent.top; topMargin: 10; bottom: parent.bottom }
        leftMargin: 8
        rightMargin: 8
        orientation: ListView.Horizontal
        interactive: false
        clip: true
        cacheBuffer: 100000
        model: tabModel

        move: Transition { NumberAnimation { property: "x"; duration: Theme.duration; easing.type: Easing.OutCubic } }
        moveDisplaced: Transition { NumberAnimation { property: "x"; duration: Theme.duration; easing.type: Easing.OutCubic } }

        footer: Item {
            width: strip.footerWidth
            height: list.height

            IconButton {
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3
                implicitWidth: 28
                implicitHeight: 28
                icon: "plus"
                iconSize: 16
                tip: "New tab"
                onClicked: Browser.run("new-tab")
            }
        }

        delegate: Item {
            id: tab

            required property var view
            required property bool closing
            required property int index

            readonly property bool active: !closing && view === Browser.current
            readonly property bool hovered: mouse.containsMouse && !closing && !strip.draggedView
            readonly property bool dragged: !!strip.draggedView && strip.draggedView === view
            readonly property bool compact: width < 72
            property color fill: active ? Theme.background : hovered ? Qt.tint(Theme.sunken, Theme.hover) : Theme.sunken
            property real grow: 0
            property real settleOffset: 0
            property string title
            property url icon
            property string url
            property bool loading

            function drop() {
                if (!dragged)
                    return
                settleOffset = strip.dragLeft - x
                strip.draggedView = null
                snapBack.restart()
            }

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
            Binding on url {
                when: !!tab.view && !tab.closing
                value: tab.view ? tab.view.url.toString() || tab.view.pendingUrl : ""
                restoreMode: Binding.RestoreNone
            }
            Binding on loading {
                when: !!tab.view && !tab.closing
                value: tab.view ? tab.view.loading : false
                restoreMode: Binding.RestoreNone
            }

            width: strip.smoothTabWidth * grow
            height: list.height
            z: dragged ? 3 : active ? 2 : 1

            onHoveredChanged: strip.tabHovered(tab, hovered)

            Behavior on fill { ColorAnimation { duration: Theme.duration / 2 } }

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

            Rectangle {
                width: 1
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3
                color: Theme.alpha(Theme.foreground, 0.2)
                opacity: tab.index > 0 && !tab.closing && !tab.dragged
                         && strip.currentModelIndex !== tab.index && strip.currentModelIndex !== tab.index - 1
                         && strip.hoverModelIndex !== tab.index && strip.hoverModelIndex !== tab.index - 1 ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: Theme.duration } }
            }

            Item {
                id: body
                x: tab.dragged ? strip.dragLeft - tab.x : tab.settleOffset
                width: tab.width
                height: tab.height

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    opacity: tab.active ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Theme.duration / 2 } }

                    ShapePath {
                        fillColor: Theme.background
                        strokeWidth: -1
                        PathSvg { path: strip.tabPath(body.width, body.height) }
                    }
                }

                Rectangle {
                    anchors { fill: parent; leftMargin: strip.inset + 2; rightMargin: strip.inset + 2; bottomMargin: 6 }
                    radius: Theme.radius
                    color: Theme.hover
                    opacity: tab.hovered && !tab.active ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Theme.duration } }
                }

                MouseArea {
                    id: mouse

                    property real pressX: 0

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !tab.closing
                    preventStealing: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                    onPressed: event => {
                        strip.hideCard()
                        if (event.button !== Qt.LeftButton)
                            return
                        pressX = mapToItem(list.contentItem, event.x, 0).x
                        Browser.selectTab(Browser.tabs.indexOf(tab.view))
                    }
                    onPositionChanged: event => {
                        if (!(pressedButtons & Qt.LeftButton))
                            return
                        const x = mapToItem(list.contentItem, event.x, 0).x
                        if (!tab.dragged) {
                            if (Math.abs(x - pressX) < 8)
                                return
                            strip.grab = pressX - tab.x
                            strip.draggedView = tab.view
                        }
                        strip.dragTo(x)
                    }
                    onReleased: tab.drop()
                    onCanceled: tab.drop()
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            strip.closeFromMouse(tab.view)
                    }
                }

                Item {
                    id: content
                    anchors { fill: parent; leftMargin: strip.inset + 10; rightMargin: strip.inset + 6; bottomMargin: 6 }

                    readonly property bool showIcon: !(tab.compact && tab.active)
                    readonly property real iconX: tab.compact ? (width - 16) / 2 : 0

                    Image {
                        id: favicon
                        x: content.iconX
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        source: tab.icon
                        visible: content.showIcon && !tab.loading && status === Image.Ready
                    }

                    Icon {
                        x: content.iconX
                        anchors.verticalCenter: parent.verticalCenter
                        name: "globe"
                        color: Theme.muted
                        visible: content.showIcon && !tab.loading && favicon.status !== Image.Ready
                    }

                    Shape {
                        id: spinner
                        x: content.iconX
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        visible: content.showIcon && tab.loading
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

                    Item {
                        id: titleBox
                        anchors {
                            left: parent.left
                            leftMargin: 24
                            right: closeButton.visible ? closeButton.left : parent.right
                            rightMargin: 4
                            verticalCenter: parent.verticalCenter
                        }
                        height: label.implicitHeight
                        clip: true
                        visible: !tab.compact

                        UiText {
                            id: label
                            text: tab.title
                            color: tab.active ? Theme.foreground : Theme.muted
                        }

                        Rectangle {
                            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                            width: 24
                            visible: label.implicitWidth > titleBox.width
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.alpha(tab.fill, 0) }
                                GradientStop { position: 1; color: tab.fill }
                            }
                        }
                    }

                    IconButton {
                        id: closeButton
                        x: tab.compact ? (content.width - width) / 2 : content.width - width
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 20
                        implicitHeight: 20
                        icon: "x"
                        iconSize: 12
                        visible: tab.active || tab.width >= 110
                        onClicked: strip.closeFromMouse(tab.view)
                    }
                }
            }
        }
    }

    WidgetSlot {
        id: extraWidgets
        name: "tabbar-right"
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
    }

    Rectangle {
        id: card

        property bool shown: false
        readonly property string title: strip.hoverTab ? strip.hoverTab.title : ""
        readonly property string host: strip.hoverTab ? Browser.hostOf(strip.hoverTab.url) : ""

        function place() {
            if (!strip.hoverTab || !parent)
                return
            const below = strip.hoverTab.mapToItem(parent, strip.inset, strip.hoverTab.height + 4)
            x = Math.max(4, Math.min(below.x, parent.width - width - 4))
            y = below.y
        }

        parent: strip.Window.contentItem

        z: 95
        width: 260
        height: cardColumn.implicitHeight + 20
        radius: Theme.radius
        color: Theme.overlay
        border.width: 1
        border.color: Theme.border
        opacity: shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: Theme.duration } }
        Behavior on x {
            enabled: card.visible
            NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic }
        }

        onShownChanged: if (shown) place()

        Column {
            id: cardColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 2

            UiText {
                width: parent.width
                text: card.title
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            UiText {
                width: parent.width
                text: card.host
                visible: text !== ""
                color: Theme.muted
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }
        }
    }
}
