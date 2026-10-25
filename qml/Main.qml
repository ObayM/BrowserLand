import QtQuick
import QtWebEngine

Window {
    width: 1200
    height: 800
    visible: true

    title: 'BrowserLand'

    WebEngineView {
        anchors.fill: parent
        url: "https://obayy.dev"
    }
    
}