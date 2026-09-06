import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string url: ""
    property bool available: false
    property bool checking: false
    property bool busy: false
    property bool cancelling: false
    property bool copying: false
    property bool terminalEvent: false
    property bool copied: false
    property real progress: -1
    property string status: "Checking tools…"
    property string details: ""
    property string error: ""
    property string savedPath: ""
    property string savedKind: ""
    property string title: ""
    readonly property string helperPath: Quickshell.shellDir + "/scripts/media-download.py"
    readonly property string savedUrl: fileUrl(savedPath)
    readonly property bool canStart: available && !busy && /^https?:\/\/\S+$/i.test(url.trim())
    readonly property bool canCancel: busy && !cancelling && !copying

    signal failed(string message)
    signal completed(string message)

    function fileUrl(path: string): string {
        return path === "" ? "" : "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    function bytesLabel(value: real): string {
        if (value >= 1048576) return (value / 1048576).toFixed(1) + " MB"
        if (value >= 1024) return Math.round(value / 1024) + " KB"
        return Math.round(value) + " B"
    }

    function reject(message: string): void {
        error = message
        status = savedPath !== "" ? "Saved, but not copied" : "Download failed"
        failed(message)
    }

    function refreshAvailability(): void {
        if (busy || checking) return
        checking = true
        probe.running = true
        probeStartup.restart()
    }

    function run(command: string, value: string): void {
        busy = true
        cancelling = false
        copying = command === "copy"
        terminalEvent = false
        copied = false
        progress = -1
        error = ""
        details = ""
        status = copying ? "Copying to clipboard…" : "Fetching media…"
        worker.exec({ command: ["python3", helperPath, command, value] })
        startup.restart()
    }

    function start(): void {
        if (!canStart) return
        savedPath = ""
        savedKind = ""
        title = ""
        run("download", url.trim())
    }

    function copySaved(): void {
        if (!busy && savedPath !== "") run("copy", savedPath)
    }

    function openFolder(): void {
        if (savedPath !== "") Qt.openUrlExternally(fileUrl(savedPath.slice(0, savedPath.lastIndexOf("/"))))
    }

    function cancel(): void {
        if (!canCancel) return
        cancelling = true
        status = "Cancelling download…"
        worker.write("cancel\n")
    }

    function receive(line: string): void {
        let event
        try { event = JSON.parse(line) } catch (parseError) { return }
        if (typeof event.event !== "string") return
        if (typeof event.path === "string" && event.path !== "") {
            savedPath = event.path
            if (title === "") title = savedPath.slice(savedPath.lastIndexOf("/") + 1)
        }
        if (typeof event.kind === "string") savedKind = event.kind
        if (typeof event.title === "string" && event.title !== "") title = event.title
        if (event.event === "metadata") details = title
        if (event.event === "progress" && !cancelling) {
            progress = typeof event.percent === "number" ? Math.max(0, Math.min(100, event.percent)) : -1
            status = progress >= 100 ? "Processing file…" : "Downloading…"
            const parts = []
            if (typeof event.downloaded_bytes === "number") parts.push(bytesLabel(event.downloaded_bytes))
            if (typeof event.speed_bytes_per_second === "number") parts.push(bytesLabel(event.speed_bytes_per_second) + "/s")
            if (typeof event.eta_seconds === "number") parts.push("About " + Math.ceil(event.eta_seconds) + " s remaining")
            details = parts.join("  ·  ")
        } else if (event.event === "processing" && !cancelling) {
            status = "Processing file…"
            progress = -1
        } else if (event.event === "saved") {
            copying = true
            status = "Copying to clipboard…"
            progress = -1
        } else if (event.event === "done") {
            terminalEvent = true
            copied = event.clipboard_ok === true
            progress = 100
            status = copied ? "Copied to clipboard" : "File saved"
            if (copied) completed("Media copied — press Ctrl+V to paste")
        } else if (event.event === "error") {
            terminalEvent = true
            reject(String(event.message || "Could not process this link"))
        } else if (event.event === "cancelled") {
            terminalEvent = true
            status = "Download cancelled"
            details = ""
        }
    }

    Timer {
        id: startup
        interval: 1500
        onTriggered: {
            if (root.busy && !worker.running) {
                root.busy = false
                root.reject("Could not start the downloader. Check python3.")
            }
        }
    }

    Timer {
        id: probeStartup
        interval: 1500
        onTriggered: {
            if (root.checking && !probe.running) {
                root.checking = false
                root.available = false
                root.status = "Could not check tools"
                root.error = "Check python3 and try again."
            }
        }
    }

    Process {
        id: probe
        command: ["python3", root.helperPath, "probe"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const result = JSON.parse(data)
                    if (result.event !== "probe") return
                    root.checking = false
                    root.available = result.capabilities.clipboard && (result.capabilities.video || result.capabilities.image)
                    if (root.available) {
                        root.status = "Ready to download"
                        root.error = result.capabilities.video ? "" : "Install yt-dlp and ffmpeg for videos. Images are available."
                    } else {
                        root.status = "Missing tools"
                        root.error = "Install wl-clipboard for copying, and yt-dlp and ffmpeg for videos."
                    }
                } catch (parseError) {
                    root.available = false
                }
            }
        }
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            probeStartup.stop()
            if (root.checking) {
                root.checking = false
                root.available = false
                root.status = "Could not check tools"
                root.error = "Check python3 and try again."
            }
        }
    }

    Process {
        id: worker
        stdinEnabled: true
        stdout: SplitParser { onRead: data => root.receive(data) }
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            startup.stop()
            root.busy = false
            root.cancelling = false
            root.copying = false
            if (!root.terminalEvent) root.reject("Downloader exited unexpectedly (" + exitCode + ")")
        }
    }

    Component.onCompleted: refreshAvailability()
}
