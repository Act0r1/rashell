import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: store

    readonly property var defaults: ({
        version: 1,
        theme: "muninn",
        wallpaper: "~/Pictures/Wallpapers/bisbiswas-a-summer-evening.png",
        captureDirectory: "~/Pictures/Screenshots",
        weatherLocation: "",
        notificationDurationSeconds: 8,
        bar: {
            left: ["rashell.workspaces"],
            center: ["rashell.weather", "rashell.clock", "rashell.media", "rashell.screenshot"],
            right: ["rashell.keyboard", "rashell.tray", "rashell.bluetooth", "rashell.notifications", "rashell.system", "rashell.audio", "rashell.tokens", "rashell.control", "rashell.updates"]
        }
    })

    property var effective: defaults
    property string selectedPath: ""
    property bool hasValidFile: false
    property bool probingXdg: false
    property bool initialized: false

    readonly property var barModuleIds: [
        "rashell.workspaces", "rashell.clock", "rashell.weather", "rashell.audio", "rashell.media",
        "rashell.screenshot", "rashell.keyboard", "rashell.tray", "rashell.bluetooth",
        "rashell.system", "rashell.control", "rashell.tokens", "rashell.notifications", "rashell.updates"
    ]
    readonly property string theme: effective.theme
    readonly property string wallpaper: effective.wallpaper
    readonly property string wallpaperPath: wallpaper.indexOf("~/") === 0
        ? Quickshell.env("HOME") + wallpaper.slice(1) : wallpaper
    readonly property string captureDirectory: effective.captureDirectory
    readonly property string weatherLocation: effective.weatherLocation
    readonly property int notificationDurationSeconds: effective.notificationDurationSeconds
    readonly property string captureDirectoryPath: captureDirectory.indexOf("~/") === 0
        ? Quickshell.env("HOME") + captureDirectory.slice(1) : captureDirectory
    readonly property var leftModules: effective.bar.left
    readonly property var centerModules: effective.bar.center
    readonly property var rightModules: effective.bar.right
    readonly property var trayPinnedIds: effective.trayPinnedIds === undefined ? null : effective.trayPinnedIds

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
        if (isPlainObject(candidate) && Object.keys(candidate).indexOf("trayPinnedIds") !== -1) {
            if (!Array.isArray(candidate.trayPinnedIds)) return "tray pins must be an array"
            const seenPins = []
            for (let index = 0; index < candidate.trayPinnedIds.length; index++) {
                const pin = candidate.trayPinnedIds[index]
                if (typeof pin !== "string" || pin.trim() === "" || pin !== pin.trim()) return "invalid tray pin"
                if (seenPins.indexOf(pin) !== -1) return "duplicate tray pin: " + pin
                seenPins.push(pin)
            }
            const base = Object.assign({}, candidate)
            delete base.trayPinnedIds
            const error = validate(base)
            if (error !== "") return error
            Object.assign(candidate, base)
            return ""
        }
        if (isPlainObject(candidate) && sameKeys(candidate, ["version", "theme", "bar"])) {
            candidate.wallpaper = defaults.wallpaper
            candidate.captureDirectory = defaults.captureDirectory
            candidate.weatherLocation = defaults.weatherLocation
            candidate.notificationDurationSeconds = defaults.notificationDurationSeconds
        } else if (isPlainObject(candidate) && sameKeys(candidate, ["version", "theme", "wallpaper", "bar"])) {
            candidate.captureDirectory = defaults.captureDirectory
            candidate.weatherLocation = defaults.weatherLocation
            candidate.notificationDurationSeconds = defaults.notificationDurationSeconds
        } else if (isPlainObject(candidate) && sameKeys(candidate, ["version", "theme", "wallpaper", "captureDirectory", "bar"])) {
            candidate.weatherLocation = defaults.weatherLocation
            candidate.notificationDurationSeconds = defaults.notificationDurationSeconds
        } else if (isPlainObject(candidate) && sameKeys(candidate, ["version", "theme", "wallpaper", "captureDirectory", "weatherLocation", "bar"])) {
            candidate.notificationDurationSeconds = defaults.notificationDurationSeconds
        }
        if (!isPlainObject(candidate) || !sameKeys(candidate, ["version", "theme", "wallpaper", "captureDirectory", "weatherLocation", "notificationDurationSeconds", "bar"])) return "invalid top-level fields"
        if (candidate.version !== 1) return "unsupported config version"
        if (Theme.names.indexOf(candidate.theme) === -1) return "unknown theme"
        if (typeof candidate.wallpaper !== "string" || candidate.wallpaper.trim() === "") return "invalid wallpaper"
        if (typeof candidate.captureDirectory !== "string" || candidate.captureDirectory.trim() === "") return "invalid capture directory"
        if (typeof candidate.weatherLocation !== "string") return "invalid weather location"
        if (typeof candidate.notificationDurationSeconds !== "number"
                || Math.floor(candidate.notificationDurationSeconds) !== candidate.notificationDurationSeconds
                || candidate.notificationDurationSeconds < 1
                || candidate.notificationDurationSeconds > 60) return "invalid notification duration"
        if (!isPlainObject(candidate.bar) || !sameKeys(candidate.bar, ["left", "center", "right"])) return "invalid bar fields"

        const allowed = barModuleIds
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

    function applyConfig(candidate) {
        effective = JSON.parse(JSON.stringify(candidate))
        hasValidFile = true
        configLoaded()
    }

    function applyText(text) {
        try {
            const parsed = JSON.parse(String(text || ""))
            const error = validate(parsed)
            if (error !== "") throw new Error(error)
            applyConfig(parsed)
        } catch (error) {
            configError("Config rejected at " + selectedPath + ": " + error)
        }
    }

    function selectPath(path, isXdgProbe) {
        selectedPath = path
        probingXdg = isXdgProbe
        configFile.path = path
    }

    function save(next) {
        const error = validate(next)
        if (error !== "") {
            configError("Config update rejected: " + error)
            return false
        }
        applyConfig(next)
        configFile.setText(JSON.stringify(next, null, 2) + "\n")
        return true
    }

    function setTheme(name) {
        const next = JSON.parse(JSON.stringify(effective))
        next.theme = String(name)
        return save(next)
    }

    function setWallpaper(path) {
        const next = JSON.parse(JSON.stringify(effective))
        next.wallpaper = String(path)
        return save(next)
    }

    function setCaptureDirectory(path) {
        const next = JSON.parse(JSON.stringify(effective))
        next.captureDirectory = String(path)
        return save(next)
    }

    function setWeatherLocation(location) {
        const next = JSON.parse(JSON.stringify(effective))
        next.weatherLocation = String(location).trim()
        return save(next)
    }

    function setNotificationDurationSeconds(seconds) {
        const next = JSON.parse(JSON.stringify(effective))
        next.notificationDurationSeconds = Math.round(Number(seconds))
        return save(next)
    }

    function setTrayPinnedIds(ids) {
        const next = JSON.parse(JSON.stringify(effective))
        next.trayPinnedIds = Array.from(ids)
        return save(next)
    }

    function setBar(left, center, right) {
        const next = JSON.parse(JSON.stringify(effective))
        next.bar = {
            left: Array.from(left),
            center: Array.from(center),
            right: Array.from(right)
        }
        return save(next)
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
