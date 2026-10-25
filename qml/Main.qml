import QtQuick
import QtWebEngine
import BrowserLand

Window {
    id: window
    property url startUrl
    
    title: Browser.current && Browser.current.title ? Browser.current.title + " - BrowserLand" : "BrowserLand"
    width: 1200
    height: 800
    visible: true
    color: Config.appearance.background

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
    }

    Component.onCompleted: {
        Browser.pool = pool
        Browser.newTab(startUrl.toString() !== "" ? startUrl.toString() : undefined)
    }
}