import QtQuick
import Quickshell
import Quickshell.Io

// Live EN<->RU translation through the Argos daemon socket, with a small persisted history.
Scope {
    id: state

    property bool opened: false
    property string input: ""
    property string result: ""
    property string error: ""
    property int latencyMs: 0
    property string manualPair: ""
    property var history: []
    property bool historyReady: false

    readonly property string pair: manualPair !== "" ? manualPair
        : /[Ѐ-ӿ]/.test(input) ? "ru en" : "en ru"
    readonly property string sourceCode: pair.split(" ")[0].toUpperCase()
    readonly property string targetCode: pair.split(" ")[1].toUpperCase()
    readonly property string socketPath: String(Quickshell.env("XDG_RUNTIME_DIR")) + "/translate.sock"
    readonly property string stateHome: String(Quickshell.env("XDG_STATE_HOME")
        || (Quickshell.env("HOME") + "/.local/state"))
    readonly property string storageDirectory: stateHome + "/rashell"
    readonly property string storagePath: storageDirectory + "/translations.json"
    readonly property int historyLimit: 5

    function open() {
        openWith("")
    }

    function openWith(text) {
        input = String(text).trim()
        result = ""
        error = ""
        manualPair = ""
        opened = true
        requestTranslation()
    }

    function openSelection() {
        if (!selectionReader.running) selectionReader.running = true
    }

    function close() {
        opened = false
    }

    function toggle() {
        if (opened) close()
        else open()
    }

    function swap() {
        const parts = pair.split(" ")
        manualPair = parts[1] + " " + parts[0]
        requestTranslation()
    }

    function setInput(text) {
        input = String(text)
        if (input.trim() === "") {
            manualPair = ""
            result = ""
            error = ""
            debounce.stop()
            return
        }
        debounce.restart()
    }

    function requestTranslation() {
        if (input.trim() === "") return
        if (translator.running) {
            translator.stale = true
            return
        }
        translator.sentInput = input
        translator.startedAt = Date.now()
        translator.command = ["sh", "-c", "printf '%s\\n%s' \"$1\" \"$2\" | socat -t 30 - UNIX-CONNECT:\"$3\"",
            "sh", pair, input.trim(), socketPath]
        translator.running = true
    }

    function commit() {
        if (result === "" || translator.running || debounce.running) return false
        Quickshell.execDetached(["wl-copy", "-n", result])
        remember(input.trim(), result, sourceCode + "→" + targetCode)
        close()
        return true
    }

    function reuse(entry) {
        manualPair = ""
        input = entry.source
        result = entry.result
        error = ""
    }

    function remember(source, translated, direction) {
        const next = [{ source: source, result: translated, direction: direction }]
            .concat(history.filter(item => item.source !== source))
            .slice(0, historyLimit)
        history = next
        if (historyReady) historyFile.setText(JSON.stringify(next, null, 2) + "\n")
    }

    function loadHistory(text) {
        try {
            const parsed = JSON.parse(String(text || "[]"))
            if (!Array.isArray(parsed)) throw new Error("expected an array")
            history = parsed
                .filter(item => item && String(item.source || "") !== "" && String(item.result || "") !== "")
                .map(item => ({ source: String(item.source), result: String(item.result), direction: String(item.direction || "") }))
                .slice(0, historyLimit)
            historyReady = true
        } catch (loadError) {
            historyReady = false
            error = "Could not load translation history: " + loadError
        }
    }

    Timer {
        id: debounce
        interval: 200
        onTriggered: state.requestTranslation()
    }

    Process {
        id: translator

        property string sentInput: ""
        property double startedAt: 0
        property bool stale: false

        stdout: StdioCollector { id: translatorOutput }

        onExited: function(exitCode) {
            const output = String(translatorOutput.text || "").trim()
            if (exitCode === 0 && output !== "") {
                state.result = output
                state.error = ""
                state.latencyMs = Date.now() - startedAt
            } else {
                state.error = "Translator is not running · systemctl --user start translate"
            }
            if (stale || sentInput !== state.input) {
                stale = false
                state.requestTranslation()
            }
        }
    }

    Process {
        id: selectionReader
        command: ["wl-paste", "-p", "-n"]
        stdout: StdioCollector { id: selectionOutput }
        onExited: function(exitCode) {
            state.openWith(exitCode === 0 ? selectionOutput.text : "")
        }
    }

    Process {
        id: storageSetup
        command: ["mkdir", "-p", state.storageDirectory]
        onExited: function(exitCode) {
            if (exitCode === 0) historyFile.path = state.storagePath
        }
    }

    FileView {
        id: historyFile
        path: ""
        atomicWrites: true
        printErrors: false

        onLoaded: state.loadHistory(text())
        onLoadFailed: function(loadError) {
            if (loadError === FileViewError.FileNotFound) {
                state.historyReady = true
                setText("[]\n")
            }
        }
    }

    Component.onCompleted: storageSetup.running = true
}
