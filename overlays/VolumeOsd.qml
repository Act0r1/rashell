import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: root

    required property var audioState
    property string targetOutput: ""
    property bool showing: false

    function show(outputName) {
        targetOutput = outputName
        showing = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.showing = false
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.showing && root.targetOutput === modelData.name
                implicitWidth: 300
                implicitHeight: 58
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                mask: Region {}

                anchors { bottom: true }
                margins { bottom: 48 }
                WlrLayershell.namespace: "rashell-volume-osd"
                WlrLayershell.layer: WlrLayer.Overlay

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surface
                    border.color: Theme.borderInteractive
                    border.width: Theme.borderWidth
                    radius: Theme.radius

                    Row {
                        anchors {
                            fill: parent
                            margins: Theme.spaceLg
                        }
                        spacing: Theme.spaceLg

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.audioState.outputMuted ? "MUTE" : "VOL"
                            color: root.audioState.outputMuted ? Theme.danger : Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 160
                            height: Theme.sliderTrackHeight
                            color: Theme.surfaceRaised
                            border.color: Theme.borderInteractive
                            border.width: Theme.borderWidth

                            Rectangle {
                                width: Math.min(1, root.audioState.outputVolume / 1.5) * parent.width
                                height: parent.height
                                color: Theme.accent
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(root.audioState.outputVolume * 100) + "%"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                        }
                    }
                }
            }
        }
    }
}
