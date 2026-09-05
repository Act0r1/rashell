import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool busy: false
    property bool recording: false
    property bool stopping: false
    property string status: "Checking local tools…"
    property string error: ""
    property bool ocrAvailable: false
    property bool dictationAvailable: false
    property string ocrReason: "Checking local OCR tools…"
    property string dictationReason: "Checking local dictation tools…"
    property string modelPath: ""
    property bool canCancel: busy && !committing && !cancelling
    property bool committing: false
    property bool cancelling: false
    property bool terminalEvent: false
    property string pendingAction: ""
    property bool probePending: false
    readonly property string helperPath: Quickshell.shellDir + "/scripts/text-capture.py"

    signal failed(string message)
    signal completed(string message)

    function reject(message: string): void {
        error = message
        status = "Capture unavailable"
        failed(message)
    }

    function refreshAvailability(): void {
        if (probe.running || busy) return
        ocrAvailable = false
        dictationAvailable = false
        ocrReason = "Checking local OCR tools…"
        dictationReason = "Checking local dictation tools…"
        probePending = true
        probe.running = true
        probeStartupCheck.restart()
    }

    function probeFailed(): void {
        probePending = false
        ocrAvailable = false
        dictationAvailable = false
        modelPath = ""
        ocrReason = "Could not inspect local tools; check python3"
        dictationReason = ocrReason
        if (!busy) {
            status = ocrReason
            error = ocrReason
        }
    }

    function start(action: string): void {
        if (busy) return
        if (action === "ocr" && !ocrAvailable) { reject(ocrReason); return }
        if (action === "dictation" && !dictationAvailable) { reject(dictationReason); return }
        busy = true
        recording = false
        stopping = false
        committing = false
        cancelling = false
        terminalEvent = false
        error = ""
        status = action === "ocr" ? "Preparing area selection…" : "Starting microphone…"
        pendingAction = action
        launchDelay.restart()
    }

    function startOcr(): void { start("ocr") }
    function startDictation(): void { start("dictation") }

    function stopDictation(): void {
        if (!recording || stopping || cancelling) return
        stopping = true
        status = "Finishing microphone recording…"
        capture.write("stop\n")
    }

    function cancel(): void {
        if (!canCancel) return
        if (launchDelay.running) {
            launchDelay.stop()
            busy = false
            status = "Cancelled · clipboard unchanged"
            return
        }
        cancelling = true
        status = "Cancelling…"
        capture.write("cancel\n")
    }

    function receive(line: string): void {
        try {
            const event = JSON.parse(line)
            if (typeof event.event !== "string") return
            if (event.event === "ready-to-copy") {
                if (cancelling) {
                    capture.write("cancel\n")
                } else {
                    committing = true
                    status = "Copying recognized text…"
                    capture.write("commit\n")
                }
                return
            }
            status = String(event.message || "")
            if (event.event === "recording") recording = true
            if (["processing", "committing", "completed", "failed", "cancelled"].indexOf(event.event) >= 0) recording = false
            if (event.event === "committing") committing = true
            if (event.event === "completed") {
                terminalEvent = true
                completed(status)
            } else if (event.event === "failed") {
                terminalEvent = true
                error = status
                failed(error)
            } else if (event.event === "cancelled") {
                terminalEvent = true
            }
        } catch (parseError) {
            console.warn("Invalid local text capture status")
        }
    }

    Timer {
        id: launchDelay
        interval: 180
        onTriggered: {
            capture.exec({ command: ["python3", root.helperPath, root.pendingAction] })
            startupCheck.restart()
        }
    }

    Timer {
        id: startupCheck
        interval: 1500
        onTriggered: {
            if (root.busy && !capture.running) {
                root.busy = false
                root.recording = false
                root.reject("Could not start the local text capture helper")
            }
        }
    }

    Timer {
        id: probeStartupCheck
        interval: 1500
        onTriggered: {
            if (root.probePending && !probe.running) root.probeFailed()
        }
    }

    Process {
        id: probe
        command: ["python3", root.helperPath, "probe"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text)
                    if (typeof result.ocrAvailable !== "boolean" || typeof result.dictationAvailable !== "boolean"
                            || typeof result.ocrReason !== "string" || typeof result.dictationReason !== "string") {
                        throw new Error("Invalid capabilities")
                    }
                    root.probePending = false
                    root.ocrAvailable = result.ocrAvailable === true
                    root.dictationAvailable = result.dictationAvailable === true
                    root.ocrReason = String(result.ocrReason || "OCR unavailable")
                    root.dictationReason = String(result.dictationReason || "Dictation unavailable")
                    root.modelPath = String(result.modelPath || "")
                    if (!root.busy) {
                        root.status = "Ready for local text capture"
                        root.error = ""
                    }
                } catch (parseError) {
                    root.probeFailed()
                }
            }
        }
        onExited: function(exitCode) {
            probeStartupCheck.stop()
            if (exitCode !== 0 || root.probePending) root.probeFailed()
        }
    }

    Process {
        id: capture
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => root.receive(data)
        }
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            startupCheck.stop()
            root.busy = false
            root.recording = false
            root.stopping = false
            root.committing = false
            root.cancelling = false
            if (!root.terminalEvent) root.reject("Local text capture ended unexpectedly (" + exitCode + ")")
        }
    }

    Component.onCompleted: refreshAvailability()
}
