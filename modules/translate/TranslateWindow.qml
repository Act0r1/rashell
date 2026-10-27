pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

// Centered translate card: live EN<->RU translation, Enter copies the result and closes.
Scope {
    id: root

    required property var translateState
    required property var coordinator
    property bool locked: false
    property var targetScreen: null

    function preferredScreen() {
        const outputName = coordinator && coordinator.preferredOutputName
            ? String(coordinator.preferredOutputName()) : ""
        const screens = Quickshell.screens || []
        for (let index = 0; index < screens.length; index++) {
            if (String(screens[index].name || "") === outputName) return screens[index]
        }
        return screens.length > 0 ? screens[0] : null
    }

    Connections {
        target: root.translateState
        function onOpenedChanged() {
            if (!root.translateState.opened) return
            root.coordinator.close("translate")
            root.targetScreen = root.preferredScreen()
            source.text = root.translateState.input
            source.cursorPosition = source.length
        }
    }

    PanelWindow {
        id: window
        screen: root.targetScreen
        visible: root.translateState.opened && root.targetScreen !== null && !root.locked
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "rashell-translate"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Shortcut {
            sequence: "Esc"
            onActivated: root.translateState.close()
        }

        Shortcut {
            sequence: "Ctrl+S"
            onActivated: root.translateState.swap()
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.42)

            MouseArea {
                anchors.fill: parent
                onClicked: root.translateState.close()
            }
        }

        PanelFrame {
            id: card
            anchors.centerIn: parent
            width: Math.min(560, window.width - Theme.spaceXl * 2)
            contentWidth: 560
            title: "Translate"
            onCloseRequested: root.translateState.close()

            MouseArea {
                parent: card
                anchors.fill: parent
                z: -1
                onClicked: event => event.accepted = true
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                ActionButton {
                    text: root.translateState.sourceCode
                    selected: true
                    toolTipText: ""
                    focusPolicy: Qt.NoFocus
                }

                ActionButton {
                    text: "⇄"
                    toolTipText: "Swap direction (Ctrl+S)"
                    focusPolicy: Qt.NoFocus
                    onClicked: root.translateState.swap()
                }

                ActionButton {
                    text: root.translateState.targetCode
                    toolTipText: ""
                    focusPolicy: Qt.NoFocus
                }
            }

            Rectangle {
                width: parent.width
                height: Math.max(88, source.implicitHeight + Theme.spaceLg * 2)
                color: Theme.surfaceRaised
                border.color: source.activeFocus ? Theme.accent : Theme.border
                border.width: source.activeFocus ? Theme.focusWidth : Theme.borderWidth
                radius: Theme.radiusSmall

                TextArea {
                    id: source
                    anchors.fill: parent
                    anchors.margins: Theme.spaceSm
                    placeholderText: "Type or paste text…"
                    placeholderTextColor: Theme.textDisabled
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.textOnAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    wrapMode: TextEdit.Wrap
                    focus: root.translateState.opened
                    background: Item {}
                    Accessible.name: "Text to translate"

                    onTextChanged: if (text !== root.translateState.input) root.translateState.setInput(text)

                    Keys.onReturnPressed: event => {
                        if (event.modifiers & Qt.ShiftModifier) event.accepted = false
                        else root.translateState.commit()
                    }
                    Keys.onEnterPressed: event => root.translateState.commit()
                }
            }

            Rectangle {
                width: parent.width
                height: Math.max(88, resultText.implicitHeight + Theme.spaceLg * 2)
                color: Theme.surfaceRaised
                border.color: Theme.border
                border.width: Theme.borderWidth
                radius: Theme.radiusSmall

                Text {
                    id: resultText
                    anchors.fill: parent
                    anchors.margins: Theme.spaceLg
                    text: root.translateState.result !== "" ? root.translateState.result : "Translation appears here"
                    color: root.translateState.result !== "" ? Theme.text : Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.WordWrap
                }

                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Theme.spaceMd
                    visible: root.translateState.result !== ""
                    text: root.translateState.latencyMs + " ms"
                    color: Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }
            }

            Text {
                width: parent.width
                visible: root.translateState.error !== ""
                text: root.translateState.error
                color: Theme.danger
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                visible: root.translateState.history.length > 0
                text: "Recent"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Theme.fontWeightStrong
            }

            Column {
                width: parent.width
                visible: root.translateState.history.length > 0

                Repeater {
                    model: root.translateState.history

                    ActionButton {
                        required property var modelData
                        width: parent.width
                        implicitHeight: Theme.rowHeight
                        flat: true
                        alignment: Text.AlignLeft
                        focusPolicy: Qt.NoFocus
                        text: modelData.source + "  →  " + modelData.result + "   · " + modelData.direction
                        toolTipText: ""
                        onClicked: {
                            root.translateState.reuse(modelData)
                            source.text = modelData.source
                            source.cursorPosition = source.length
                            source.forceActiveFocus()
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "Enter copy & close · Shift+Enter new line · Ctrl+S swap · Esc close"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }
        }
    }
}
