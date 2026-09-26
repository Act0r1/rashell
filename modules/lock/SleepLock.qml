import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property bool secure

    property bool preparingSleep: false

    signal lockRequested

    readonly property string sessionPath: "/org/freedesktop/login1/session/" + encodePath(Quickshell.env("XDG_SESSION_ID") || "auto")

    function encodePath(value: string): string {
        let result = ""
        for (let index = 0; index < value.length; index++) {
            const character = value.charAt(index)
            const plain = /[A-Za-z0-9]/.test(character) && !(index === 0 && /[0-9]/.test(character))
            result += plain ? character : "_" + value.charCodeAt(index).toString(16).padStart(2, "0")
        }
        return result
    }

    function handle(line: string) {
        if (line.indexOf(".Manager.PrepareForSleep (true") !== -1) {
            preparingSleep = true
            lockRequested()
        } else if (line.indexOf(".Manager.PrepareForSleep (false") !== -1) {
            preparingSleep = false
        } else if (line.indexOf(sessionPath + ": org.freedesktop.login1.Session.Lock ") === 0) {
            lockRequested()
        }
    }

    Process {
        id: inhibitor
        running: !(root.preparingSleep && root.secure)
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=rashell",
            "--why=Lock the screen before sleep", "sleep", "infinity"]
    }

    Process {
        id: monitor
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: data => root.handle(data)
        }
        onExited: restartMonitor.start()
    }

    Timer {
        id: restartMonitor
        interval: 2000
        onTriggered: monitor.running = true
    }
}
