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
        "check": "M20 6L9 17l-5-5",
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
        "globe": "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20M12 2a14.5 14.5 0 0 0 0 20a14.5 14.5 0 0 0 0-20M2 12h20",
        "lock": "M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2zM7 11V7a5 5 0 0 1 10 0v4",
        "volume-2": "M11 4.702a0.705 0.705 0 0 0-1.203-0.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 0.997 0.413l3.383 3.384A0.705 0.705 0 0 0 11 19.298zM16 9a5 5 0 0 1 0 6M19.364 18.364a9 9 0 0 0 0-12.728",
        "volume-x": "M11 4.702a0.705 0.705 0 0 0-1.203-0.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 0.997 0.413l3.383 3.384A0.705 0.705 0 0 0 11 19.298zM22 9l-6 6M16 9l6 6",
        "video": "M16 13l5.223 3.482a0.5 0.5 0 0 0 0.777-0.416V7.87a0.5 0.5 0 0 0-0.752-0.432L16 10.5M4 6h10a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z",
        "mic": "M12 19v3M19 10v2a7 7 0 0 1-14 0v-2M12 2a3 3 0 0 1 3 3v7a3 3 0 0 1-6 0V5a3 3 0 0 1 3-3z",
        "bell": "M10.268 21a2 2 0 0 0 3.464 0M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 0.74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326",
        "map-pin": "M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0M12 7a3 3 0 1 0 0 6a3 3 0 1 0 0-6",
        "clipboard": "M9 2h6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1zM16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2",
        "type": "M12 4v16M4 7V5a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v2M9 20h6",
        "cookie": "M12 2a10 10 0 1 0 10 10a4 4 0 0 1-5-5a4 4 0 0 1-5-5M8.5 8.5v0.01M16 15.5v0.01M12 12v0.01M11 17v0.01M7 14v0.01",
        "external-link": "M15 3h6v6M10 14L21 3M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"
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
