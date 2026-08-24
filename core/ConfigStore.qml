import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: store

    readonly property var defaults: ({
        version: 1,
        theme: "muninn",
        wallpaper: "~/Pictures/Wallpapers/bisbiswas-a-summer-evening.png",
        bar: {
            left: ["rashell.workspaces"],
            center: ["rashell.clock", "rashell.media", "rashell.screenshot"],
            right: ["rashell.keyboard", "rashell.tray", "rashell.notifications", "rashell.system", "rashell.audio", "rashell.tokens", "rashell.control", "rashell.updates"]
        }
    })

    property var effective: defaults
    property string selectedPath: ""
    property bool hasValidFile: false
    property bool probingXdg: false
    property bool initialized: false

    readonly property string theme: effective.theme
    readonly property string wallpaper: effective.wallpaper
    readonly property var leftModules: effective.bar.left
    readonly property var centerModules: effective.bar.center
    readonly property var rightModules: effective.bar.right

    signal configError(string message)
    signal configLoaded()

    function isPlainObject(value) {
        return value !== null && typeof value === "object" && !Array.isArray(value)
    }

    function sameKeys(value, allowed) {
        const keys = Object.keys(value)
        if (keys.length !== allowed.length) return false
        for (let index = 0; index < keys.length; index++) {
            if (allowed.indexOf(keys[index]) === -1) return false
        }
        return true
    }

    function validate(candidate) {
        if (isPlainObject(candidate) && sameKeys(candidate, ["version", "theme", "bar"])) {
            candidate.wallpaper = defaults.wallpaper
        }
        if (!isPlainObject(candidate) || !sameKeys(candidate, ["version", "theme", "wallpaper", "bar"])) return "invalid top-level fields"
        if (candidate.version !== 1) return "unsupported config version"
        if (["oilslick", "muninn", "nevermore", "talon", "ember", "raven", "jade"].indexOf(candidate.theme) === -1) return "unknown theme"
        if (typeof candidate.wallpaper !== "string" || candidate.wallpaper.trim() === "") return "invalid wallpaper"
        if (!isPlainObject(candidate.bar) || !sameKeys(candidate.bar, ["left", "center", "right"])) return "invalid bar fields"

        const allowed = [
            "rashell.workspaces", "rashell.clock", "rashell.audio", "rashell.media",
            "rashell.screenshot", "rashell.keyboard", "rashell.tray", "rashell.system",
            "rashell.control", "rashell.tokens", "rashell.notifications", "rashell.updates"
        ]
        const zones = [candidate.bar.left, candidate.bar.center, candidate.bar.right]
        const seen = []

        for (let zoneIndex = 0; zoneIndex < zones.length; zoneIndex++) {
            const zone = zones[zoneIndex]
            if (!Array.isArray(zone)) return "bar zones must be arrays"
            for (let itemIndex = 0; itemIndex < zone.length; itemIndex++) {
                const moduleId = zone[itemIndex]
                if (typeof moduleId !== "string" || allowed.indexOf(moduleId) === -1) return "unknown module: " + moduleId
                if (seen.indexOf(moduleId) !== -1) return "duplicate module: " + moduleId
                seen.push(moduleId)
            }
        }

        return ""
    }

    function applyText(text) {
        try {
            const parsed = JSON.parse(String(text || ""))
            const error = validate(parsed)
            if (error !== "") throw new Error(error)
            effective = JSON.parse(JSON.stringify(parsed))
            hasValidFile = true
            configLoaded()
        } catch (error) {
            configError("Config rejected at " + selectedPath + ": " + error)
        }
    }

    function selectPath(path, isXdgProbe) {
        selectedPath = path
        probingXdg = isXdgProbe
        configFile.path = path
    }

    function initialize() {
        if (initialized) return
        initialized = true

        const explicitPath = String(Quickshell.env("RASHELL_CONFIG") || "")
        if (explicitPath !== "") {
            if (explicitPath.charAt(0) === "/") {
                selectPath(explicitPath, false)
                return
            }
            configError("RASHELL_CONFIG must be an absolute path")
        }

        const home = String(Quickshell.env("HOME") || "")
        const xdgHome = String(Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config"))
        selectPath(xdgHome + "/rashell/config.json", true)
    }

    FileView {
        id: configFile
        watchChanges: true
        printErrors: false

        onLoaded: {
            store.probingXdg = false
            store.applyText(text())
        }

        onFileChanged: reload()

        onLoadFailed: function(error) {
            if (store.probingXdg && !store.hasValidFile && error === FileViewError.FileNotFound) {
                Qt.callLater(function() {
                    store.selectPath(Quickshell.shellDir + "/config.json", false)
                })
                return
            }

            store.probingXdg = false
            store.configError("Config unavailable at " + store.selectedPath + ": " + FileViewError.toString(error))
        }
    }

    Component.onCompleted: initialize()
}
