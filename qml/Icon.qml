import QtQuick
import QtQuick.Shapes
import BrowserLand

Item {
    id: icon

    property string name
    property color color: Theme.foreground
    property real size: 16

    readonly property var paths: ({
        "arrow-left": "M12 19l-7-7 7-7M19 12H5",
        "arrow-right": "M5 12h14M12 5l7 7-7 7",
        "rotate-cw": "M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8M21 3v5h-5",
        "x": "M18 6 6 18M6 6l12 12",
        "plus": "M5 12h14M12 5v14",
        "download": "M12 15V3M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5",
        "chevron-up": "M18 15l-6-6-6 6",
        "chevron-down": "M6 9l6 6 6-6"
    })

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: icon.color
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: icon.paths[icon.name] || "" }
        }
    }
}
