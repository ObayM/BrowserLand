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
        "chevron-down": "M6 9l6 6 6-6",
        "ellipsis-vertical": "M12 11a1 1 0 1 0 0 2a1 1 0 1 0 0-2M12 4a1 1 0 1 0 0 2a1 1 0 1 0 0-2M12 18a1 1 0 1 0 0 2a1 1 0 1 0 0-2",
        "settings-2": "M14 17H5M19 7h-9M17 14a3 3 0 1 0 0 6a3 3 0 1 0 0-6M7 4a3 3 0 1 0 0 6a3 3 0 1 0 0-6",
        "triangle-alert": "M21.73 18l-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3M12 9v4M12 17h.01",
        "history": "M3 12a9 9 0 1 0 9-9a9.75 9.75 0 0 0-6.74 2.74L3 8M3 3v5h5M12 7v5l4 2",
        "search": "M21 21l-4.34-4.34M11 3a8 8 0 1 0 0 16a8 8 0 1 0 0-16",
        "minus": "M5 12h14",
        "globe": "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20M12 2a14.5 14.5 0 0 0 0 20a14.5 14.5 0 0 0 0-20M2 12h20"
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
