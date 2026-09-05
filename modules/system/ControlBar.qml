import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root
    required property var coordinator
    required property var audioState
    required property var screenshotState
    required property var systemState
    required property var controlState
    required property var notificationState
    required property var sessionModeState
    required property var textCaptureState
    required property var configStore
    required property var barEditor
    required property var lockScreen
    required property var wallpaperPicker
    required property string outputName
    implicitWidth: Theme.compactControlSize
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "Control center"

        contentItem: Text {
            text: "󰒓"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "control"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: 1
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "control",
            root,
            "right",
            Quickshell.shellDir + "/modules/system/ControlPanel.qml",
            {
                coordinator: root.coordinator,
                audioState: root.audioState,
                screenshotState: root.screenshotState,
                systemState: root.systemState,
                controlState: root.controlState,
                notificationState: root.notificationState,
                sessionModeState: root.sessionModeState,
                textCaptureState: root.textCaptureState,
                configStore: root.configStore,
                barEditor: root.barEditor,
                lockScreen: root.lockScreen,
                wallpaperPicker: root.wallpaperPicker,
                outputName: root.outputName
            }
        )
    }

    Component.onCompleted: coordinator.registerAnchor("control", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("control", outputName, root)
}
