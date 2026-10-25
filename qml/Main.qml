import QtQuick
import QtWebEngine
import BrowserLand

Window {
    id: window
    property url startUrl: Config.general.homepage

    title: 'BrowserLand'
    width: 1200
    height: 800
    visible: true
    color: Config.appearance.background

    Rectangle {
        id: accentBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 4
        color: Config.appearance.accent
    }

    ErrorBanner {
        id: errorBanner
        anchors { top: accentBar.bottom; left: parent.left; right: parent.right }
    }


    WebEngineView {
        anchors { top: errorBanner.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        Component.onCompleted: url = window.startUrl
    }
    
}