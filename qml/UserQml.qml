import QtQuick
import BrowserLand


Item {
    id: root

    property url source
    property string label
    property bool fill: false // stretch the loaded item over this one (for shell.qml)
    property Item item: null
    property bool ready: false

    implicitWidth: item ? item.implicitWidth : 0
    implicitHeight: item ? item.implicitHeight : 0

    function load() {
        if (item) {
            item.destroy()
            item = null
        }
        if (source.toString() === "") {
            Browser.setQmlError(label, "")
            return
        }
        const component = Qt.createComponent(source)
        if (component.status !== Component.Ready) {
            Browser.setQmlError(label, component.errorString().trim())
            return
        }
        const created = component.createObject(root)
        if (!created) {
            Browser.setQmlError(label, "could not be created, see the terminal for details")
            return
        }
        Browser.setQmlError(label, "")
        if (fill && created.anchors)
            created.anchors.fill = root
        item = created
    }

    onSourceChanged: if (ready) load()
    Component.onCompleted: {
        ready = true
        load()
    }
    Component.onDestruction: Browser.setQmlError(label, "")
}