import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import "bar"

ShellRoot {
    id: shell

    readonly property var defaultConfig: ({
        version: 1,
        bar: {
            left: ["rashell.workspaces"],
            center: ["rashell.clock"],
            right: ["rashell.audio"]
        }
    })
    property var config: defaultConfig

    function loadConfig(text) {
        try {
            const parsed = JSON.parse(String(text || ""))
            if (parsed.version !== 1 || !parsed.bar) throw new Error("unsupported config")
            config = parsed
        } catch (error) {
            console.warn("Rashell config failed, using defaults:", error)
            config = defaultConfig
        }
    }

    PluginRegistry {
        id: plugins
        builtinsDir: Quickshell.shellDir + "/plugins"
        userDir: Quickshell.env("HOME") + "/.config/rashell/plugins"
    }

    FileView {
        path: Quickshell.shellDir + "/config.json"
        watchChanges: true
        printErrors: false
        onLoaded: shell.loadConfig(text())
        onFileChanged: reload()
        onLoadFailed: shell.config = shell.defaultConfig
    }

    Bar {
        pluginRegistry: plugins
        leftPlugins: shell.config.bar.left || []
        centerPlugins: shell.config.bar.center || []
        rightPlugins: shell.config.bar.right || []
    }
}
