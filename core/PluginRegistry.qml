import QtQuick
import Quickshell.Io

QtObject {
    id: registry

    property string builtinsDir: ""
    property string userDir: ""
    property var plugins: ({})
    property int revision: 0
    property bool scanning: false

    function plugin(pluginId) {
        return plugins[String(pluginId)] || null
    }

    function entryPoint(pluginId, kind) {
        const manifest = plugin(pluginId)
        if (!manifest || !manifest.entryPoints) return ""

        const relativePath = String(manifest.entryPoints[kind] || "")
        if (!safeRelativePath(relativePath)) return ""

        return "file://" + encodeURI(manifest.sourceDir + "/" + relativePath)
    }

    function safeRelativePath(path) {
        return path.length > 0 && path.charAt(0) !== "/" && path.indexOf("..") === -1
    }

    function validate(manifest, sourceDir) {
        if (!manifest || typeof manifest !== "object") return null
        if (manifest.schemaVersion !== 1) return null
        if (!manifest.id || !manifest.name || !manifest.version) return null
        if (!Array.isArray(manifest.kinds) || manifest.kinds.length === 0) return null
        if (!manifest.entryPoints || typeof manifest.entryPoints !== "object") return null

        const supportedKinds = ["bar-widget"]
        for (let index = 0; index < manifest.kinds.length; index++) {
            if (supportedKinds.indexOf(String(manifest.kinds[index])) === -1) return null
        }
        if (manifest.kinds.indexOf("bar-widget") !== -1 && !manifest.entryPoints.barWidget) return null

        const id = String(manifest.id)
        if (id.indexOf("/") !== -1 || id.indexOf("..") !== -1) return null

        const points = Object.keys(manifest.entryPoints)
        for (let index = 0; index < points.length; index++) {
            if (!safeRelativePath(String(manifest.entryPoints[points[index]]))) return null
        }

        manifest.sourceDir = sourceDir
        return manifest
    }

    function parseScanOutput(output) {
        const found = {}
        const lines = String(output || "").split("\n")
        let sourceDir = ""
        let manifestLines = []

        function finishManifest() {
            if (!sourceDir || manifestLines.length === 0) return

            try {
                const manifest = registry.validate(JSON.parse(manifestLines.join("\n")), sourceDir)
                if (manifest) found[manifest.id] = manifest
            } catch (error) {
                console.warn("Rashell plugin manifest failed:", sourceDir, error)
            }
        }

        for (let index = 0; index < lines.length; index++) {
            const line = lines[index]
            if (line.indexOf("===PLUGIN::") === 0 && line.endsWith("===")) {
                finishManifest()
                sourceDir = line.slice(11, -3)
                manifestLines = []
            } else if (line === "===END===") {
                finishManifest()
                sourceDir = ""
                manifestLines = []
            } else if (sourceDir) {
                manifestLines.push(line)
            }
        }

        finishManifest()
        plugins = found
        revision++
        scanning = false
    }

    function rescan() {
        if (scanning || builtinsDir === "" || userDir === "") return

        scanning = true
        const script = [
            "emit_manifest() {",
            "  local manifest=\"$1\"",
            "  local dir=${manifest%/manifest.json}",
            "  printf '===PLUGIN::%s===\\n' \"$dir\"",
            "  cat \"$manifest\"",
            "  printf '\\n===END===\\n'",
            "}",
            "scan_dir() {",
            "  local root=\"$1\"",
            "  [ -d \"$root\" ] || return 0",
            "  while IFS= read -r manifest; do emit_manifest \"$manifest\"; done < <(find \"$root\" -mindepth 2 -maxdepth 2 -type f -name manifest.json | sort)",
            "}",
            "scan_dir \"$1\"",
            "scan_dir \"$0\""
        ].join("\n")

        scanner.command = ["bash", "-c", script, builtinsDir, userDir]
        scanner.running = true
    }

    property Process scanner: Process {
        stdout: StdioCollector {
            id: scanOutput
            waitForEnd: true
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) console.warn("Rashell plugin scan exited with", exitCode)
            registry.parseScanOutput(scanOutput.text)
        }
    }

    property Process createUserDir: Process {
        command: ["mkdir", "-p", registry.userDir]
        onExited: registry.rescan()
    }

    Component.onCompleted: createUserDir.running = true
}
