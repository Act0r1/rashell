import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

Scope {
    id: state

    readonly property var baseIds: [1, 2, 3, 4, 5, 6]
    readonly property var workspaces: Hyprland.workspaces ? Hyprland.workspaces.values : []
    readonly property var ids: visibleWorkspaceIds()
    readonly property var monitors: Hyprland.monitors ? Hyprland.monitors.values : []
    readonly property bool available: monitors.length > 0
    readonly property var audioStreams: (Pipewire.nodes ? Pipewire.nodes.values : [])
        .filter(node => node && node.isStream && node.audio && (node.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream)
    property var mutedIds: []
    property var managedStreams: []
    property var unmutedIds: []
    property bool audioSyncDirty: false

    signal attentionRequested(int workspaceId)

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindowv2"].indexOf(event.name) !== -1) state.scheduleAudioSync()
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
            if (event.name === "openwindow") state.refreshHyprland()
        }
    }

    function refreshHyprland() {
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
    }

    Timer {
        running: true
        interval: 1500
        onTriggered: state.refreshHyprland()
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

    function muted(workspaceId) {
        return mutedIds.indexOf(workspaceId) !== -1
    }

    function toggleMute(workspaceId) {
        if (muted(workspaceId)) {
            mutedIds = mutedIds.filter(id => id !== workspaceId)
            unmutedIds = unmutedIds.concat([workspaceId])
        } else {
            mutedIds = mutedIds.concat([workspaceId])
        }
        scheduleAudioSync()
    }

    function scheduleAudioSync() {
        if (mutedIds.length > 0 || managedStreams.length > 0 || unmutedIds.length > 0) audioSyncTimer.restart()
    }

    function runAudioSync() {
        if (audioProcess.running) {
            audioSyncDirty = true
            return
        }
        audioSyncDirty = false
        audioProcess.command = ["python3", Quickshell.shellDir + "/scripts/workspace-audio.py"]
        audioProcess.running = true
    }

    function applyAudioMute(owners) {
        const managed = []
        for (let index = 0; index < audioStreams.length; index++) {
            const node = audioStreams[index]
            const workspaceIds = owners[String(node.id)] || []
            const shouldMute = workspaceIds.some(id => muted(id))
            const ours = managedStreams.indexOf(node.id) !== -1
            const released = workspaceIds.some(id => unmutedIds.indexOf(id) !== -1)
            if (shouldMute && (ours || !node.audio.muted)) {
                node.audio.muted = true
                managed.push(node.id)
            } else if (!shouldMute && (ours || released)) {
                node.audio.muted = false
            }
        }
        managedStreams = managed
        unmutedIds = []
    }

    onAudioStreamsChanged: scheduleAudioSync()

    Timer {
        id: audioSyncTimer
        interval: 150
        onTriggered: state.runAudioSync()
    }

    Process {
        id: audioProcess
        stdout: StdioCollector {
            id: audioOutput
        }
        stderr: StdioCollector {
            id: audioErrors
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) state.applyAudioMute(JSON.parse(audioOutput.text))
            else console.warn("Workspace audio sync failed: exit " + exitCode + ": " + audioErrors.text.trim())
            if (state.audioSyncDirty) audioSyncTimer.restart()
        }
    }

    PwObjectTracker {
        objects: state.audioStreams
    }
}
