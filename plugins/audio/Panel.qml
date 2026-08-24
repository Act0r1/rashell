pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.core

Item {
    id: root

    property Item anchorItem: null
    property bool open: false
    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var sinks: {
        const result = []
        for (let index = 0; index < nodes.length; index++) {
            const node = nodes[index]
            if (node && node.isSink && !node.isStream) result.push(node)
        }
        return result
    }

    readonly property var sources: {
        const result = []
        for (let index = 0; index < nodes.length; index++) {
            const node = nodes[index]
            if (node && !node.isSink && !node.isStream && node.audio) result.push(node)
        }
        return result
    }

    function nodeLabel(node) {
        if (!node) return "Unavailable"
        return String(node.nickname || node.description || node.name || "Unknown device")
    }

    function selectSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }

    function selectSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
    }

    function toggleMute(node) {
        if (node && node.audio) node.audio.muted = !node.audio.muted
    }

    component SectionLabel: Text {
        color: Theme.accentMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.bold: true
        font.letterSpacing: 2
    }

    component VolumeControl: Item {
        id: volumeControl

        required property string label
        required property var node

        implicitHeight: 54

        Text {
            anchors {
                left: parent.left
                top: parent.top
            }
            text: volumeControl.label
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        Slider {
            id: volumeSlider
            anchors {
                left: parent.left
                right: percentage.left
                bottom: parent.bottom
                rightMargin: 12
            }
            from: 0
            to: 1.5
            value: volumeControl.node && volumeControl.node.audio ? volumeControl.node.audio.volume : 0
            enabled: volumeControl.node && volumeControl.node.audio

            onMoved: {
                if (volumeControl.node && volumeControl.node.audio) volumeControl.node.audio.volume = value
            }

            background: Rectangle {
                x: volumeSlider.leftPadding
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                width: volumeSlider.availableWidth
                height: 6
                color: Theme.surfaceRaised
                border.color: Theme.border
                border.width: 1

                Rectangle {
                    width: volumeSlider.visualPosition * parent.width
                    height: parent.height
                    color: Theme.accent
                }
            }

            handle: Rectangle {
                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                width: 12
                height: 18
                color: volumeSlider.pressed ? Theme.accent : Theme.text
                border.color: Theme.background
                border.width: 1
                radius: 1
            }
        }

        Text {
            id: percentage
            anchors {
                right: muteButton.left
                rightMargin: 10
                verticalCenter: volumeSlider.verticalCenter
            }
            text: volumeControl.node && volumeControl.node.audio
                ? Math.round(volumeControl.node.audio.volume * 100) + "%" : "--"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Rectangle {
            id: muteButton
            anchors {
                right: parent.right
                verticalCenter: volumeSlider.verticalCenter
            }
            width: 52
            height: 28
            color: volumeControl.node && volumeControl.node.audio && volumeControl.node.audio.muted
                ? Theme.danger : muteHover.hovered ? Theme.surfaceRaised : "transparent"
            border.color: volumeControl.node && volumeControl.node.audio && volumeControl.node.audio.muted
                ? Theme.danger : Theme.border
            border.width: 1
            radius: Theme.radius

            Text {
                anchors.centerIn: parent
                text: volumeControl.node && volumeControl.node.audio && volumeControl.node.audio.muted ? "OFF" : "ON"
                color: volumeControl.node && volumeControl.node.audio && volumeControl.node.audio.muted
                    ? Theme.background : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            HoverHandler {
                id: muteHover
            }

            TapHandler {
                onTapped: root.toggleMute(volumeControl.node)
            }
        }
    }

    component DeviceRow: Rectangle {
        id: deviceRow

        required property var node
        required property bool selected
        required property string kind

        signal chosen(var node)

        implicitHeight: 40
        color: selected ? Theme.accent : rowHover.hovered ? Theme.surfaceRaised : "transparent"
        border.color: selected ? Theme.accent : "transparent"
        border.width: 1
        radius: Theme.radius

        Text {
            anchors {
                left: parent.left
                leftMargin: 12
                right: stateLabel.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: (deviceRow.selected ? "> " : "  ") + root.nodeLabel(deviceRow.node)
            color: deviceRow.selected ? Theme.background : Theme.text
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Text {
            id: stateLabel
            anchors {
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: deviceRow.selected ? "IN USE" : deviceRow.kind
            color: deviceRow.selected ? Theme.background : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: deviceRow.selected
            font.letterSpacing: 1
        }

        HoverHandler {
            id: rowHover
        }

        TapHandler {
            onTapped: deviceRow.chosen(deviceRow.node)
        }
    }

    PwObjectTracker {
        objects: root.nodes
    }

    HyprlandFocusGrab {
        active: popup.visible
        windows: root.anchorItem && root.anchorItem.QsWindow.window
            ? [popup, root.anchorItem.QsWindow.window] : [popup]
        onCleared: root.open = false
    }

    PopupWindow {
        id: popup

        visible: root.open && root.anchorItem !== null
        color: "transparent"
        implicitWidth: 460
        implicitHeight: Math.max(480, Math.min(760, 370 + root.sinks.length * 42 + root.sources.length * 42))

        anchor {
            id: popupAnchor
            window: root.anchorItem ? root.anchorItem.QsWindow.window : null
            adjustment: PopupAdjustment.Slide
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            rect.width: 1
            rect.height: 1

            onAnchoring: {
                if (!root.anchorItem) return
                const window = root.anchorItem.QsWindow.window
                if (!window) return

                const point = window.contentItem.mapFromItem(
                    root.anchorItem,
                    root.anchorItem.width - popup.implicitWidth,
                    root.anchorItem.height + Theme.panelGap
                )
                popupAnchor.rect.x = Math.round(point.x)
                popupAnchor.rect.y = Math.round(point.y)
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius

            Column {
                anchors {
                    fill: parent
                    margins: Theme.panelPadding
                }
                spacing: 10

                Item {
                    width: parent.width
                    height: 28

                    Text {
                        anchors.left: parent.left
                        text: "[ AUDIO ]"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 28
                        height: 28
                        color: closeHover.hovered ? Theme.surfaceRaised : "transparent"
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "X"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }

                        HoverHandler {
                            id: closeHover
                        }

                        TapHandler {
                            onTapped: root.open = false
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                VolumeControl {
                    width: parent.width
                    label: "OUTPUT VOLUME"
                    node: root.sink
                }

                SectionLabel {
                    text: "OUTPUT"
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.sinks

                        DeviceRow {
                            required property var modelData
                            width: parent.width
                            node: modelData
                            selected: root.sink !== null && modelData.id === root.sink.id
                            kind: "SINK"
                            onChosen: function(node) { root.selectSink(node) }
                        }
                    }
                }

                VolumeControl {
                    width: parent.width
                    label: "INPUT VOLUME"
                    node: root.source
                    visible: root.source !== null
                }

                SectionLabel {
                    text: "INPUT"
                    visible: root.sources.length > 0
                }

                Column {
                    width: parent.width
                    spacing: 2
                    visible: root.sources.length > 0

                    Repeater {
                        model: root.sources

                        DeviceRow {
                            required property var modelData
                            width: parent.width
                            node: modelData
                            selected: root.source !== null && modelData.id === root.source.id
                            kind: "SOURCE"
                            onChosen: function(node) { root.selectSource(node) }
                        }
                    }
                }

                Item {
                    width: 1
                    height: 4
                }

                SectionLabel {
                    text: "APPLICATION STREAMS"
                }

                Text {
                    text: "Per-application controls are the next audio milestone."
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
