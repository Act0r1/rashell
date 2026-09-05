import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core

Scope {
    id: coordinator

    property string activePanelId: ""
    property Item anchorItem: null
    property string alignment: "center"
    property url contentSource: ""
    property var contentProperties: ({})
    property bool opened: false
    property bool transitioning: false
    property int transaction: 0
    property var anchorsByKey: ({})

    signal appearanceRequested(var screen)

    function key(panelId, outputName) {
        return panelId + "@" + outputName
    }

    function registerAnchor(panelId, outputName, item, itemAlignment) {
        const next = Object.assign({}, anchorsByKey)
        next[key(panelId, outputName)] = {
            item: item,
            alignment: itemAlignment
        }
        anchorsByKey = next
    }

    function unregisterAnchor(panelId, outputName, item) {
        const anchorKey = key(panelId, outputName)
        const current = anchorsByKey[anchorKey]
        if (!current || current.item !== item) return

        const next = Object.assign({}, anchorsByKey)
        delete next[anchorKey]
        anchorsByKey = next

        if (anchorItem === item) close("anchor-lost")
    }

    function preferredOutputName() {
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) return String(Hyprland.focusedMonitor.name)

        const monitors = Hyprland.monitors ? Hyprland.monitors.values.slice() : []
        monitors.sort(function(left, right) { return left.id - right.id })
        return monitors.length > 0 ? String(monitors[0].name) : ""
    }

    function registeredAnchor(panelId, outputName) {
        const requested = anchorsByKey[key(panelId, outputName)]
        if (requested && requested.item) return requested
        if (outputName !== "") return null

        const keys = Object.keys(anchorsByKey).sort()
        for (let index = 0; index < keys.length; index++) {
            const candidate = anchorsByKey[keys[index]]
            if (keys[index].indexOf(panelId + "@") === 0 && candidate && candidate.item) return candidate
        }
        return null
    }

    function toggleRegistered(panelId, source, properties) {
        const target = registeredAnchor(panelId, preferredOutputName())
        if (!target) return false
        toggle(panelId, target.item, target.alignment, source, properties)
        return true
    }

    function toggle(panelId, anchor, itemAlignment, source, properties) {
        if (opened && activePanelId === panelId && anchorItem === anchor) {
            close("trigger-toggle")
            return
        }

        open(panelId, anchor, itemAlignment, source, properties)
    }

    function open(panelId, anchor, itemAlignment, source, properties) {
        if (!anchor) return

        const token = ++transaction
        transitioning = true
        popup.visible = false
        opened = false
        activePanelId = panelId
        anchorItem = anchor
        alignment = itemAlignment || "center"
        contentSource = source
        contentProperties = properties || ({})
        contentLoader.source = ""
        contentLoader.setSource(source, contentProperties)

        Qt.callLater(function() {
            if (token !== coordinator.transaction) return
            transitioning = false
            opened = true
            popup.visible = true
            Qt.callLater(function() {
                if (contentLoader.item) contentLoader.item.forceActiveFocus()
            })
        })
    }

    function clearState() {
        opened = false
        activePanelId = ""
        anchorItem = null
        contentSource = ""
        contentProperties = ({})
        contentLoader.source = ""
    }

    function close(reason) {
        ++transaction
        transitioning = true
        popup.visible = false
        clearState()
        transitioning = false
    }

    function deferOutsideClear() {
        const token = ++transaction
        Qt.callLater(function() {
            if (token === coordinator.transaction && !popup.visible && coordinator.opened && !coordinator.transitioning) {
                coordinator.clearState()
            }
        })
    }

    PopupWindow {
        id: popup

        visible: false
        color: "transparent"
        grabFocus: true
        implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 1
        implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 1

        onVisibleChanged: {
            if (!visible && coordinator.opened && !coordinator.transitioning) coordinator.deferOutsideClear()
        }

        anchor {
            id: popupAnchor
            window: coordinator.anchorItem ? coordinator.anchorItem.QsWindow.window : null
            adjustment: PopupAdjustment.Slide
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            rect.width: 1
            rect.height: 1

            onAnchoring: {
                if (!coordinator.anchorItem) return
                const window = coordinator.anchorItem.QsWindow.window
                if (!window) return

                let localX = 0
                if (coordinator.alignment === "center") {
                    localX = coordinator.anchorItem.width / 2 - popup.implicitWidth / 2
                } else if (coordinator.alignment === "right") {
                    localX = coordinator.anchorItem.width - popup.implicitWidth
                }

                const point = window.contentItem.mapFromItem(
                    coordinator.anchorItem,
                    localX,
                    coordinator.anchorItem.height + Theme.panelGap
                )
                popupAnchor.rect.x = Math.round(point.x)
                popupAnchor.rect.y = Math.round(point.y)
            }
        }

        Loader {
            id: contentLoader
            anchors.fill: parent

            onStatusChanged: {
                if (status === Loader.Error) {
                    console.warn("Rashell panel failed:", coordinator.activePanelId, source)
                    coordinator.close("module-error")
                }
            }
        }
    }
}
