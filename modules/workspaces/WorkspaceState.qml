import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: state

    readonly property var ids: [1, 2, 3, 4, 5, 6]
    readonly property var workspaces: Hyprland.workspaces ? Hyprland.workspaces.values : []
    readonly property var monitors: Hyprland.monitors ? Hyprland.monitors.values : []
    readonly property bool available: monitors.length > 0

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

    function activate(workspaceId) {
        if (!available || ids.indexOf(workspaceId) === -1) return false
        const command = "hl.dsp.focus({ workspace = \"" + workspaceId + "\" })"
        Quickshell.execDetached(["hyprctl", "dispatch", command])
        return true
    }
}
