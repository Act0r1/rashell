import QtQuick
import qs.core
import qs.modules.workspaces
import qs.modules.clock
import qs.modules.weather
import qs.modules.audio
import qs.modules.media
import qs.modules.system
import qs.modules.notifications

Item {
    id: root

    required property string moduleId
    required property string outputName
    required property var workspaceState
    required property var clockState
    required property var weatherState
    required property var audioState
    required property var mediaState
    required property var screenshotState
    required property var systemState
    required property var keyboardState
    required property var controlState
    required property var tokenState
    required property var notificationState
    required property var sessionModeState
    required property var textCaptureState
    required property var configStore
    required property var barEditor
    required property var lockScreen
    required property var wallpaperPicker
    required property var coordinator
    required property var osd
    required property var feedback

    readonly property Item moduleItem: loader.item as Item
    readonly property bool emptyModule: moduleItem && (!moduleItem.visible || moduleItem.implicitWidth <= 0)
    readonly property int traySpacing: root.moduleId === "rashell.tray" && !emptyModule ? 12 : 0

    implicitWidth: emptyModule ? 0 : moduleItem
        ? Math.max(Theme.controlHeight, moduleItem.implicitWidth) + traySpacing : errorLabel.implicitWidth
    implicitHeight: moduleItem ? moduleItem.implicitHeight : Theme.controlHeight

    readonly property bool known: [
        "rashell.workspaces", "rashell.clock", "rashell.weather", "rashell.audio", "rashell.media",
        "rashell.screenshot", "rashell.keyboard", "rashell.tray", "rashell.bluetooth",
        "rashell.system", "rashell.control", "rashell.tokens", "rashell.notifications", "rashell.updates"
    ].indexOf(moduleId) !== -1

    Component {
        id: workspacesComponent
        WorkspaceBar {
            state: root.workspaceState
            outputName: root.outputName
        }
    }

    Component {
        id: clockComponent
        ClockBar {
            state: root.clockState
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }

    Component {
        id: weatherComponent
        WeatherBar {
            state: root.weatherState
            coordinator: root.coordinator
            configStore: root.configStore
            outputName: root.outputName
        }
    }

    Component {
        id: audioComponent
        AudioBar {
            state: root.audioState
            coordinator: root.coordinator
            osd: root.osd
            feedback: root.feedback
            outputName: root.outputName
        }
    }

    Component {
        id: mediaComponent
        MediaBar {
            state: root.mediaState
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }

    Component {
        id: screenshotComponent
        ScreenshotBar {
            state: root.screenshotState
            coordinator: root.coordinator
            configStore: root.configStore
            outputName: root.outputName
        }
    }
    Component { id: keyboardComponent; KeyboardBar { state: root.keyboardState } }
    Component {
        id: trayComponent
        TrayBar {
            configStore: root.configStore
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }
    Component {
        id: bluetoothComponent
        BluetoothBar {
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }
    Component {
        id: notificationsComponent
        NotificationBar {
            state: root.notificationState
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }
    Component {
        id: systemComponent
        SystemBar {
            state: root.systemState
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }
    Component {
        id: updatesComponent
        UpdatesBar {
            state: root.systemState
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }
    Component {
        id: tokensComponent
        TokenBar {
            state: root.tokenState
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }

    Component {
        id: controlComponent
        ControlBar {
            coordinator: root.coordinator
            audioState: root.audioState
            screenshotState: root.screenshotState
            systemState: root.systemState
            controlState: root.controlState
            notificationState: root.notificationState
            sessionModeState: root.sessionModeState
            textCaptureState: root.textCaptureState
            configStore: root.configStore
            barEditor: root.barEditor
            lockScreen: root.lockScreen
            wallpaperPicker: root.wallpaperPicker
            outputName: root.outputName
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        anchors.rightMargin: root.traySpacing
        sourceComponent: root.moduleId === "rashell.workspaces" ? workspacesComponent
            : root.moduleId === "rashell.clock" ? clockComponent
            : root.moduleId === "rashell.weather" ? weatherComponent
            : root.moduleId === "rashell.audio" ? audioComponent
            : root.moduleId === "rashell.media" ? mediaComponent
            : root.moduleId === "rashell.screenshot" ? screenshotComponent
            : root.moduleId === "rashell.keyboard" ? keyboardComponent
            : root.moduleId === "rashell.tray" ? trayComponent
            : root.moduleId === "rashell.bluetooth" ? bluetoothComponent
            : root.moduleId === "rashell.notifications" ? notificationsComponent
            : root.moduleId === "rashell.system" ? systemComponent
            : root.moduleId === "rashell.control" ? controlComponent
            : root.moduleId === "rashell.tokens" ? tokensComponent
            : root.moduleId === "rashell.updates" ? updatesComponent : null
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceSm
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.borderWidth
        height: 16
        color: Theme.border
        visible: root.traySpacing > 0
    }

    Text {
        id: errorLabel
        visible: !root.known
        text: "MODULE !"
        color: Theme.danger
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
    }
}
