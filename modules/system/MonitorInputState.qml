import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    required property string outputName
    property var inputs: []
    property int current: -1
    property string model: ""
    property string error: ""
    property string message: ""
    readonly property bool busy: process.running

    function run(source) {
        if (busy) return
        error = ""
        message = ""
        const args = ["python3", Quickshell.shellDir + "/scripts/monitor-input.py", outputName]
        if (source !== undefined) args.push("--set", Number(source).toString(16))
        process.command = args
        process.running = true
    }

    Process {
        id: process
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text)
                    if (result.error) root.error = result.error
                    else if (result.sent) {
                        root.current = -1
                        root.message = "Switch command sent"
                    } else {
                        root.inputs = result.inputs
                        root.current = result.current
                        root.model = result.model
                    }
                } catch (error) {
                    root.error = "Could not read monitor response"
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if ((exitCode !== 0 || exitStatus !== 0) && root.error === "")
                root.error = "Monitor command failed"
        }
    }
}
