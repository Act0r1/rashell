import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Scope {
    id: state

    property bool everReady: false
    readonly property bool ready: Pipewire.ready
    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var output: Pipewire.defaultAudioSink
    readonly property var input: Pipewire.defaultAudioSource

    readonly property var deviceNodes: {
        const result = []
        for (let index = 0; index < nodes.length; index++) {
            const node = nodes[index]
            if (!node || node.isStream || !node.audio) continue
            if ((node.type & PwNodeType.Sink) !== 0 || (node.type & PwNodeType.Source) !== 0) result.push(node)
        }
        return result
    }

    readonly property var outputs: {
        const result = []
        for (let index = 0; index < deviceNodes.length; index++) {
            const node = deviceNodes[index]
            if ((node.type & PwNodeType.Sink) !== 0) result.push(node)
        }
        return result
    }

    readonly property var inputs: {
        const result = []
        for (let index = 0; index < deviceNodes.length; index++) {
            const node = deviceNodes[index]
            if ((node.type & PwNodeType.Source) !== 0) result.push(node)
        }
        return result
    }

    readonly property bool outputUsable: output !== null && output.ready && output.audio
    readonly property bool inputUsable: input !== null && input.ready && input.audio
    readonly property string availability: outputUsable ? "ready" : "loading"
    readonly property real outputVolume: outputUsable ? output.audio.volume : 0
    readonly property bool outputMuted: outputUsable ? output.audio.muted : false
    readonly property real inputVolume: inputUsable ? input.audio.volume : 0
    readonly property bool inputMuted: inputUsable ? input.audio.muted : false

    property string pendingKind: ""
    property string pendingOrigin: ""
    property real pendingValue: 0
    signal directOutputChangeObserved(string outputName)

    function clampVolume(value) {
        return Math.max(0, Math.min(1.5, Number(value)))
    }

    function nodeLabel(node) {
        if (!node) return "Unavailable"
        return String(node.nickname || node.description || node.name || "Unknown device")
    }

    function setOutputVolume(value) {
        if (!outputUsable) return false
        output.audio.volume = clampVolume(value)
        return true
    }

    function adjustOutput(delta) {
        return setOutputVolume(outputVolume + Number(delta))
    }

    function adjustOutputDirect(delta, outputName) {
        if (!outputUsable || !isFinite(delta)) return false
        const target = clampVolume(outputVolume + Number(delta))
        if (Math.abs(target - outputVolume) < 0.0001) return true
        pendingKind = "volume"
        pendingOrigin = outputName
        pendingValue = target
        pendingTimeout.restart()
        return setOutputVolume(target)
    }

    function toggleOutputMute() {
        if (!outputUsable) return false
        output.audio.muted = !output.audio.muted
        return true
    }

    function toggleOutputMuteDirect(outputName) {
        if (!outputUsable) return false
        pendingKind = "mute"
        pendingOrigin = outputName
        pendingValue = outputMuted ? 0 : 1
        pendingTimeout.restart()
        return toggleOutputMute()
    }

    function selectOutput(node) {
        if (!node || outputs.indexOf(node) === -1) return false
        Pipewire.preferredDefaultAudioSink = node
        return true
    }

    function setInputVolume(value) {
        if (!inputUsable) return false
        input.audio.volume = clampVolume(value)
        return true
    }

    function toggleInputMute() {
        if (!inputUsable) return false
        input.audio.muted = !input.audio.muted
        return true
    }

    function selectInput(node) {
        if (!node || inputs.indexOf(node) === -1) return false
        Pipewire.preferredDefaultAudioSource = node
        return true
    }

    function clearPendingDirect() {
        pendingKind = ""
        pendingOrigin = ""
        pendingValue = 0
    }

    function completeDirectVolume() {
        if (pendingKind !== "volume" || Math.abs(outputVolume - pendingValue) > 0.011) return
        const origin = pendingOrigin
        clearPendingDirect()
        directOutputChangeObserved(origin)
    }

    function completeDirectMute() {
        if (pendingKind !== "mute" || (outputMuted ? 1 : 0) !== pendingValue) return
        const origin = pendingOrigin
        clearPendingDirect()
        directOutputChangeObserved(origin)
    }

    onReadyChanged: {
        if (ready) everReady = true
        else clearPendingDirect()
    }
    onOutputChanged: clearPendingDirect()

    Timer {
        id: pendingTimeout
        interval: 600
        onTriggered: state.clearPendingDirect()
    }

    Connections {
        target: state.outputUsable ? state.output.audio : null
        function onVolumesChanged() { state.completeDirectVolume() }
        function onMutedChanged() { state.completeDirectMute() }
    }

    PwObjectTracker {
        objects: state.deviceNodes
    }
}
