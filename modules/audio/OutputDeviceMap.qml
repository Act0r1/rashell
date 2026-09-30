pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var audioState
    property bool animationsEnabled: true
    property int currentIndex: -1
    property Item focusedDevice: null
    property bool animateFocus: false

    signal outputSelected()
    signal focusMoved(real top, real bottom)

    readonly property var devices: audioState ? audioState.outputs : []
    readonly property int rows: Math.max(2, Math.ceil(devices.length / 2))
    readonly property real centerX: width / 2
    readonly property real centerY: height / 2 - 14
    readonly property real ringRadius: 53
    readonly property real focusRadius: 48

    implicitHeight: rows * 154 + 10

    function focusAt(index) {
        const button = deviceRepeater.itemAt(index)
        if (!button) return
        currentIndex = index
        button.forceActiveFocus(Qt.TabFocusReason)
    }

    function focusSelected() {
        const output = audioState ? audioState.output : null
        const selectedIndex = devices.findIndex(function(node) { return output && node.id === output.id })
        if (devices.length > 0) focusAt(Math.max(0, selectedIndex))
        else forceActiveFocus()
    }

    function navigate(dx, dy) {
        const current = deviceRepeater.itemAt(currentIndex)
        if (!current) {
            focusSelected()
            return
        }
        let next = -1
        let bestDistance = Infinity
        for (let index = 0; index < devices.length; index++) {
            const candidate = deviceRepeater.itemAt(index)
            if (!candidate || candidate === current) continue
            const offsetX = candidate.x + candidate.width / 2 - current.x - current.width / 2
            const offsetY = candidate.y - current.y
            const forward = offsetX * dx + offsetY * dy
            if (forward <= 1) continue
            const sideways = Math.abs(offsetX * dy - offsetY * dx)
            const distance = forward + sideways * 4
            if (distance < bestDistance) {
                bestDistance = distance
                next = index
            }
        }
        if (next !== -1) focusAt(next)
    }

    function choose(index) {
        if (index >= 0 && index < devices.length && audioState.selectOutput(devices[index])) outputSelected()
    }

    function handleKey(event) {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        const scanCode = event.nativeScanCode
        if (scanCode === 43 || event.key === Qt.Key_H || event.key === 0x0420 || event.key === Qt.Key_Left) navigate(-1, 0)
        else if (scanCode === 44 || event.key === Qt.Key_J || event.key === 0x041E || event.key === Qt.Key_Down) navigate(0, 1)
        else if (scanCode === 45 || event.key === Qt.Key_K || event.key === 0x041B || event.key === Qt.Key_Up) navigate(0, -1)
        else if (scanCode === 46 || event.key === Qt.Key_L || event.key === 0x0414 || event.key === Qt.Key_Right) navigate(1, 0)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) choose(currentIndex)
        else return
        event.accepted = true
    }

    Keys.onPressed: event => root.handleKey(event)
    onDevicesChanged: if (activeFocus) Qt.callLater(function() { root.focusSelected() })

    Rectangle {
        x: root.centerX - root.ringRadius
        y: root.centerY - root.ringRadius
        width: root.ringRadius * 2
        height: width
        radius: width / 2
        color: "transparent"
        border.color: Qt.alpha(Theme.accent, 0.85)
        border.width: 2
    }

    Repeater {
        id: deviceRepeater
        model: root.devices

        delegate: ActionButton {
            id: device

            required property var modelData
            required property int index

            readonly property bool leftSide: index % 2 === 0
            readonly property int row: Math.floor(index / 2)
            readonly property int sideCount: Math.ceil((root.devices.length - (leftSide ? 0 : 1)) / 2)
            readonly property real socketX: x + width / 2
            readonly property real socketY: y + 42
            readonly property real angle: Math.atan2(socketY - root.centerY, socketX - root.centerX)
            readonly property real lineStartX: root.centerX + Math.cos(angle) * root.ringRadius
            readonly property real lineStartY: root.centerY + Math.sin(angle) * root.ringRadius
            readonly property real connectionRadius: activeFocus ? root.focusRadius : floatingArtwork.width / 2 * floatingArtwork.scale
            readonly property real lineEndX: socketX + (leftSide ? connectionRadius : -connectionRadius)
            readonly property real lineEndY: socketY + (activeFocus ? 0 : floatOffset)
            property real floatOffset: 0

            x: leftSide ? 0 : root.width - width
            y: sideCount === 1 ? root.centerY - 42 : 6 + row * (root.height - height - 12) / (sideCount - 1)
            width: Math.min(140, (root.width - root.ringRadius * 2 - Theme.spaceXl) / 2)
            height: 130
            padding: 0
            selected: root.audioState.output !== null && modelData.id === root.audioState.output.id
            text: root.audioState.nodeLabel(modelData)
            accessibleName: text + (selected ? ", in use" : ", select output")
            toolTipText: text + (selected ? " · In use" : " · Select output")
            onClicked: root.choose(index)
            onActiveFocusChanged: {
                if (activeFocus) {
                    root.animateFocus = root.focusedDevice !== null
                    root.focusedDevice = device
                    root.currentIndex = index
                    root.focusMoved(y, y + height)
                }
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => root.handleKey(event)

            background: Item {}

            Shape {
                x: -device.x
                y: -device.y
                width: root.width
                height: root.height
                z: -1
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Qt.alpha(Theme.accent, device.activeFocus ? 1 : device.selected ? 0.9 : 0.66)
                    strokeWidth: device.activeFocus ? 2.4 : device.selected ? 2 : 1.5
                    capStyle: ShapePath.FlatCap
                    startX: device.lineStartX
                    startY: device.lineStartY

                    Behavior on strokeColor { ColorAnimation { duration: 280; easing.type: Easing.InOutCubic } }
                    Behavior on strokeWidth { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }

                    PathCubic {
                        x: device.lineEndX
                        y: device.lineEndY
                        control1X: device.lineStartX + (device.leftSide ? -42 : 42)
                        control1Y: device.lineStartY
                        control2X: device.lineEndX + (device.leftSide ? 42 : -42)
                        control2Y: device.lineEndY
                    }
                }
            }

            contentItem: Item {
                Item {
                    id: floatingArtwork
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4 + device.floatOffset
                    width: 76
                    height: 76
                    scale: device.down ? 0.95 : device.activeFocus ? 1.1 : device.hovered ? 1.06 : 1

                    Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.alpha(Theme.surface, 0.16)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.alpha(Theme.accent, device.selected ? 0.12 : device.hovered ? 0.07 : 0)
                        border.color: Qt.alpha(Theme.accent, device.selected ? 0.52 : device.hovered ? 0.24 : 0)

                        Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 260; easing.type: Easing.InOutCubic } }
                    }

                    OutputArtwork {
                        anchors.centerIn: parent
                        width: 56
                        height: 56
                        kind: root.audioState.outputKind(device.modelData)
                        opacity: device.selected || device.hovered || device.activeFocus ? 1 : 0.8

                        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: 19
                        height: 19
                        radius: width / 2
                        color: Theme.accent
                        opacity: device.selected ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: Theme.textOnAccent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    y: 100
                    text: device.text
                    color: device.selected || device.activeFocus ? Theme.text : Theme.textMuted
                    style: Text.Outline
                    styleColor: Qt.alpha(Theme.background, 0.9)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: device.selected ? Font.Medium : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight

                    Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.InOutCubic } }
                }
            }

            SequentialAnimation on floatOffset {
                running: root.visible && root.animationsEnabled
                loops: Animation.Infinite

                NumberAnimation {
                    to: -6
                    duration: 1850 + device.index * 150
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 6
                    duration: 1850 + device.index * 150
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    Rectangle {
        x: root.focusedDevice ? root.focusedDevice.x + root.focusedDevice.width / 2 - width / 2 : 0
        y: root.focusedDevice ? root.focusedDevice.y + 42 - height / 2 : 0
        width: root.focusRadius * 2
        height: width
        radius: width / 2
        color: Qt.alpha(Theme.accent, 0.06)
        border.color: Theme.accent
        border.width: Theme.focusWidth
        opacity: root.activeFocus && root.focusedDevice ? 1 : 0

        Behavior on x {
            enabled: root.animateFocus
            NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
        }
        Behavior on y {
            enabled: root.animateFocus
            NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
        }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutCubic } }
    }
}
