import QtQuick
import BrowserLand


Row {
    id: widgetSlot

    required property string name
    readonly property var widgets: Array.from(Config.widgets).filter(widget => widget.slot === widgetSlot.name)
    readonly property int count: widgets.length

    spacing: 10

    Repeater {
        model: widgetSlot.widgets

        delegate: UserQml {
            required property var modelData
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            source: modelData.url
            label: "widget '" + modelData.name + "'"
        }
    }
}
