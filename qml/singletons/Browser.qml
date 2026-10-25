pragma Singleton

import QtQuick
import QtWebEngine
import BrowserLand


QtObject {
    id: browser

    property var tabs: []
    property int currentIndex: -1
    readonly property WebEngineView current: currentIndex >= 0 && currentIndex < tabs.length ? tabs[currentIndex] : null

    property Item pool: null

    signal focusUrlRequested()
    signal devToolsRequested()

    readonly property var actions: ({
        "new-tab": args => { browser.newTab(args || undefined); browser.focusUrlRequested() },
        "close-tab": () => browser.closeTab(browser.currentIndex),
        "next-tab": () => browser.selectTab((browser.currentIndex + 1) % browser.tabs.length),
        "prev-tab": () => browser.selectTab((browser.currentIndex - 1 + browser.tabs.length) % browser.tabs.length),

        "select-tab": args => browser.selectTab(parseInt(args) - 1),
        "open": args => browser.navigate(args),
        "focus-url": () => browser.focusUrlRequested(),
        "back": () => { if (browser.current) browser.current.goBack() },
        
        "forward": () => { if (browser.current) browser.current.goForward() },
        "reload": () => { if (browser.current) browser.current.reload() },
        "stop": () => { if (browser.current) browser.current.stop() },
        
        "zoom-in": () => browser.zoomBy(0.1),
        "zoom-out": () => browser.zoomBy(-0.1),
        "zoom-reset": () => { if (browser.current) browser.current.zoomFactor = 1 },
        "devtools": () => browser.devToolsRequested(),
        "reload-config": () => Config.reload(),
        "quit": () => Qt.quit()
    })

    readonly property var bindErrors: Array.from(Config.binds)
        .filter(bind => !(bind.action in actions))
        .map(bind => "bind " + bind.sequence + ": unknown action '" + bind.action + "'")

    property var qmlErrors: ({})

    readonly property var errors: Array.from(Config.errors)
        .concat(bindErrors, Object.keys(qmlErrors).map(key => qmlErrors[key]))

    function run(name, args) {
        const action = actions[name]
        if (!action) {
            console.warn("BrowserLand: unknown action '" + name + "'")
            return
        }
        action(args)
    }

    function newTab(url, background) {
        const view = tabComponent.createObject(pool)
        if (url !== null)
            view.url = toUrl(url === undefined ? Config.general.homepage : url)
        tabs = tabs.concat([view])

        if (!background)
            currentIndex = tabs.length - 1
        return view
    }

    function closeTab(index) {
        if (index < 0 || index >= tabs.length)
            return
        const view = tabs[index]
        const remaining = tabs.slice()
        remaining.splice(index, 1)

        if (remaining.length === 0) {

            tabs = remaining
            newTab()
        } else {

            const next = index < currentIndex ? currentIndex - 1 : Math.min(currentIndex, remaining.length - 1)
            tabs = remaining
            currentIndex = next
        }
        view.destroy()
    }

    function selectTab(index) {
        if (index >= 0 && index < tabs.length)
            currentIndex = index
    }


    function navigate(text) {
        if (current)
            current.url = toUrl(text)
        else
            newTab(text)
    }

    
    function toUrl(text) {
        const input = String(text).trim()
        if (input === "")
            return "about:blank"
        
        if (/^(localhost|\d+\.\d+\.\d+\.\d+)(:\d+)?(\/\S*)?$/.test(input))
            return "http://" + input
        if (/^[\w-]+(\.[\w-]+)+(:\d+)?(\/\S*)?$/.test(input))
            return "https://" + input
        if (/^[a-zA-Z][a-zA-Z0-9+.-]*:\S*$/.test(input))
            return input
        
        return Config.general.search_url.replace("{}", encodeURIComponent(input))
    }

    function zoomBy(step) {
        if (current)
            current.zoomFactor = Math.max(0.25, Math.min(5, current.zoomFactor + step))
    }

    function park(view) {
        view.visible = false
        view.anchors.fill = undefined
        view.parent = pool
    }

    function setQmlError(label, message) {

        const text = message ? label + ": " + message.replace(/\?v=\d+/g, "").replace(/file:\/\//g, "").replace(/\s*\n\s*/g, " ") : ""
        if ((qmlErrors[label] || "") === text)
            return
        const copy = Object.assign({}, qmlErrors)
        if (text)
            copy[label] = text
        else
            delete copy[label]
        qmlErrors = copy
    }

    property Component tabComponent: Component {
        WebEngineView {
            id: view
            visible: false

            onNewWindowRequested: request => {
                const background = request.destination === WebEngineNewWindowRequest.InNewBackgroundTab
                request.openIn(browser.newTab(null, background))
            }

            onWindowCloseRequested: browser.closeTab(browser.tabs.indexOf(view))
        }
    }
}