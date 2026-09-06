import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: state

    readonly property var baseIds: [1, 2, 3, 4, 5, 6]
    readonly property var workspaces: Hyprland.workspaces ? Hyprland.workspaces.values : []
    readonly property var ids: visibleWorkspaceIds()
    readonly property var monitors: Hyprland.monitors ? Hyprland.monitors.values : []
    readonly property bool available: monitors.length > 0

    signal attentionRequested(int workspaceId)

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "urgent" && event.name !== "openwindow") return
            const address = event.data.split(",")[0].replace(/^0x/, "")
            const toplevels = Hyprland.toplevels.values
            for (let index = 0; index < toplevels.length; index++) {
                const toplevel = toplevels[index]
                if (toplevel.address.replace(/^0x/, "") === address && toplevel.workspace) {
                    state.attentionRequested(toplevel.workspace.id)
                    return
                }
            }
        }
    }

    function visibleWorkspaceIds() {
        const result = baseIds.slice()
        for (let index = 0; index < workspaces.length; index++) {
            const workspaceId = Number(workspaces[index].id)
            if (workspaceId > 0 && result.indexOf(workspaceId) === -1) result.push(workspaceId)
        }
        result.sort((left, right) => left - right)
        return result
    }

    function monitor(outputName) {
        for (let index = 0; index < monitors.length; index++) {
            if (String(monitors[index].name) === String(outputName)) return monitors[index]
        }
        return null
    }

    function workspace(workspaceId) {
        for (let index = 0; index < workspaces.length; index++) {
            if (workspaces[index].id === workspaceId) return workspaces[index]
        }
        return null
    }

    function activeWorkspaceId(outputName) {
        const currentMonitor = monitor(outputName)
        return currentMonitor && currentMonitor.activeWorkspace ? currentMonitor.activeWorkspace.id : -1
    }

    function occupied(workspaceId) {
        const current = workspace(workspaceId)
        return current !== null && current.toplevels && current.toplevels.values.length > 0
    }

    function urgent(workspaceId) {
        const current = workspace(workspaceId)
        return current !== null && current.urgent
    }

    function activate(workspaceId) {
        if (!available || ids.indexOf(workspaceId) === -1) return false
        const command = "hl.dsp.focus({ workspace = \"" + workspaceId + "\" })"
        Quickshell.execDetached(["hyprctl", "dispatch", command])
        return true
    }
}
