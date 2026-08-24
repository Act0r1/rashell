import QtQuick
import qs.core
import qs.modules.workspaces
import qs.modules.clock
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
    required property var audioState
    required property var mediaState
    required property var systemState
    required property var keyboardState
    required property var controlState
    required property var tokenState
    required property var notificationState
    required property var configStore
    required property var coordinator
    required property var osd
    required property var feedback

    implicitWidth: loader.item ? loader.item.implicitWidth : errorLabel.implicitWidth
    implicitHeight: loader.item ? loader.item.implicitHeight : Theme.controlHeight

    readonly property bool known: [
        "rashell.workspaces", "rashell.clock", "rashell.audio", "rashell.media",
        "rashell.screenshot", "rashell.keyboard", "rashell.tray", "rashell.system",
        "rashell.control", "rashell.tokens", "rashell.notifications", "rashell.updates"
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

    Component { id: screenshotComponent; ScreenshotBar {} }
    Component { id: keyboardComponent; KeyboardBar { state: root.keyboardState } }
    Component { id: trayComponent; TrayBar {} }
    Component {
        id: notificationsComponent
        NotificationBar {
            state: root.notificationState
            coordinator: root.coordinator
            outputName: root.outputName
        }
    }
    Component { id: systemComponent; SystemBar { state: root.systemState } }
    Component { id: updatesComponent; UpdatesBar { state: root.systemState } }
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
            systemState: root.systemState
            controlState: root.controlState
            notificationState: root.notificationState
            configStore: root.configStore
            outputName: root.outputName
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.moduleId === "rashell.workspaces" ? workspacesComponent
            : root.moduleId === "rashell.clock" ? clockComponent
            : root.moduleId === "rashell.audio" ? audioComponent
            : root.moduleId === "rashell.media" ? mediaComponent
            : root.moduleId === "rashell.screenshot" ? screenshotComponent
            : root.moduleId === "rashell.keyboard" ? keyboardComponent
            : root.moduleId === "rashell.tray" ? trayComponent
            : root.moduleId === "rashell.notifications" ? notificationsComponent
            : root.moduleId === "rashell.system" ? systemComponent
            : root.moduleId === "rashell.control" ? controlComponent
            : root.moduleId === "rashell.tokens" ? tokensComponent
            : root.moduleId === "rashell.updates" ? updatesComponent : null
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
