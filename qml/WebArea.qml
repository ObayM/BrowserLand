import QtQuick
import BrowserLand


Item {
    id: area

    property Item shown: null

    function showCurrent() {
        const view = Browser.current
        if (shown && shown !== view && shown.parent === area)
            Browser.park(shown)
        if (view) {
            view.parent = area
            view.anchors.fill = area
            view.visible = true
        }
        shown = view
    }

    Connections {
        target: Browser
        function onCurrentChanged() { area.showCurrent() }
    }

    Component.onCompleted: showCurrent()

    Component.onDestruction: if (shown && shown.parent === area) Browser.park(shown)
}