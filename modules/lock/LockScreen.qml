pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Scope {
    id: root

    required property var configStore

    property bool locked: false
    property bool pendingSuspend: false
    property date now: new Date()

    readonly property string wallpaperSource: root.configStore.wallpaperPath.indexOf("/") === 0
        ? "file://" + root.configStore.wallpaperPath : root.configStore.wallpaperPath
    readonly property string displayName: {
        const username = lockContext.username || "User"
        return username.charAt(0).toUpperCase() + username.slice(1)
    }

    function lock() {
        pendingSuspend = false
        lockContext.reset()
        locked = true
    }

    function lockAndSuspend() {
        pendingSuspend = true
        lockContext.reset()
        locked = true
        suspendWhenSecure()
    }

    function suspendWhenSecure() {
        if (!pendingSuspend || !sessionLock.secure) return
        pendingSuspend = false
        Quickshell.execDetached(["systemctl", "suspend"])
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.locked
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    LockContext {
        id: lockContext
        onUnlocked: {
            root.pendingSuspend = false
            root.locked = false
            lockContext.reset()
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.locked
        onSecureStateChanged: root.suspendWhenSecure()
        onLockStateChanged: {
            if (!locked && !secure) root.pendingSuspend = false
        }

        WlSessionLockSurface {
            id: lockSurface
            color: Theme.background

            Image {
                anchors.fill: parent
                source: root.wallpaperSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.02, 0.015, 0.025, 0.7)
            }

            Rectangle {
                width: Math.min(540, lockSurface.width - 48)
                height: 430
                anchors.centerIn: parent
                color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.94)
                border.color: Theme.borderInteractive
                border.width: Theme.borderWidth
                radius: Math.max(12, Theme.radius)

                MouseArea {
                    anchors.fill: parent
                    onClicked: passwordField.forceActiveFocus()
                }

                Column {
                    anchors {
                        fill: parent
                        margins: 36
                    }
                    spacing: Theme.spaceLg

                    Text {
                        width: parent.width
                        text: Qt.formatTime(root.now, "HH:mm")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 58
                        font.weight: Font.Light
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: Qt.formatDate(root.now, "dddd, d MMMM")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        width: 64
                        height: 64
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: width / 2
                        color: Theme.surfaceRaised
                        border.color: Theme.accent
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: root.displayName.charAt(0)
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 30
                            font.bold: true
                        }
                    }

                    Text {
                        width: parent.width
                        text: root.displayName
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: "PASSWORD"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        font.letterSpacing: 1.5
                    }

                    Row {
                        width: parent.width
                        height: 52
                        spacing: Theme.spaceMd

                        TextField {
                            id: passwordField

                            width: parent.width - submitButton.width - parent.spacing
                            height: parent.height
                            enabled: !lockContext.authenticating
                            echoMode: lockContext.responseVisible || revealButton.checked
                                ? TextInput.Normal : TextInput.Password
                            passwordMaskDelay: 0
                            placeholderText: "Enter your password"
                            placeholderTextColor: Theme.textDisabled
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.textOnAccent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            leftPadding: Theme.spaceLg
                            rightPadding: revealButton.width + Theme.spaceLg
                            selectByMouse: true
                            Accessible.name: "Password"
                            onTextEdited: lockContext.password = text
                            onAccepted: lockContext.submit()

                            background: Rectangle {
                                color: Theme.surfaceRaised
                                border.color: lockContext.failed ? Theme.danger
                                    : passwordField.activeFocus ? Theme.accent : Theme.borderInteractive
                                border.width: passwordField.activeFocus ? Theme.focusWidth : Theme.borderWidth
                                radius: Math.max(8, Theme.radius)
                            }

                            ActionButton {
                                id: revealButton

                                width: 38
                                height: 38
                                anchors {
                                    right: parent.right
                                    rightMargin: 7
                                    verticalCenter: parent.verticalCenter
                                }
                                checkable: true
                                text: checked ? "󰈉" : "󰈈"
                                accessibleName: checked ? "Hide password" : "Show password"
                                onClicked: passwordField.forceActiveFocus()
                            }

                            Connections {
                                target: lockContext
                                function onPasswordChanged() {
                                    if (passwordField.text !== lockContext.password) {
                                        passwordField.text = lockContext.password
                                    }
                                }
                            }

                            Component.onCompleted: forceActiveFocus()
                        }

                        ActionButton {
                            id: submitButton
                            width: 52
                            height: parent.height
                            text: lockContext.authenticating ? "…" : "→"
                            selected: true
                            enabled: !lockContext.authenticating && lockContext.password.length > 0
                            accessibleName: "Unlock"
                            onClicked: lockContext.submit()
                        }
                    }

                    Text {
                        width: parent.width
                        text: lockContext.message
                        color: lockContext.failed ? Theme.danger : Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
