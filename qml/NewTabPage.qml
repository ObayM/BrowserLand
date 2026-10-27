import QtQuick
import BrowserLand
import QtQuick.Effects

Rectangle {
    id: page
    
    property date now: new Date()
    property var sites: []
    property int today: 0

    readonly property int tileSize: 56
    readonly property int fits: Math.max(1, Math.floor((width - 96) / (tileSize + 6)))
    
    function refresh (){
        now = new Date()
        sites = History.top(7)
        
        today = History.visitedToday()

        const images = System.images(Config.appearance.wallpaper || "")
        wallpaper.source = images.length > 0? images[Math.floor(Math.random() * images.length)] : ""
    }


    component Figure: Column {
        id: figure 

        property int value
        property string label

        UiText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: figure.value
            font.pixelSize: Theme.fontSize + 9
            font.weight: Font.DemiBold
        }

        UiText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: figure.label
            color: Theme.muted
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    color: Theme.background
    onVisibleChanged: if (visible) refresh()
    Component.onCompleted: if (visible) refresh()

    Timer {
        interval: 999
        repeat: true
        running: page.visible
        onTriggered: page.now = new Date()
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: Screen.width * Screen.devicePixelRatio
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.duration * 2 } }
    }

    Rectangle {
        anchors.fill: parent
        opacity: wallpaper.opacity
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(Theme.background, 0.2) }
            GradientStop { position: 1; color: Theme.alpha(Theme.background, 0.8) }
        }
    }

    Column {
        id: center
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -30
        spacing: 40

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            layer.enabled: wallpaper.status === Image.Ready
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.8
                shadowOpacity: 0.45
            }

            UiText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(page.now, "hh:mm")
                font.pixelSize: 104
                font.weight: Font.Light
            }

            UiText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(page.now, "dddd, d MMMM")
                font.pixelSize: Theme.fontSize + 5
            }
        }

        Item {
            id: dock

            anchors.horizontalCenter: parent.horizontalCenter
            width: sitesRow.width + 20
            height: sitesRow.height + 20
            visible: page.sites.length > 0

            RectangularShadow {
                anchors.fill: parent
                radius: glass.radius
                blur: 30
                offset.y: 10
                color: Qt.rgba(0, 0, 0, 0.35)
            }

            ShaderEffectSource {
                id: behind
                anchors.fill: parent
                sourceItem: wallpaper
                sourceRect: Qt.rect(center.x + dock.x, center.y + dock.y, dock.width, dock.height)
                visible: false
            }

            Rectangle {
                id: shape
                anchors.fill: parent
                radius: glass.radius
                layer.enabled: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: behind
                visible: wallpaper.status === Image.Ready
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: 48
                saturation: 0.2
                maskEnabled: true
                maskSource: shape
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Rectangle {
                id: glass
                anchors.fill: parent
                radius: Theme.radius * 3
                border.color: Theme.alpha(Theme.foreground, 0.14)
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(Theme.raised, 0.55) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.background, 0.45) }
                }
            }

            Row {
                id: sitesRow
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: page.sites.slice(0, page.fits)

                    delegate: Item {
                        id: tile

                        required property var modelData

                        width: page.tileSize
                        height: page.tileSize

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius * 2
                            color: mouse.pressed ? Theme.pressed : Theme.hover
                            opacity: mouse.containsMouse ? 1 : 0

                            Behavior on opacity { NumberAnimation { duration: Theme.duration } }
                        }

                        Item {
                            anchors.centerIn: parent
                            width: 32
                            height: 32
                            scale: mouse.containsMouse ? 1.18 : 1

                            Behavior on scale { NumberAnimation { duration: Theme.duration * 1.5; easing.type: Easing.OutBack } }

                            Image {
                                id: favicon
                                anchors.fill: parent
                                sourceSize: Qt.size(64, 64)
                                source: tile.modelData.icon
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                visible: favicon.status !== Image.Ready
                                color: Theme.alpha(Theme.accent, 0.2)

                                UiText {
                                    anchors.centerIn: parent
                                    text: Browser.hostOf(tile.modelData.url).replace(/^www\./, "").charAt(0).toUpperCase()
                                    color: Theme.accent
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Browser.navigate(tile.modelData.url)
                        }

                        Tooltip {
                            target: tile
                            text: tile.modelData.title || Browser.hostOf(tile.modelData.url)
                            show: mouse.containsMouse
                        }
                    }
                }
            }
        }
    }

    Row {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 28 }
        spacing: 56

        Figure {
            value: Browser.tabs.length
            label: value === 1 ? "tab open" : "tabs open"
        }

        Figure {
            value: page.today
            label: value === 1 ? "page today" : "pages today"
        }
    }
}