pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

Scope {
    id: root

    required property var coordinator
    property bool opened: false
    property var targetScreen: null
    property string mode: "apps"
    property var clipboardItems: []

    function toggle() {
        if (opened) close()
        else open()
    }

    function open() {
        coordinator.close("launcher")
        targetScreen = Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        mode = "apps"
        clipboardQuery.running = true
        opened = true
    }

    function close() {
        opened = false
    }

    function copyClipboard(id) {
        const numericId = Number(id)
        if (!Number.isInteger(numericId) || numericId < 0) return
        Quickshell.execDetached(["sh", "-c", "printf '%s' " + String(numericId) + " | cliphist decode | wl-copy"])
        close()
    }

    Process {
        id: clipboardQuery
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const next = []
                for (let index = 0; index < lines.length; index++) {
                    const separator = lines[index].indexOf("\t")
                    if (separator <= 0) continue
                    next.push({ id: lines[index].slice(0, separator), text: lines[index].slice(separator + 1) })
                }
                root.clipboardItems = next
            }
        }
    }

    PanelWindow {
        id: window
        screen: root.targetScreen
        visible: root.opened && root.targetScreen !== null
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "rashell-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.52)

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            width: Math.min(700, window.width - 48)
            height: Math.min(680, window.height - 120)
            anchors.centerIn: parent
            color: Theme.surface
            border.color: Theme.borderInteractive
            border.width: 1
            radius: 16

            MouseArea {
                anchors.fill: parent
                onClicked: event => event.accepted = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                TextField {
                    id: search
                    width: parent.width
                    height: 48
                    placeholderText: "Search applications…"
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.textOnAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    focus: root.opened

                    background: Rectangle {
                        color: Theme.surfaceRaised
                        border.color: search.activeFocus ? Theme.accent : Theme.border
                        border.width: 1
                        radius: Theme.radius
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            results.currentIndex = Math.min(results.count - 1, results.currentIndex + 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            results.currentIndex = Math.max(0, results.currentIndex - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (results.currentItem) results.currentItem.launch()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            root.close()
                            event.accepted = true
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8
                    Button {
                        width: 120
                        height: 30
                        text: "Applications"
                        onClicked: root.mode = "apps"
                        background: Rectangle { color: root.mode === "apps" ? Theme.accent : Theme.surfaceRaised; radius: Theme.radius }
                        contentItem: Text { text: parent.text; color: root.mode === "apps" ? Theme.textOnAccent : Theme.text; font.family: Theme.fontFamily; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Button {
                        width: 120
                        height: 30
                        text: "Clipboard"
                        onClicked: root.mode = "clipboard"
                        background: Rectangle { color: root.mode === "clipboard" ? Theme.accent : Theme.surfaceRaised; radius: Theme.radius }
                        contentItem: Text { text: parent.text; color: root.mode === "clipboard" ? Theme.textOnAccent : Theme.text; font.family: Theme.fontFamily; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }

                Text {
                    text: root.mode === "apps" ? (search.text === "" ? "APPLICATIONS" : "RESULTS") : "CLIPBOARD HISTORY"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }

                ListView {
                    id: results
                    width: parent.width
                    height: parent.height - search.height - 82
                    spacing: 4
                    clip: true
                    currentIndex: count > 0 ? 0 : -1
                    model: {
                        const query = search.text.trim().toLowerCase()
                        if (root.mode === "clipboard") {
                            return root.clipboardItems.filter(function(item) {
                                return query === "" || item.text.toLowerCase().indexOf(query) !== -1
                            }).slice(0, 40).map(function(item) {
                                return { kind: "clipboard", id: item.id, name: item.text, comment: "Copy to clipboard", icon: "edit-copy" }
                            })
                        }
                        const all = DesktopEntries.applications ? DesktopEntries.applications.values : []
                        return all.filter(function(entry) {
                            if (!entry || entry.noDisplay || entry.hidden) return false
                            if (query === "") return true
                            return String(entry.name || "").toLowerCase().indexOf(query) !== -1
                                || String(entry.comment || "").toLowerCase().indexOf(query) !== -1
                                || String(entry.keywords || "").toLowerCase().indexOf(query) !== -1
                        }).slice(0, 40).map(function(entry) {
                            return { kind: "app", entry: entry, name: entry.name, comment: entry.comment || entry.id, icon: entry.icon }
                        })
                    }

                    delegate: ItemDelegate {
                        id: appDelegate
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 52
                        hoverEnabled: true
                        highlighted: ListView.isCurrentItem

                        function launch() {
                            if (appDelegate.modelData.kind === "clipboard") root.copyClipboard(appDelegate.modelData.id)
                            else appDelegate.modelData.entry.execute()
                            root.close()
                        }

                        contentItem: Row {
                            spacing: 12
                            Image {
                                width: 30
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter
                                source: Quickshell.iconPath(appDelegate.modelData.icon)
                                fillMode: Image.PreserveAspectFit
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 42
                                Text {
                                    width: parent.width
                                    text: appDelegate.modelData.name
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.bold: true
                                }
                                Text {
                                    width: parent.width
                                    text: appDelegate.modelData.comment
                                    color: Theme.textMuted
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                }
                            }
                        }

                        background: Rectangle {
                            color: appDelegate.highlighted || appDelegate.hovered ? Theme.surfaceRaised : "transparent"
                            border.color: appDelegate.highlighted ? Theme.accent : "transparent"
                            border.width: 1
                            radius: Theme.radius
                        }
                        onHoveredChanged: if (hovered) results.currentIndex = index
                        onClicked: launch()
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                search.text = ""
                Qt.callLater(function() { search.forceActiveFocus() })
            }
        }
    }
}
