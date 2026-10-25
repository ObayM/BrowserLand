import QtQuick
import BrowserLand
import QtQuick.Effects

Rectangle {
    id: page
    
    property date now: new Date()
    property var sites: []
    property int today: 0

    readonly property int tileSize: 96
    readonly property int fits: Math.max(1, Math.floor((width - 64) / (tileSize + 14)))
    
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
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -30

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

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 44
            spacing: 14

            Repeater {
                model: page.sites.slice(0, page.fits)

                delegate: Rectangle {
                    id: tile

                    required property var modelData

                    width: page.tileSize
                    height: page.tileSize
                    radius: Theme.radius * 1.5
                    color: Theme.alpha(Theme.raised, mouse.containsMouse ? 0.9 : 0.6)
                    border.color: Theme.border

                    Behavior on color { ColorAnimation { duration: Theme.duration } }

                    Image {
                        id: favicon
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 20 }
                        width: 32
                        height: 32
                        sourceSize: Qt.size(32, 32)
                        source: tile.modelData.icon
                    }

                    UiText {
                        anchors.centerIn: favicon
                        visible: favicon.status !== Image.Ready
                        text: Browser.hostOf(tile.modelData.url).replace(/^www\./, "").charAt(0).toUpperCase()
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }

                    UiText {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: tile.modelData.title || Browser.hostOf(tile.modelData.url)
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Browser.navigate(tile.modelData.url)
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