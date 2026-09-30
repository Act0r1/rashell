import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

Item {
    id: root

    required property var state
    required property var coordinator
    required property var configStore
    required property string outputName
    property bool minimal: false

    implicitWidth: status.implicitWidth + 16
    implicitHeight: minimal ? 26 : Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        padding: 0
        Accessible.name: root.state.available
            ? "Weather in " + root.state.location + ", " + root.state.condition + ", " + root.state.temperatureCelsius + " degrees Celsius"
            : "Weather unavailable"
        Accessible.role: Accessible.Button
        BarToolTip {
            visible: button.hovered && !root.coordinator.opened
            text: root.state.available
                ? (root.state.location ? root.state.location + " · " : "") + root.state.condition
                : "Weather unavailable"
        }

        contentItem: Item {
            Row {
                id: status
                anchors.centerIn: parent
                spacing: 5

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.state.icon
                    color: Theme.accent
                    style: root.minimal ? Text.Raised : Text.Normal
                    styleColor: "#c0000000"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.state.temperatureText
                    color: root.state.available ? Theme.text : Theme.textMuted
                    style: root.minimal ? Text.Raised : Text.Normal
                    styleColor: "#c0000000"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.bold: true
                }
            }
        }

        background: Rectangle {
            visible: !root.minimal
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.visualFocus ? Theme.focus : "transparent"
            border.width: button.visualFocus ? Theme.focusWidth : Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "weather",
            root,
            "center",
            Quickshell.shellDir + "/modules/weather/WeatherPanel.qml",
            {
                coordinator: root.coordinator,
                weatherState: root.state,
                configStore: root.configStore
            }
        )
    }

    Component.onCompleted: coordinator.registerAnchor("weather", outputName, root, "center")
    Component.onDestruction: coordinator.unregisterAnchor("weather", outputName, root)
}
