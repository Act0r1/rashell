import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: root

    property string targetOutput: ""
    property string message: ""
    property bool showing: false
    property bool error: true

    function show(outputName, text, isError) {
        targetOutput = outputName
        message = text
        error = isError !== false
        showing = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: root.showing = false
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.showing && root.targetOutput === modelData.name
                implicitWidth: 360
                implicitHeight: 54
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                mask: Region {}

                anchors {
                    right: true
                    bottom: true
                }
                margins {
                    right: Theme.edgeMargin
                    bottom: 114
                }
                WlrLayershell.namespace: "rashell-feedback"
                WlrLayershell.layer: WlrLayer.Overlay

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surface
                    border.color: root.error ? Theme.danger : Theme.accent
                    border.width: Theme.borderWidth
                    radius: Theme.radius

                    Text {
                        anchors {
                            fill: parent
                            margins: Theme.spaceLg
                        }
                        text: root.message
                        color: root.error ? Theme.danger : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
