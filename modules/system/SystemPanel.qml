pragma ComponentBehavior: Bound

import QtQuick
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var systemState

    property int selectedProcessId: 0
    property string selectedProcessName: ""

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    function toggleProcessSignals(processId, processName) {
        if (selectedProcessId === processId) {
            selectedProcessId = 0
            selectedProcessName = ""
            return
        }

        selectedProcessId = processId
        selectedProcessName = processName
    }

    function sendSelectedSignal(signalName) {
        if (!systemState.sendProcessSignal(selectedProcessId, signalName)) return
        selectedProcessId = 0
        selectedProcessName = ""
    }

    component MetricCard: Rectangle {
        id: card

        required property string label
        required property string value
        required property string detail
        property real progress: 0
        property bool showGraph: false
        property var history: []

        height: 112
        color: Theme.surfaceRaised
        border.color: Theme.border
        border.width: Theme.borderWidth
        radius: Theme.radius

        Column {
            anchors {
                fill: parent
                margins: Theme.spaceLg
            }
            spacing: Theme.spaceSm

            Text {
                width: parent.width
                text: card.label
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Text {
                width: parent.width
                text: card.value
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: card.detail
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }

            Canvas {
                id: graph

                width: parent.width
                height: 22
                visible: card.showGraph
                antialiasing: true

                onPaint: {
                    const context = getContext("2d")
                    context.clearRect(0, 0, width, height)
                    if (!card.history || card.history.length < 2) return

                    context.beginPath()
                    context.strokeStyle = Theme.accent
                    context.lineWidth = 2
                    for (let index = 0; index < card.history.length; index++) {
                        const x = index * width / (card.history.length - 1)
                        const percent = Math.max(0, Math.min(100, Number(card.history[index])))
                        const y = height - 1 - percent * (height - 2) / 100
                        if (index === 0) context.moveTo(x, y)
                        else context.lineTo(x, y)
                    }
                    context.stroke()
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            Rectangle {
                width: parent.width
                height: Theme.sliderTrackHeight
                visible: !card.showGraph
                color: Theme.border
                radius: height / 2

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, card.progress))
                    height: parent.height
                    color: Theme.accent
                    radius: parent.radius
                }
            }
        }

        onHistoryChanged: graph.requestPaint()
    }

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: panel

        width: parent.width
        title: "System monitor"
        contentWidth: 430
        onCloseRequested: root.coordinator.close("close-system")

        Column {
            width: parent.width
            spacing: Theme.spaceLg

            Row {
                width: parent.width

                Text {
                    width: parent.width / 2
                    text: "SYSTEM"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    font.letterSpacing: 2
                }

                Text {
                    width: parent.width / 2
                    text: "UP " + root.systemState.formatUptime(root.systemState.uptimeSeconds)
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    horizontalAlignment: Text.AlignRight
                }
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: Theme.spaceMd

                MetricCard {
                    width: (parent.width - parent.spacing) / 2
                    label: "CPU"
                    value: root.systemState.cpuPercent + "%"
                    detail: "CURRENT LOAD"
                    showGraph: true
                    history: root.systemState.cpuHistory
                }

                MetricCard {
                    width: (parent.width - parent.spacing) / 2
                    label: "MEMORY"
                    value: root.systemState.memoryPercent + "%"
                    detail: root.systemState.formatBytes(root.systemState.memoryUsedBytes, "")
                        + " / " + root.systemState.formatBytes(root.systemState.memoryTotalBytes, "")
                    progress: root.systemState.memoryPercent / 100
                }

                MetricCard {
                    width: (parent.width - parent.spacing) / 2
                    label: "TEMPERATURE"
                    value: root.systemState.temperatureCelsius >= 0
                        ? Math.round(root.systemState.temperatureCelsius) + " °C" : "N/A"
                    detail: root.systemState.temperatureCelsius >= 0 ? "SYSTEM SENSOR" : "SENSOR UNAVAILABLE"
                    progress: root.systemState.temperatureCelsius >= 0
                        ? root.systemState.temperatureCelsius / 100 : 0
                }

                MetricCard {
                    width: (parent.width - parent.spacing) / 2
                    label: "DISK"
                    value: root.systemState.formatBytes(root.systemState.diskFreeBytes, "") + " FREE"
                    detail: "OF " + root.systemState.formatBytes(root.systemState.diskTotalBytes, "")
                    progress: root.systemState.diskUsedPercent / 100
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spaceSm

                Row {
                    width: parent.width

                    Text {
                        width: parent.width - 240 - Theme.spaceMd
                        text: "PROCESS"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.letterSpacing: 1
                    }

                    Text {
                        width: 65
                        text: "CPU"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        horizontalAlignment: Text.AlignRight
                        font.letterSpacing: 1
                    }

                    Text {
                        width: 95
                        text: "MEMORY"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        horizontalAlignment: Text.AlignRight
                        font.letterSpacing: 1
                    }

                    Item {
                        width: Theme.spaceMd
                        height: 1
                    }

                    Text {
                        width: 80
                        text: "ACTION"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        horizontalAlignment: Text.AlignRight
                        font.letterSpacing: 1
                    }
                }

                Repeater {
                    model: root.systemState.topProcesses

                    Rectangle {
                        required property int processId
                        required property string processName
                        required property real cpuPercent
                        required property real memoryBytes

                        width: parent.width
                        height: Theme.controlHeight
                        color: "transparent"

                        Row {
                            anchors.fill: parent

                            Text {
                                width: parent.width - 240 - Theme.spaceMd
                                anchors.verticalCenter: parent.verticalCenter
                                text: processName
                                textFormat: Text.PlainText
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                elide: Text.ElideRight
                            }

                            Text {
                                width: 65
                                anchors.verticalCenter: parent.verticalCenter
                                text: cpuPercent.toFixed(1) + "%"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                width: 95
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.systemState.formatBytes(memoryBytes, "")
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                horizontalAlignment: Text.AlignRight
                            }

                            Item {
                                width: Theme.spaceMd
                                height: 1
                            }

                            ActionButton {
                                width: 80
                                height: Theme.controlHeight
                                text: "SIGNAL"
                                selected: root.selectedProcessId === processId
                                accessibleName: "Choose signal for " + processName + ", PID " + processId
                                onClicked: root.toggleProcessSignals(processId, processName)
                            }
                        }
                    }
                }

                Text {
                    visible: root.systemState.topProcesses.count === 0
                    width: parent.width
                    height: 28
                    text: "PROCESS DATA UNAVAILABLE"
                    color: Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }

                Rectangle {
                    width: parent.width
                    height: 106
                    visible: root.selectedProcessId > 0
                    color: Theme.surfaceRaised
                    border.color: Theme.borderInteractive
                    border.width: Theme.borderWidth
                    radius: Theme.radius

                    Column {
                        anchors {
                            fill: parent
                            margins: Theme.spaceMd
                        }
                        spacing: Theme.spaceMd

                        Text {
                            width: parent.width
                            text: "SEND SIGNAL TO " + root.selectedProcessName
                                + " · PID " + root.selectedProcessId
                            textFormat: Text.PlainText
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spaceSm

                            Repeater {
                                model: ["TERM", "KILL", "STOP", "CONT", "HUP"]

                                ActionButton {
                                    required property string modelData

                                    width: (parent.width - Theme.spaceSm * 4) / 5
                                    height: Theme.controlHeight
                                    text: modelData
                                    selected: modelData === "TERM"
                                    accessibleName: "Send SIG" + modelData + " to " + root.selectedProcessName
                                    onClicked: root.sendSelectedSignal(modelData)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: "TERM end · KILL force · STOP pause · CONT resume · HUP reload"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: systemState.refreshStats()
}
