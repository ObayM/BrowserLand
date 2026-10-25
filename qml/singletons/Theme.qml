pragma Singleton

import QtQuick
import BrowserLand

QtObject {
    readonly property color background: Config.appearance.background
    readonly property color foreground: Config.appearance.foreground
    readonly property color accent: Config.appearance.accent

    readonly property bool dark: background.hslLightness < 0.5
    readonly property color sunken: Qt.tint(background, Qt.rgba(0, 0, 0, dark ? 0.45 : 0.12))
    readonly property color field: Qt.tint(background, Qt.rgba(0, 0, 0, dark ? 0.33 : 0.055))
    readonly property color raised: Qt.tint(background, alpha(foreground, 0.07))
    readonly property color overlay: Qt.tint(background, alpha(foreground, 0.1))
    readonly property color hover: alpha(foreground, 0.08)
    readonly property color pressed: alpha(foreground, 0.15)
    readonly property color border: alpha(foreground, 0.13)
    readonly property color muted: alpha(foreground, 0.6)

    readonly property string fontFamily: Config.appearance.font || Qt.application.font.family
    readonly property int fontSize: Config.appearance.font_size || 13
    readonly property int fontSizeSmall: fontSize - 2

    readonly property int radius: Config.appearance.radius ?? 8
    readonly property int radiusSmall: Math.max(0, radius - 2)

    readonly property int duration: Config.appearance.animations === false ? 0 : 160

    function alpha(color, amount) {
        return Qt.rgba(color.r, color.g, color.b, amount)
    }
}
