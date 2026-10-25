import QtQuick
import QtQuick.Layouts
import QtWebEngine
import BrowserLand

IconButton {
    id: button

    readonly property var active: Browser.downloads.filter(download => download.state === WebEngineDownloadRequest.DownloadInProgress)
    readonly property real progress: {
        let received = 0
        let total = 0
        for (const download of active) {
            received += download.receivedBytes
            total += Math.max(download.totalBytes, download.receivedBytes)
        }
        return total > 0 ? received / total : 0
    }

    function size(bytes) {
        if (bytes < 1024)
            return bytes + " B"
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(0) + " KB"
        if (bytes < 1024 * 1024 * 1024)
            return (bytes / 1024 / 1024).toFixed(1) + " MB"
        return (bytes / 1024 / 1024 / 1024).toFixed(2) + " GB"
    }

    function status(download) {
        switch (download.state) {
        case WebEngineDownloadRequest.DownloadCompleted:
            return "Done, " + size(download.receivedBytes)
        case WebEngineDownloadRequest.DownloadCancelled:
            return "Cancelled"
        case WebEngineDownloadRequest.DownloadInterrupted:
            return "Failed: " + download.interruptReasonString
        }
        return size(download.receivedBytes) + (download.totalBytes > 0 ? " of " + size(download.totalBytes) : "")
    }

    function fileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    visible: Browser.downloads.length > 0
    icon: "download"
    tip: "Downloads"
    onClicked: panel.open = !panel.open

    property int lastCount: 0
    Connections {
        target: Browser
        function onDownloadsChanged() {
            if (Browser.downloads.length > button.lastCount)
                panel.open = true
            button.lastCount = Browser.downloads.length
        }
    }

    Rectangle {
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 4; bottomMargin: 3 }
        width: (parent.width - 8) * button.progress
        height: 2
        radius: 1
        visible: button.active.length > 0
        color: Theme.accent

        Behavior on width { NumberAnimation { duration: Theme.duration } }
    }

    Popover {
        id: panel
        anchorItem: button
        alignRight: true
        closeOnOutsideClick: true
        width: 360
        height: content.implicitHeight + 16

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4

                UiText {
                    Layout.fillWidth: true
                    text: "Downloads"
                    font.bold: true
                }
                TextButton {
                    text: "Open folder"
                    onClicked: Qt.openUrlExternally(button.fileUrl(Browser.downloadDir))
                }
                TextButton {
                    text: "Clear"
                    onClicked: Browser.clearDownloads()
                }
            }

            Repeater {
                model: Browser.downloads

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    readonly property bool done: modelData.state === WebEngineDownloadRequest.DownloadCompleted

                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Theme.radiusSmall
                    color: mouse.containsMouse && done ? Theme.hover : "transparent"

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (row.done) Qt.openUrlExternally(button.fileUrl(row.modelData.downloadDirectory + "/" + row.modelData.downloadFileName))
                    }

                    Column {
                        anchors { left: parent.left; leftMargin: 8; right: rowButton.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        spacing: 2

                        UiText {
                            width: parent.width
                            text: row.modelData.downloadFileName
                            elide: Text.ElideMiddle
                        }
                        UiText {
                            width: parent.width
                            text: button.status(row.modelData)
                            color: Theme.muted
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    IconButton {
                        id: rowButton
                        anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                        visible: !row.modelData.isFinished
                        implicitWidth: 24
                        implicitHeight: 24
                        icon: "x"
                        iconSize: 14
                        onClicked: row.modelData.cancel()
                    }
                }
            }
        }
    }
}
