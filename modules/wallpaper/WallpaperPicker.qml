pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: root

    required property var configStore

    property bool opened: false
    property var targetScreen: null
    property int activeIndex: 0

    readonly property real collapsedWeight: 1
    readonly property real expandedWeight: 5.2

    function open(screen) {
        targetScreen = screen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        if (targetScreen === null) return
        activeIndex = state.indexOfCurrent()
        opened = true
    }

    function close() {
        opened = false
    }

    function toggle(screen) {
        if (opened) close()
        else open(screen)
    }

    function step(delta) {
        if (state.count === 0) return
        activeIndex = (activeIndex + delta + state.count) % state.count
    }

    function applyActive() {
        if (state.apply(activeIndex)) close()
    }

    WallpaperState {
        id: state
        configStore: root.configStore
    }

    Image {
        id: meta
        source: root.opened && state.count > 0
            ? "file://" + state.pathAt(root.activeIndex) : ""
        asynchronous: true
        visible: false
        cache: false
    }

    PanelWindow {
        id: window

        screen: root.targetScreen
        visible: root.opened && root.targetScreen !== null
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "rashell-wallpaper-picker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Theme.background

            Image {
                id: backdrop
                anchors.fill: parent
                source: state.count > 0 ? "file://" + state.pathAt(root.activeIndex) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.height: 720
                opacity: 0.22
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.55)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        onVisibleChanged: if (visible) Qt.callLater(function() { keys.forceActiveFocus() })

        FocusScope {
            id: keys
            anchors.fill: parent
            focus: root.opened

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    root.step(-1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                    root.step(1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.applyActive()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }

            Column {
                anchors.centerIn: parent
                width: Math.min(1280, window.width - 96)
                spacing: Theme.spaceLg

                Item {
                    width: parent.width
                    height: Theme.controlHeight

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "[ WALLPAPER ]"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: state.count + (state.count === 1 ? " image" : " images")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }

                Rectangle {
                    id: sheet
                    width: parent.width
                    height: Math.min(620, window.height - 240)
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: Theme.borderWidth
                    radius: Theme.radius
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        visible: state.count === 0
                        text: state.ready ? "No images in " + state.directory : "Reading " + state.directory + "…"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }

                    Row {
                        id: strip
                        anchors.fill: parent
                        spacing: 0

                        readonly property real totalWeight: state.count <= 0 ? 1
                            : root.expandedWeight + (state.count - 1) * root.collapsedWeight
                        readonly property real unit: width / totalWeight

                        Repeater {
                            model: state.model

                            Item {
                                id: column

                                required property int index
                                required property string filePath
                                required property string fileName

                                readonly property bool active: index === root.activeIndex
                                readonly property string label: {
                                    const dot = fileName.lastIndexOf(".")
                                    return dot > 0 ? fileName.slice(0, dot) : fileName
                                }

                                width: strip.unit * (active ? root.expandedWeight : root.collapsedWeight)
                                height: strip.height
                                clip: true

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 420
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Image {
                                    id: shot
                                    anchors.fill: parent
                                    source: "file://" + column.filePath
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.height: 900
                                    opacity: column.active ? 1 : 0.5

                                    Behavior on opacity {
                                        NumberAnimation { duration: 420 }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: !column.active
                                    color: Qt.rgba(0, 0, 0, 0.35)
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    width: Theme.borderWidth
                                    height: parent.height
                                    visible: column.index < state.count - 1
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spaceLg
                                    text: String(column.index + 1).padStart(2, "0")
                                    color: column.active ? Theme.accent : Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.bold: true
                                    style: Text.Outline
                                    styleColor: Qt.rgba(0, 0, 0, 0.75)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    rotation: -90
                                    text: column.label.toUpperCase()
                                    color: Qt.rgba(1, 1, 1, 0.72)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.letterSpacing: 2
                                    opacity: column.active ? 0 : 1
                                    style: Text.Outline
                                    styleColor: Qt.rgba(0, 0, 0, 0.85)

                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 104
                                    opacity: column.active ? 1 : 0
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: "transparent" }
                                        GradientStop { position: 1; color: Qt.rgba(0.03, 0.03, 0.04, 0.93) }
                                    }

                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }

                                    Column {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: Theme.spaceXl
                                        spacing: Theme.spaceXs

                                        Text {
                                            text: column.label
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontTitle
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: {
                                                const size = state.sizeLabelAt(column.index)
                                                if (!column.active) return size
                                                const dimensions = meta.implicitWidth > 0
                                                    ? meta.implicitWidth + "×" + meta.implicitHeight : ""
                                                return dimensions !== "" ? dimensions + "  ·  " + size : size
                                            }
                                            color: Theme.textMuted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSmall
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: column.active
                                    color: "transparent"
                                    border.color: Theme.accent
                                    border.width: Theme.focusWidth
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.activeIndex = column.index
                                    onClicked: {
                                        root.activeIndex = column.index
                                        root.applyActive()
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "←→ browse   enter apply   esc close"
                        color: Theme.textDisabled
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 260
                        horizontalAlignment: Text.AlignRight
                        text: state.directory
                        color: Theme.textDisabled
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideLeft
                    }
                }
            }
        }
    }
}
