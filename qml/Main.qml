import QtQuick
import QtWebEngine
import BrowserLand

Window {
    id: window
    property url startUrl
    property int visibilityBeforeFullScreen: Window.Windowed
    
    title: Browser.current && Browser.current.title ? Browser.current.title + " - BrowserLand" : "BrowserLand"
    width: 1200
    height: 800
    visible: true
    color: Theme.background

    Item {
        id: pool
        visible: false
    }

    Instantiator {
        model: Config.binds
        delegate: Shortcut {
            sequence: modelData.sequence
            context: Qt.ApplicationShortcut
            onActivated: Browser.run(modelData.action, modelData.args)
        }
    }

    UserQml {
        id: userShell
        anchors.fill: parent
        source: Config.shellUrl
        label: "shell.qml"
        fill: true
    }

    Loader {
        anchors.fill: parent
        active: !userShell.item
        sourceComponent: Component {
            DefaultShell {}
        }
    }

    ErrorBanner {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        z: 100
    }


    Item {
        id: fullScreenHost

        property WebEngineView view: null

        anchors.fill: parent
        z: 50
        visible: !!view
    }

    Shortcut {
        sequence: "Esc"
        context: Qt.ApplicationShortcut
        enabled: !!Browser.fullScreenView && !contextMenu.open
        onActivated: Browser.exitFullScreen()
    }

    NotificationToast {
        anchors { right: parent.right; bottom: parent.bottom; margins: 16 }
        z: 95
    }

    ContextMenu {
        id: contextMenu
        anchors.fill: parent
        z: 97
    }

    Window {
        id: devTools
        title: "DevTools - BrowserLand"
        width: 1000
        height: 650

        WebEngineView {
            anchors.fill: parent
            inspectedView: devTools.visible ? Browser.current : null
        }
    }

    Connections {
        target: Browser
        function onDevToolsRequested() { devTools.visible = !devTools.visible }

        function onInspectRequested() {
            devTools.visible = true
            devTools.raise()
            Browser.current.triggerWebAction(WebEngineView.InspectElement)
        }

        function onFullScreenViewChanged() {
            const view = Browser.fullScreenView
            if (fullScreenHost.view && fullScreenHost.view.parent === fullScreenHost)
                Browser.park(fullScreenHost.view)
            fullScreenHost.view = view

            if (view) {
                window.visibilityBeforeFullScreen = window.visibility
                view.parent = fullScreenHost
                view.anchors.fill = fullScreenHost
                view.visible = true
                window.showFullScreen()
            } else if (window.visibility === Window.FullScreen) {
                window.visibility = window.visibilityBeforeFullScreen
            }
        }
    }

    onClosing: Browser.saveSession()

    Component.onCompleted: {
        Browser.pool = pool
        Browser.start(startUrl.toString())
    }
}