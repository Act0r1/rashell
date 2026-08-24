import QtQuick
import qs.core
import qs.modules.workspaces
import qs.modules.clock
import qs.modules.audio

Item {
    id: root

    required property string moduleId
    required property string outputName
    required property var workspaceState
    required property var clockState
    required property var audioState
    required property var coordinator
    required property var osd
    required property var feedback

    implicitWidth: loader.item ? loader.item.implicitWidth : errorLabel.implicitWidth
    implicitHeight: loader.item ? loader.item.implicitHeight : Theme.controlHeight

    readonly property bool known: ["rashell.workspaces", "rashell.clock", "rashell.audio"].indexOf(moduleId) !== -1

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

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.moduleId === "rashell.workspaces" ? workspacesComponent
            : root.moduleId === "rashell.clock" ? clockComponent
            : root.moduleId === "rashell.audio" ? audioComponent : null
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
