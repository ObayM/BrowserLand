pragma Singleton

import QtQuick
import BrowserLand

QtObject {
    id: bookmarks

    property var items: []

    function indexOf(url) {
        const key = String(url)
        return items.findIndex(item => item.url === key)
    }

    function has(url) {
        return indexOf(url) >= 0
    }

    function add(url, title, icon) {
        const key = String(url)
        if (key === "" || has(key))
            return
        items = items.concat([{ url: key, title: title || "", icon: String(icon || "") }])
        save()
    }

    function remove(url) {
        items = items.filter(item => item.url !== String(url))
        save()
    }

    function rename(url, title) {
        items = items.map(item => item.url === String(url) ? Object.assign({}, item, { title }) : item)
        save()
    }

    function refresh(url, title, icon) {
        const index = indexOf(url)
        if (index < 0)
            return
        
        const item = items[index]
        const next = { url: item.url, title: item.title || title || "", icon: String(icon || "") || item.icon }
        
        if (next.title === item.title && next.icon === item.icon)
            return
        
        const copy = items.slice()
        copy[index] = next
        items = copy
        save()
    }

    function search(text, limit) {
        const words = text.toLowerCase().split(/\s+/).filter(word => word !== "")
        if (words.length === 0)
            return []
        
        return items
            .filter(item => words.every(word => (item.url + " " + item.title).toLowerCase().includes(word)))
            .slice(0, limit)
            .map(item => ({ url: item.url, title: item.title, bookmark: true }))
    }

    function save() {
        System.writeJson("bookmarks.json", items)
    }

    function move (from, to) {
        if (from == to || from < 0 || from >= items.length || to >= items.length)
            return

        const copy = items.slice()
        copy.slice(to, 0, copy.splice(from, 1)[0])
        items = copy
        save()
    }

    Component.onCompleted: {
        const saved = System.readJson("bookmarks.json")
        if (saved)
            items = Array.from(saved)
                .filter(item => item && item.url)
                .map(item => ({ url: String(item.url), title: String(item.title || ""), icon: String(item.icon || "") }))
    }
}
