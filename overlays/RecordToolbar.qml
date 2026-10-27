import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.core
import qs.ui

// Floating recording toolbar shown under a freshly selected region (F4 flow).
// Lets you switch to the full display, pick audio and microphone, change the folder and start.
Scope {
    id: root

    required property var captureState
    required property var configStore
    property bool locked: false

    property string region: ""
    property bool micListOpen: false
    property bool pickingFolder: false

    readonly property bool fullDisplay: captureState.captureMode === "output"
    readonly property bool usesMicrophone: captureState.audioMode === "microphone" || captureState.audioMode === "both"

    readonly property var rect: {
        const match = /^(-?\d+),(-?\d+) (\d+)x(\d+)$/.exec(region)
        return match ? { x: Number(match[1]), y: Number(match[2]), w: Number(match[3]), h: Number(match[4]) } : null
    }

    readonly property var targetScreen: {
        const screens = Quickshell.screens
        for (let index = 0; rect && index < screens.length; index++) {
            const screen = screens[index]
            if (rect.x >= screen.x && rect.x < screen.x + screen.width
                    && rect.y >= screen.y && rect.y < screen.y + screen.height) return screen
        }
        return screens.length > 0 ? screens[0] : null
    }

    readonly property var microphones: {
        const nodes = Pipewire.nodes ? Pipewire.nodes.values : []
        const result = []
        for (let index = 0; index < nodes.length; index++) {
            const node = nodes[index]
            if (node && node.audio && !node.isStream && (node.type & PwNodeType.Source) !== 0) result.push(node)
        }
        return result
    }

    readonly property string microphoneLabel: {
        const chosen = configStore.captureMicrophone
        for (let index = 0; index < microphones.length; index++) {
            if (microphones[index].name === chosen) return nodeLabel(microphones[index])
        }
        return "Default"
    }

    function nodeLabel(node) {
        return String(node.nickname || node.description || node.name)
    }

    function toggleFullDisplay() {
        if (fullDisplay) {
            captureState.captureMode = "region"
            captureState.captureSelection = region
        } else if (targetScreen) {
            captureState.captureMode = "output"
            captureState.captureSelection = targetScreen.name
        }
    }

    function startRecording() {
        if (!captureState.toolbarOpen) return
        captureState.start(
            "record",
            configStore.captureDirectoryPath,
            targetScreen ? targetScreen.name : "",
            captureState.captureMode,
            captureState.audioMode,
            captureState.captureSelection,
            configStore.captureMicrophone
        )
    }

    function cancel() {
        micListOpen = false
        captureState.closeToolbar()
    }

    Connections {
        target: root.captureState
        function onToolbarOpenChanged() {
            root.micListOpen = false
            if (root.captureState.toolbarOpen) root.region = root.captureState.captureSelection
        }
    }

    Process {
        id: folderPicker
        stdout: StdioCollector {}
        onExited: function(exitCode) {
            root.pickingFolder = false
            const selected = String(folderPicker.stdout.text || "").trim()
            if (exitCode === 0 && selected !== "") root.configStore.setCaptureDirectory(selected)
        }
    }

    PanelWindow {
        id: window
        screen: root.targetScreen
        visible: screen !== null && root.captureState.toolbarOpen && !root.locked && !root.pickingFolder
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "rashell-record-toolbar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        readonly property real regionX: root.rect && screen ? root.rect.x - screen.x : 0
        readonly property real regionY: root.rect && screen ? root.rect.y - screen.y : 0
        readonly property real gap: Theme.spaceLg

        Shortcut {
            sequence: "Esc"
            onActivated: root.cancel()
        }

        Shortcut {
            sequences: ["Return", "Enter"]
            onActivated: root.startRecording()
        }

        Rectangle {
            x: root.fullDisplay ? 0 : window.regionX - border.width
            y: root.fullDisplay ? 0 : window.regionY - border.width
            width: root.fullDisplay ? window.width : (root.rect ? root.rect.w : 0) + border.width * 2
            height: root.fullDisplay ? window.height : (root.rect ? root.rect.h : 0) + border.width * 2
            color: "transparent"
            border.color: Theme.accent
            border.width: 2
        }

        Rectangle {
            id: toolbar
            width: 460
            height: content.implicitHeight + Theme.spaceLg * 2
            x: root.fullDisplay || !root.rect
                ? window.width - width - window.gap
                : Math.max(window.gap, Math.min(window.regionX, window.width - width - window.gap))
            y: {
                if (root.fullDisplay || !root.rect) return window.height - height - window.gap
                const below = window.regionY + root.rect.h + window.gap
                if (below + height <= window.height - window.gap) return below
                const above = window.regionY - height - window.gap
                if (above >= window.gap) return above
                return window.regionY + root.rect.h - height - window.gap
            }
            color: Theme.surface
            radius: Theme.radius
            border.color: Theme.borderInteractive
            border.width: Theme.borderWidth

            Column {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceLg }
                spacing: Theme.spaceMd

                Row {
                    width: parent.width
                    spacing: Theme.spaceMd

                    ActionButton {
                        width: (parent.width - parent.spacing) / 2
                        text: "Full display"
                        accessibleName: "Record the whole display instead of the region"
                        selected: root.fullDisplay
                        onClicked: root.toggleFullDisplay()
                    }

                    ActionButton {
                        width: (parent.width - parent.spacing) / 2
                        text: "Mic: " + root.microphoneLabel + (root.micListOpen ? " ▴" : " ▾")
                        accessibleName: "Choose recording microphone"
                        enabled: root.usesMicrophone
                        selected: root.micListOpen
                        subtleSelected: true
                        onClicked: root.micListOpen = !root.micListOpen
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spaceSm
                    visible: root.micListOpen && root.usesMicrophone

                    ActionButton {
                        width: parent.width
                        alignment: Text.AlignLeft
                        text: "Default"
                        selected: root.microphoneLabel === "Default"
                        subtleSelected: true
                        onClicked: {
                            root.configStore.setCaptureMicrophone("")
                            root.micListOpen = false
                        }
                    }

                    Repeater {
                        model: root.microphones

                        ActionButton {
                            required property var modelData
                            width: parent.width
                            alignment: Text.AlignLeft
                            text: root.nodeLabel(modelData)
                            selected: root.configStore.captureMicrophone === modelData.name
                            subtleSelected: true
                            onClicked: {
                                root.configStore.setCaptureMicrophone(modelData.name)
                                root.micListOpen = false
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spaceMd

                    Repeater {
                        model: [
                            { mode: "none", label: "No audio" },
                            { mode: "system", label: "System" },
                            { mode: "microphone", label: "Mic" },
                            { mode: "both", label: "Both" }
                        ]

                        ActionButton {
                            required property var modelData
                            width: (parent.width - parent.spacing * 3) / 4
                            text: modelData.label
                            selected: root.captureState.audioMode === modelData.mode
                            onClicked: root.captureState.audioMode = modelData.mode
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spaceMd

                    ActionButton {
                        width: parent.width - cancelButton.width - startButton.width - parent.spacing * 2
                        alignment: Text.AlignLeft
                        text: "Save to: " + root.configStore.captureDirectory
                        accessibleName: "Choose capture folder"
                        onClicked: {
                            root.pickingFolder = true
                            folderPicker.exec({
                                command: ["zenity", "--file-selection", "--directory",
                                    "--filename=" + root.configStore.captureDirectoryPath + "/"]
                            })
                        }
                    }

                    ActionButton {
                        id: cancelButton
                        text: "Cancel"
                        accessibleName: "Cancel recording (Esc)"
                        onClicked: root.cancel()
                    }

                    ActionButton {
                        id: startButton
                        text: "● Start"
                        accessibleName: "Start recording (Enter or F4)"
                        danger: true
                        onClicked: root.startRecording()
                    }
                }
            }
        }
    }
}
