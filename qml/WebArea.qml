import QtQuick
import BrowserLand


Item {
    id: area

    property Item shown: null

    function showCurrent() {
        const view = Browser.current
        if (shown && shown !== view && shown.parent === area)
            Browser.park(shown)
        if (view && view !== Browser.fullScreenView) {
            view.parent = area
            view.anchors.fill = area
            view.visible = Qt.binding(() => !view.newTabPage)
        }
        shown = view
    }

    Connections {
        target: Browser
        function onCurrentChanged() { area.showCurrent() }
        function onFullScreenViewChanged() { area.showCurrent() }
    }

    NewTabPage {
        anchors.fill: parent
        z: 1
        visible: !!Browser.current && Browser.current.newTabPage
    }

    PermissionPrompt {
        anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
        z: 2
    }

    FindBar {
        anchors { top: parent.top; right: parent.right; margins: 10 }
        z: 2
    }

    Component.onCompleted: showCurrent()

    Component.onDestruction: if (shown && shown.parent === area) Browser.park(shown)
}
