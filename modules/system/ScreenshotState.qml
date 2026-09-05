import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool busy: false
    property bool recording: false
    property bool paused: false
    property bool selecting: false
    property string captureMode: "region"
    property string captureSelection: ""
    property string audioMode: "none"
    property string activeAction: ""
    property string targetOutput: ""
    property string pendingAction: ""
    property string pendingDirectory: ""
    property string pendingOutput: ""
    property string pendingCaptureMode: "region"
    property string pendingCaptureSelection: ""
    property string pendingAudioMode: "none"
    property string selectionOutputName: ""

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/screen-capture.sh"

    signal failed(string outputName, string message)

    function start(action, directory, outputName, requestedCaptureMode, requestedAudioMode, requestedCaptureSelection) {
        if (busy || selecting) return
        pendingAction = action
        pendingDirectory = directory
        pendingOutput = outputName
        pendingCaptureMode = requestedCaptureMode || "region"
        pendingCaptureSelection = requestedCaptureSelection || ""
        pendingAudioMode = requestedAudioMode || "none"
        launchDelay.restart()
    }

    function selectArea(mode, outputName) {
        if (busy || selecting || (mode !== "region" && mode !== "output")) return
        captureMode = mode
        captureSelection = ""
        selectionOutputName = outputName
        selecting = true
        selectionProcess.exec({
            command: [root.scriptPath, mode === "region" ? "select-region" : "select-output"]
        })
    }

    function pause() {
        if (!recording || paused || pauseProcess.running) return
        pauseProcess.exec({ command: [root.scriptPath, "pause"] })
    }

    function resume() {
        if (!recording || !paused || resumeProcess.running) return
        resumeProcess.exec({ command: [root.scriptPath, "resume"] })
    }

    function stop() {
        if (!recording || stopProcess.running) return
        stopProcess.exec({ command: [root.scriptPath, "stop"] })
    }

    Timer {
        id: launchDelay
        interval: 150
        repeat: false
        onTriggered: {
            root.activeAction = root.pendingAction
            root.targetOutput = root.pendingOutput
            root.busy = true
            root.recording = root.activeAction === "record"
            captureProcess.exec({
                command: [
                    root.scriptPath,
                    root.activeAction,
                    root.pendingDirectory,
                    root.pendingCaptureMode,
                    root.pendingAudioMode,
                    root.pendingCaptureSelection
                ]
            })
        }
    }

    Process {
        id: selectionProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function(exitCode) {
            root.selecting = false
            if (exitCode === 0) {
                root.captureSelection = String(selectionProcess.stdout.text || "").trim()
                return
            }
            if (exitCode !== 10 && exitCode !== 130) {
                const errorText = String(selectionProcess.stderr.text || "").trim()
                root.failed(root.selectionOutputName, errorText !== "" ? errorText : "AREA SELECTION FAILED")
            }
        }
    }

    Process {
        id: captureProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function(exitCode) {
            const action = root.activeAction
            const outputName = root.targetOutput
            const errorText = String(captureProcess.stderr.text || "").trim()
            root.busy = false
            root.recording = false
            root.paused = false
            root.activeAction = ""

            if (exitCode !== 0 && exitCode !== 10 && exitCode !== 130) {
                const fallback = action === "record" ? "VIDEO CAPTURE FAILED" : "SCREENSHOT FAILED"
                root.failed(outputName, errorText !== "" ? errorText : fallback)
            }
        }
    }

    Process {
        id: pauseProcess
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.paused = true
                return
            }
            const errorText = String(pauseProcess.stderr.text || "").trim()
            root.failed(root.targetOutput, errorText !== "" ? errorText : "COULD NOT PAUSE RECORDING")
        }
    }

    Process {
        id: resumeProcess
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.paused = false
                return
            }
            const errorText = String(resumeProcess.stderr.text || "").trim()
            root.failed(root.targetOutput, errorText !== "" ? errorText : "COULD NOT RESUME RECORDING")
        }
    }

    Process {
        id: stopProcess
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                const errorText = String(stopProcess.stderr.text || "").trim()
                root.failed(root.targetOutput, errorText !== "" ? errorText : "COULD NOT STOP RECORDING")
            }
        }
    }
}
