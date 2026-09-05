import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root

    required property var state
    required property var coordinator
    required property var configStore
    required property string outputName

    implicitWidth: status.implicitWidth + 16
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: root.state.available
            ? "Weather in " + root.state.location + ", " + root.state.condition + ", " + root.state.temperatureCelsius + " degrees Celsius"
            : "Weather unavailable"
        Accessible.role: Accessible.Button
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: root.state.available
            ? (root.state.location ? root.state.location + " · " : "") + root.state.condition
            : "Weather unavailable"

        contentItem: Row {
            id: status
            spacing: 5

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.state.icon
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.state.temperatureText
                color: root.state.available ? Theme.text : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.bold: true
            }
        }

        background: Rectangle {
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: "transparent"
            border.width: Theme.borderWidth
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
