import QtQuick
import QtQuick.Layouts
import QtWebEngine
import BrowserLand

Popover {
    id: panel

    readonly property WebEngineView view: Browser.current
    readonly property string url: view ? view.url.toString() : ""
    readonly property string host: Browser.hostOf(url)

    readonly property string origin: {
        const match = url.match(/^([a-z][a-z0-9+.-]*:\/\/)(?:[^@\/?#]*@)?([^\/?#]*)/i)
        return match ? (match[1] + match[2]).toLowerCase() + "/" : ""
    }

    readonly property bool secure: url.startsWith("https:")
    readonly property string rules: Array.from(Config.siteRules)
        .filter(rule => new RegExp(rule.host).test(panel.host))
        .map(rule => rule.rule === "zoom" ? "zoom " + rule.zoom : rule.file.split("/").pop())
        .join(", ")

    readonly property var kinds: ({
        camera: { title: "Camera", icon: "video" },
        microphone: { title: "Microphone", icon: "mic" },
        notifications: { title: "Notifications", icon: "bell" },
        location: { title: "Location", icon: "map-pin" },
        clipboard: { title: "Clipboard", icon: "clipboard" },
        fonts: { title: "Fonts", icon: "type" }
    })

    property var permissions: []
    property int cookieCount: 0
    property bool needsReload: false
    property bool confirmClear: false

    function refresh() {
        permissions = Browser.profile && origin ? Array.from(Browser.profile.listPermissionsForOrigin(origin)) : []
        cookieCount = Browser.cookies.count(host)
    }

    function kind(permission) {
        const names = Browser.permissionNames(permission.permissionType)
        if (names.length > 1)
            return { title: "Camera and microphone", icon: "video" }
        
        return kinds[names[0]] || { title: "Other", icon: "settings-2" }
    }

    function allow(permission, allowed) {
        if (allowed)
            permission.grant()
        else
            permission.deny()
        
        needsReload = true
        refresh()
    }

    function resetPermissions() {
        for (const permission of permissions)
            permission.reset()
        
        needsReload = true
        refresh()
    }

    function fileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    closeOnOutsideClick: true
    width: 340
    height: content.implicitHeight + 16

    onOpenChanged: {
        if (open) {
            needsReload = false
            confirmClear = false
            refresh()
        }
    }
    onOriginChanged: open = false

    Connections {
        target: Browser.cookies
        enabled: panel.open
        function onChanged() { panel.cookieCount = Browser.cookies.count(panel.host) }
    }

    Shortcut {
        sequence: "Esc"
        enabled: panel.open
        onActivated: panel.open = false
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 4

            UiText {
                Layout.fillWidth: true
                text: panel.host
                font.pixelSize: Theme.fontSize + 3
                font.bold: true
                elide: Text.ElideMiddle
            }
            IconButton {
                Layout.rightMargin: -6
                implicitWidth: 28
                implicitHeight: 28
                iconSize: 16
                icon: "x"
                onClicked: panel.open = false
            }
        }

        Entry {
            icon: panel.secure ? "lock" : "triangle-alert"
            title: panel.secure ? "Connection is secure" : "Connection is not secure"
            detail: panel.secure ? "Your info is private when it's sent to this site"
                                 : "Don't enter passwords or card details here"
        }

        Separator {}

        Entry {
            icon: panel.view && panel.view.audioMuted ? "volume-x" : "volume-2"
            title: "Sound"

            Toggle {
                checked: !!panel.view && !panel.view.audioMuted
                onToggled: panel.view.audioMuted = !panel.view.audioMuted
            }
        }

        Repeater {
            model: panel.permissions

            delegate: Entry {
                id: permissionEntry

                required property var modelData
                readonly property var kind: panel.kind(modelData)

                icon: kind.icon
                title: kind.title

                Toggle {
                    checked: permissionEntry.modelData.state === WebEnginePermission.State.Granted
                    onToggled: panel.allow(permissionEntry.modelData, !checked)
                }
            }
        }

        RowLayout {
            Layout.leftMargin: 28
            Layout.bottomMargin: 8
            visible: panel.permissions.length > 0 || panel.needsReload
            spacing: 6

            TextButton {
                visible: panel.permissions.length > 0
                text: "Reset permissions"
                onClicked: panel.resetPermissions()
            }
            TextButton {
                visible: panel.needsReload
                primary: true
                text: "Reload"
                onClicked: {
                    panel.open = false
                    Browser.run("reload")
                }
            }
        }

        Separator {}

        Entry {
            icon: "cookie"
            title: "Cookies and site data"
            detail: panel.cookieCount === 0 ? "No cookies"
                  : panel.cookieCount === 1 ? "1 cookie" : panel.cookieCount + " cookies"

            TextButton {
                text: panel.confirmClear ? "Clear and reload" : "Clear"
                primary: panel.confirmClear
                onClicked: {
                    if (!panel.confirmClear) {
                        panel.confirmClear = true
                        return
                    }
                    Browser.clearSiteData(panel.view)
                    panel.open = false
                }
            }
        }

        Separator {}

        Entry {
            icon: "settings-2"
            title: "Site rules"
            detail: panel.rules || "None yet, add a siterule to your config"

            IconButton {
                Layout.rightMargin: -6
                implicitWidth: 28
                implicitHeight: 28
                iconSize: 16
                icon: "external-link"
                tip: "Open config"
                onClicked: {
                    panel.open = false
                    Qt.openUrlExternally(panel.fileUrl(Config.configFile))
                }
            }
        }
    }

    component Entry: RowLayout {
        id: entry

        property string icon
        property string title
        property string detail

        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: 2

            RowLayout {
                spacing: 12

                Icon {
                    name: entry.icon
                }
                UiText {
                    Layout.fillWidth: true
                    text: entry.title
                    elide: Text.ElideRight
                }
            }
            UiText {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                visible: text !== ""
                text: entry.detail
                color: Theme.muted
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
            }
        }
    }

    component Toggle: Rectangle {
        id: toggle

        property bool checked
        signal toggled()

        implicitWidth: 36
        implicitHeight: 20
        radius: Theme.radius > 0 ? height / 2 : 0
        color: checked ? Theme.accent : Theme.pressed

        Behavior on color { ColorAnimation { duration: Theme.duration } }

        Rectangle {
            x: toggle.checked ? toggle.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: Theme.radius > 0 ? height / 2 : 0
            color: toggle.checked ? Theme.background : Theme.muted

            Behavior on x { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.toggled()
        }
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.border
    }
}
