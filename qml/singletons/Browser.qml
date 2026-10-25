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
    property bool started: false

    property WebEngineProfile profile: null
    readonly property string downloadDir: System.downloadDir(Config.general.download_dir || "")
    property var downloads: []
    property var closedTabs: []
    property var permissionRequests: []
    property WebEngineView fullScreenView: null
    property var findResult: ({ numberOfMatches: 0, activeMatch: 0 })

    signal focusUrlRequested()
    signal devToolsRequested()
    signal findRequested()
    signal notificationPresented(var notification)

    readonly property var actions: ({
        "new-tab": args => { browser.newTab(args || undefined); if (!args) browser.focusUrlRequested() },
        "close-tab": () => browser.closeTab(browser.currentIndex),
        "reopen-closed-tab": () => browser.reopenClosedTab(),
        "next-tab": () => browser.selectTab((browser.currentIndex + 1) % browser.tabs.length),
        "prev-tab": () => browser.selectTab((browser.currentIndex - 1 + browser.tabs.length) % browser.tabs.length),

        "select-tab": args => browser.selectTab(parseInt(args) - 1),
        "open": args => browser.navigate(args),
        "focus-url": () => browser.focusUrlRequested(),
        "find": () => browser.findRequested(),
        "back": () => { if (browser.current) browser.current.goBack() },

        "forward": () => { if (browser.current) browser.current.goForward() },
        "reload": () => { if (browser.current) browser.current.reload() },
        "stop": () => { if (browser.current) browser.current.stop() },

        "zoom-in": () => browser.zoomBy(0.1),
        "zoom-out": () => browser.zoomBy(-0.1),
        "zoom-reset": () => { if (browser.current) browser.current.zoomFactor = 1 },
        "devtools": () => browser.devToolsRequested(),
        "exec": args => System.exec(args || ""),
        "clear-history": () => History.clear(),
        "reload-config": () => Config.reload(),
        "quit": () => { browser.saveSession(); Qt.quit() }
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
            return false
        }
        action(args)
        return true
    }

    function start(url) {
        if (Config.general.restore_session !== false)
            restoreSession()
        if (url || tabs.length === 0)
            newTab(url || undefined)
        started = true
    }

    function newTab(url, background, index) {
        const view = tabComponent.createObject(pool)
        if (url !== null)
            view.url = toUrl(url === undefined ? Config.general.homepage : url)
        insertTab(view, index, background)
        return view
    }

    function insertTab(view, index, background) {
        const at = index === undefined ? tabs.length : Math.max(0, Math.min(index, tabs.length))
        const next = tabs.slice()
        next.splice(at, 0, view)
        const shifted = currentIndex >= at
        tabs = next

        if (!background)
            currentIndex = at
        else if (shifted)
            currentIndex++
    }

    function closeTab(index) {
        if (index < 0 || index >= tabs.length)
            return
        const view = tabs[index]
        const remaining = tabs.slice()
        remaining.splice(index, 1)

        if (view === fullScreenView)
            fullScreenView = null
        for (const request of permissionRequests.filter(r => r.view === view))
            request.permission.deny()
        permissionRequests = permissionRequests.filter(r => r.view !== view)

        const url = view.pendingUrl || view.url.toString()
        if (url !== "")
            closedTabs = closedTabs.concat([{ url, index }]).slice(-25)

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

    function reopenClosedTab() {
        const last = closedTabs[closedTabs.length - 1]
        if (!last)
            return
        closedTabs = closedTabs.slice(0, -1)
        newTab(last.url, false, last.index)
    }

    function selectTab(index) {
        if (index >= 0 && index < tabs.length)
            currentIndex = index
    }

    // restored tabs only start loading once you look at them
    function loadPending() {
        if (current && current.pendingUrl !== "") {
            current.url = current.pendingUrl
            current.pendingUrl = ""
        }
    }

    onCurrentChanged: {
        if (fullScreenView && fullScreenView !== current) {
            fullScreenView.triggerWebAction(WebEngineView.ExitFullScreen)
            fullScreenView = null
        }
        findResult = { numberOfMatches: 0, activeMatch: 0 }
        Qt.callLater(loadPending)
    }

    onTabsChanged: scheduleSave()
    onCurrentIndexChanged: scheduleSave()

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

        const space = input.indexOf(" ")
        if (space > 0 && Config.search) {
            const engine = Config.search[input.slice(0, space)]
            if (typeof engine === "string" && engine.includes("{}"))
                return engine.replace("{}", encodeURIComponent(input.slice(space + 1).trim()))
        }

        if (/^(localhost|\d+\.\d+\.\d+\.\d+)(:\d+)?(\/\S*)?$/.test(input))
            return "http://" + input
        if (/^[\w-]+(\.[\w-]+)+(:\d+)?(\/\S*)?$/.test(input))
            return "https://" + input
        if (/^[a-zA-Z][a-zA-Z0-9+.-]*:\S*$/.test(input))
            return input

        return Config.general.search_url.replace("{}", encodeURIComponent(input))
    }

    function hostOf(url) {
        const match = String(url).match(/^[a-z][a-z0-9+.-]*:\/\/(?:[^@\/?#]*@)?(\[[^\]]*\]|[^:\/?#]*)/i)
        return match ? match[1].toLowerCase() : ""
    }

    function siteRules(url, rule) {
        const host = hostOf(url)
        return Array.from(Config.siteRules).filter(r => r.rule === rule && new RegExp(r.host).test(host))
    }

    function applyUserScripts() {
        if (!profile)
            return
        profile.userScripts.clear()

        for (const rule of Array.from(Config.siteRules)) {
            if (rule.rule !== "css" && rule.rule !== "js")
                continue
            const host = JSON.stringify(rule.host)
            const script = WebEngine.script()
            script.name = rule.rule + " " + rule.site + " " + rule.file
            script.runsOnSubFrames = false

            if (rule.rule === "css") {
                // a constructed sheet isn't blocked by the page's Content-Security-Policy like a <style> would be
                script.injectionPoint = WebEngineScript.DocumentCreation
                script.worldId = WebEngineScript.ApplicationWorld
                script.sourceCode = `(function () {
    if (!new RegExp(${host}).test(location.hostname)) return;
    const sheet = new CSSStyleSheet();
    sheet.replaceSync(${JSON.stringify(rule.source)});
    document.adoptedStyleSheets = document.adoptedStyleSheets.concat([sheet]);
})();`
            } else {
                script.injectionPoint = WebEngineScript.DocumentReady
                script.worldId = WebEngineScript.MainWorld
                script.sourceCode = `(function () {
    if (!new RegExp(${host}).test(location.hostname)) return;
${rule.source}
})();`
            }
            profile.userScripts.insert(script)
        }
    }

    function zoomBy(step) {
        if (current)
            current.zoomFactor = Math.max(0.25, Math.min(5, current.zoomFactor + step))
    }

    function find(text, backward) {
        if (!current)
            return
        if (text === "")
            findResult = { numberOfMatches: 0, activeMatch: 0 }
        current.findText(text, backward ? WebEngineView.FindBackward : 0)
    }

    function exitFullScreen() {
        if (fullScreenView)
            fullScreenView.triggerWebAction(WebEngineView.ExitFullScreen)
    }

    function permissionNames(type) {
        switch (type) {
        case WebEnginePermission.PermissionType.MediaAudioCapture: return ["microphone"]
        case WebEnginePermission.PermissionType.MediaVideoCapture: return ["camera"]
        case WebEnginePermission.PermissionType.MediaAudioVideoCapture: return ["camera", "microphone"]
        case WebEnginePermission.PermissionType.DesktopVideoCapture:
        case WebEnginePermission.PermissionType.DesktopAudioVideoCapture: return ["screen"]
        case WebEnginePermission.PermissionType.MouseLock: return ["mouse_lock"]
        case WebEnginePermission.PermissionType.Notifications: return ["notifications"]
        case WebEnginePermission.PermissionType.Geolocation: return ["location"]
        case WebEnginePermission.PermissionType.ClipboardReadWrite: return ["clipboard"]
        case WebEnginePermission.PermissionType.LocalFontsAccess: return ["fonts"]
        }
        return []
    }

    function permissionText(names) {
        const phrases = {
            camera: "use your camera",
            microphone: "use your microphone",
            screen: "share your screen",
            mouse_lock: "lock your mouse pointer",
            notifications: "show notifications",
            location: "know your location",
            clipboard: "use your clipboard",
            fonts: "see your installed fonts"
        }
        if (names.length === 2 && names[0] === "camera" && names[1] === "microphone")
            return "use your camera and microphone"
        return names.map(name => phrases[name]).join(" and ")
    }

    function permissionPolicy(names) {
        const section = Config.permissions
        const setting = name => section && typeof section[name] === "string" ? section[name] : ""
        const fallback = setting("default") || "ask"
        const policies = names.map(name => setting(name) || fallback)

        if (policies.length === 0 || policies.includes("deny"))
            return "deny"
        return policies.every(policy => policy === "allow") ? "allow" : "ask"
    }

    function requestPermission(view, permission) {
        const names = permissionNames(permission.permissionType)
        const policy = permissionPolicy(names)
        if (policy === "allow") {
            permission.grant()
        } else if (policy === "deny") {
            permission.deny()
        } else {
            permissionRequests = permissionRequests.concat([{
                view,
                permission,
                what: permissionText(names),
                site: hostOf(permission.origin) || permission.origin.toString()
            }])
        }
    }

    function answerPermission(request, allow) {
        if (allow)
            request.permission.grant()
        else
            request.permission.deny()
        permissionRequests = permissionRequests.filter(r => r !== request)
    }

    function clearDownloads() {
        downloads = downloads.filter(download => !download.isFinished)
    }

    property Timer saveTimer: Timer {
        interval: 1000
        onTriggered: browser.saveSession()
    }

    function scheduleSave() {
        if (started)
            saveTimer.restart()
    }

    function saveSession() {
        if (!started)
            return
        saveTimer.stop()
        System.writeJson("session.json", {
            current: currentIndex,
            tabs: tabs.map(view => ({
                url: view.pendingUrl || view.url.toString(),
                title: view.title || view.pendingTitle
            }))
        })
    }

    function restoreSession() {
        const session = System.readJson("session.json")
        if (!session || !session.tabs)
            return

        const restored = []
        for (const tab of Array.from(session.tabs)) {
            if (tab && tab.url)
                restored.push(tabComponent.createObject(pool, { pendingUrl: tab.url, pendingTitle: tab.title || "" }))
        }
        if (restored.length === 0)
            return
        tabs = tabs.concat(restored)
        currentIndex = Math.max(0, Math.min(Number(session.current) || 0, tabs.length - 1))
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

    property WebEngineProfilePrototype profilePrototype: WebEngineProfilePrototype {
        storageName: "default"
        persistentStoragePath: System.dataDir + "/profile"
        persistentPermissionsPolicy: WebEngineProfile.PersistentPermissionsPolicy.StoreInMemory
    }

    onDownloadDirChanged: if (profile) profile.downloadPath = downloadDir

    Component.onCompleted: {
        profile = profilePrototype.instance()
        profile.downloadPath = downloadDir
        applyUserScripts()
    }

    property Connections profileConnections: Connections {
        target: browser.profile

        function onDownloadRequested(download) {
            download.accept()
            browser.downloads = [download].concat(browser.downloads)
        }

        function onPresentNotification(notification) {
            browser.notificationPresented(notification)
        }
    }

    property Connections configConnections: Connections {
        target: Config

        function onReloaded() {
            browser.applyUserScripts()
            for (const view of browser.tabs)
                view.applySiteZoom(true)
        }
    }

    property Component tabComponent: Component {
        WebEngineView {
            id: view

            property string pendingUrl: ""
            property string pendingTitle: ""
            property string ruleHost: ""
            property real ruleZoom: 0

            function applySiteZoom(force) {
                const host = browser.hostOf(url)
                if (host === ruleHost && !force)
                    return
                ruleHost = host

                const rules = browser.siteRules(url, "zoom")
                const zoom = rules.length > 0 ? rules[rules.length - 1].zoom : 0
                if (zoom > 0)
                    zoomFactor = zoom
                else if (ruleZoom > 0)
                    zoomFactor = 1
                ruleZoom = zoom
            }

            visible: false
            profile: browser.profile
            settings.fullScreenSupportEnabled: true

            onUrlChanged: {
                applySiteZoom(false)
                browser.scheduleSave()
            }
            onTitleChanged: browser.scheduleSave()

            onLoadingChanged: info => {
                if (info.status === WebEngineLoadingInfo.LoadSucceededStatus)
                    History.add(info.url, view.title)
            }

            onFindTextFinished: result => {
                if (view === browser.current)
                    browser.findResult = { numberOfMatches: result.numberOfMatches, activeMatch: result.activeMatch }
            }

            onFullScreenRequested: request => {
                request.accept()
                browser.fullScreenView = request.toggleOn ? view : null
            }

            onPermissionRequested: permission => browser.requestPermission(view, permission)

            onNewWindowRequested: request => {
                const background = request.destination === WebEngineNewWindowRequest.InNewBackgroundTab
                request.openIn(browser.newTab(null, background))
            }

            onWindowCloseRequested: browser.closeTab(browser.tabs.indexOf(view))
        }
    }
}
