pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: root

    required property var audioState
    property bool opened: false
    property var targetScreen: null

    function open(screen) {
        targetScreen = screen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        opened = targetScreen !== null
        Qt.callLater(focusOutput)
    }

    function close() {
        opened = false
    }

    function focusOutput() {
        const map = mapLoader.item as OutputDeviceMap
        if (opened && map) map.focusSelected()
    }

    PanelWindow {
        id: window
        screen: root.targetScreen
        visible: root.opened || scene.opacity > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "rashell-audio-output-picker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Item {
            id: scene
            anchors.fill: parent
            opacity: root.opened ? 1 : 0
            enabled: root.opened

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.background, 0.3)
                MouseArea { anchors.fill: parent; onClicked: root.close() }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(568, window.width - 48)
                height: Math.min(Math.max(mapLoader.implicitHeight, 180), window.height - 96) + 48
                color: Qt.alpha(Theme.surface, 0.12)
                radius: Theme.radius

                MouseArea { anchors.fill: parent }

                Flickable {
                    id: viewport
                    anchors.fill: parent
                    anchors.margins: 24
                    contentWidth: width
                    contentHeight: mapLoader.height
                    interactive: contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Loader {
                        id: mapLoader
                        width: parent.width
                        active: window.visible
                        onLoaded: Qt.callLater(root.focusOutput)

                        sourceComponent: OutputDeviceMap {
                            audioState: root.audioState
                            onOutputSelected: root.close()
                            onFocusMoved: (top, bottom) => {
                                if (top < viewport.contentY) viewport.contentY = top
                                else if (bottom > viewport.contentY + viewport.height) viewport.contentY = bottom - viewport.height
                            }
                            Keys.onEscapePressed: root.close()
                        }
                    }

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.audioState.outputs.length === 0
                    text: "No output devices"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }
    }
}
