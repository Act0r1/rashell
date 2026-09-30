pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

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

    SleepLock {
        secure: sessionLock.secure
        onLockRequested: if (!root.locked) root.lock()
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

            property var themeConfig: ({})
            readonly property string themeDir: "/usr/share/sddm/themes/ii-pixel/"
            readonly property string backgroundSource: themeConfig.background
                ? "file://" + (themeConfig.background.indexOf("/") === 0
                    ? themeConfig.background : themeDir + themeConfig.background)
                : root.wallpaperSource
            property string currentView: "clock"
            property bool loginFailed: false
            readonly property bool showPasswordView: currentView === "password"
            readonly property color colPrimary: themeConfig.primaryColor || "#cba6f7"
            readonly property color colOnPrimary: themeConfig.onPrimaryColor || "#1e1e2e"
            readonly property color colSurface: themeConfig.surfaceColor || "#1e1e2e"
            readonly property color colSurfaceContainer: themeConfig.surfaceContainerColor || "#181825"
            readonly property color colOnSurface: themeConfig.onSurfaceColor || "#cdd6f4"
            readonly property color colOnSurfaceVariant: themeConfig.onSurfaceVariantColor || "#9399b2"
            readonly property color colBackground: themeConfig.backgroundColor || "#1e1e2e"
            readonly property color colError: themeConfig.errorColor || "#f38ba8"
            readonly property real blurRadius: isNaN(Number(themeConfig.blurRadius))
                ? 64 : Number(themeConfig.blurRadius)
            readonly property bool materialShapeChars: String(
                themeConfig.materialShapeChars || "false"
            ).toLowerCase() === "true"

            color: colBackground

            function parseTheme(text: string): var {
                const values = {}
                const lines = text.split(/\r?\n/)
                let inGeneral = false
                for (let index = 0; index < lines.length; index++) {
                    const line = lines[index].trim()
                    if (line.length === 0 || line.charAt(0) === "#" || line.charAt(0) === ";") continue
                    if (line.charAt(0) === "[") {
                        inGeneral = line === "[General]"
                        continue
                    }
                    if (!inGeneral) continue
                    const separator = line.indexOf("=")
                    if (separator <= 0) continue
                    values[line.slice(0, separator).trim()] = line.slice(separator + 1).trim()
                }
                return values
            }

            function symbolFont(): string {
                return materialSymbolsFont.status === FontLoader.Ready ? materialSymbolsFont.name : ""
            }

            function switchToPassword(capturedText: string) {
                currentView = "password"
                Qt.callLater(function() {
                    passwordBox.forceActiveFocus()
                    if (capturedText.length === 1 && capturedText.charCodeAt(0) >= 32) {
                        lockContext.password += capturedText
                    }
                })
            }

            function attemptUnlock() {
                if (lockContext.authenticating || lockContext.password.length === 0) return
                loginFailed = false
                lockContext.submit()
            }

            FileView {
                id: themeFile

                path: "/usr/share/sddm/themes/ii-pixel/theme.conf"
                blockLoading: true
                watchChanges: true
                printErrors: false

                onLoaded: lockSurface.themeConfig = lockSurface.parseTheme(text())
                onFileChanged: reload()
                onLoadFailed: lockSurface.themeConfig = ({})
            }

            FontLoader {
                id: materialSymbolsFont
                source: "fonts/MaterialSymbolsRounded.ttf"
            }

            Connections {
                target: root

                function onLockedChanged() {
                    if (!root.locked) return
                    lockSurface.currentView = "clock"
                    lockSurface.loginFailed = false
                    hintText.hintOpacity = 0.7
                    Qt.callLater(function() {
                        visualRoot.forceActiveFocus()
                    })
                }
            }

            Connections {
                target: lockContext

                function onPasswordChanged() {
                    if (passwordBox.text !== lockContext.password) passwordBox.text = lockContext.password
                }

                function onFailedChanged() {
                    if (!lockContext.failed) {
                        lockSurface.loginFailed = false
                        return
                    }
                    lockSurface.loginFailed = true
                    shakeAnimation.restart()
                    Qt.callLater(function() {
                        passwordBox.forceActiveFocus()
                    })
                }

                function onUnlocked() {
                    unlockFadeAnimation.start()
                }
            }

            MouseArea {
                id: visualRoot

                anchors.fill: parent
                focus: true
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: function(mouse) {
                    if (!lockSurface.showPasswordView) lockSurface.switchToPassword("")
                    else passwordBox.forceActiveFocus()
                }
                onPositionChanged: {
                    if (lockSurface.showPasswordView) passwordBox.forceActiveFocus()
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        if (lockContext.password.length > 0) lockContext.password = ""
                        else if (lockSurface.showPasswordView) {
                            lockSurface.currentView = "clock"
                            visualRoot.forceActiveFocus()
                        }
                        event.accepted = true
                        return
                    }
                    if (!lockSurface.showPasswordView) {
                        lockSurface.switchToPassword(event.text || "")
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        lockSurface.attemptUnlock()
                        event.accepted = true
                        return
                    }
                    if (!passwordBox.activeFocus) passwordBox.forceActiveFocus()
                }

                Rectangle {
                    anchors.fill: parent
                    color: lockSurface.colBackground
                    z: -2
                }

                Image {
                    id: wallpaper

                    anchors.fill: parent
                    source: lockSurface.backgroundSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: lockSurface.showPasswordView ? 1 : 0
                        blurMax: Math.round(lockSurface.blurRadius)
                        Behavior on blur {
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }
                    transform: Scale {
                        origin.x: wallpaper.width / 2
                        origin.y: wallpaper.height / 2
                        xScale: lockSurface.showPasswordView ? 1.15 : 1
                        yScale: lockSurface.showPasswordView ? 1.15 : 1
                        Behavior on xScale {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                        Behavior on yScale {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.1) }
                        GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.05) }
                        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.3) }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.4)
                    opacity: lockSurface.showPasswordView ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                    }
                }

                Item {
                    id: clockView

                    anchors.fill: parent
                    opacity: lockSurface.showPasswordView ? 0 : 1
                    visible: opacity > 0
                    scale: lockSurface.showPasswordView ? 0.92 : 1
                    Behavior on opacity {
                        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 450; easing.type: Easing.OutBack }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -80
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatTime(root.now, "hh:mm")
                            font.pixelSize: 108
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            color: lockSurface.colOnSurface
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: 1
                                shadowVerticalOffset: 3
                                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDate(root.now, "dddd, d MMMM")
                            font.pixelSize: 22
                            color: lockSurface.colOnSurface
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: 1
                                shadowVerticalOffset: 1
                                shadowColor: Qt.rgba(0, 0, 0, 0.4)
                            }
                        }
                    }

                    Text {
                        id: hintText
                        property real hintOpacity: 0.7

                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Press any key or click to unlock"
                        font.pixelSize: 15
                        color: lockSurface.colOnSurfaceVariant
                        opacity: hintOpacity
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowBlur: 1
                            shadowVerticalOffset: 1
                            shadowColor: Qt.rgba(0, 0, 0, 0.3)
                        }
                        Behavior on hintOpacity {
                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                        }
                        Timer {
                            interval: 4000
                            running: clockView.visible
                            onTriggered: hintText.hintOpacity = 0
                        }
                    }
                }

                Item {
                    id: passwordView

                    anchors.fill: parent
                    opacity: lockSurface.showPasswordView ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity {
                        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }

                    ColumnLayout {
                        id: loginContent
                        property real animationProgress: lockSurface.showPasswordView ? 1 : 0

                        anchors.centerIn: parent
                        spacing: 16
                        Behavior on animationProgress {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 100
                            implicitHeight: 100
                            opacity: Math.min(1, loginContent.animationProgress * 3)
                            scale: 0.8 + 0.2 * Math.min(1, loginContent.animationProgress * 3)
                            Behavior on scale {
                                NumberAnimation { duration: 350; easing.type: Easing.OutBack }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 108
                                height: 108
                                radius: width / 2
                                color: "transparent"
                                border.color: lockSurface.colPrimary
                                border.width: 3
                                opacity: 0.8
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowBlur: 1
                                    shadowVerticalOffset: 4
                                    shadowColor: Qt.rgba(0, 0, 0, 0.4)
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: lockSurface.colPrimary

                                Image {
                                    id: homeAvatar
                                    anchors.fill: parent
                                    source: "file://" + Quickshell.env("HOME") + "/.face.icon"
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    mipmap: true
                                    visible: false
                                }
                                Image {
                                    id: accountsAvatar
                                    anchors.fill: parent
                                    source: homeAvatar.status === Image.Ready ? ""
                                        : "file:///var/lib/AccountsService/icons/" + lockContext.username
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    mipmap: true
                                    visible: false
                                }
                                Rectangle {
                                    id: avatarMask
                                    anchors.fill: parent
                                    radius: width / 2
                                    visible: false
                                    layer.enabled: true
                                }
                                MultiEffect {
                                    anchors.fill: parent
                                    source: homeAvatar.status === Image.Ready ? homeAvatar : accountsAvatar
                                    maskEnabled: true
                                    maskSource: avatarMask
                                    visible: homeAvatar.status === Image.Ready || accountsAvatar.status === Image.Ready
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: root.displayName.charAt(0).toUpperCase()
                                    font.pixelSize: 40
                                    font.weight: Font.Medium
                                    color: lockSurface.colOnPrimary
                                    visible: homeAvatar.status !== Image.Ready && accountsAvatar.status !== Image.Ready
                                }
                            }
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 8
                            implicitWidth: userName.implicitWidth + 16
                            implicitHeight: userName.implicitHeight + 8
                            opacity: Math.min(1, Math.max(0, loginContent.animationProgress * 3 - 0.3))
                            transform: Translate {
                                y: (1 - Math.min(1, Math.max(0, loginContent.animationProgress * 3 - 0.3))) * 15
                            }
                            Text {
                                id: userName
                                anchors.centerIn: parent
                                text: root.displayName
                                font.pixelSize: 22
                                font.weight: Font.Medium
                                color: lockSurface.colOnSurface
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowBlur: 1
                                    shadowVerticalOffset: 1
                                    shadowColor: Qt.rgba(0, 0, 0, 0.4)
                                }
                            }
                        }

                        Rectangle {
                            id: passwordPill
                            property real staggerY: (
                                1 - Math.min(1, Math.max(0, loginContent.animationProgress * 3 - 0.5))
                            ) * 20
                            property real shakeOffset: 0

                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 12
                            implicitWidth: 300
                            implicitHeight: 52
                            radius: height / 2
                            color: Qt.rgba(
                                lockSurface.colSurface.r,
                                lockSurface.colSurface.g,
                                lockSurface.colSurface.b,
                                0.85
                            )
                            border.color: lockSurface.loginFailed ? lockSurface.colError
                                : passwordBox.activeFocus ? lockSurface.colPrimary
                                : Qt.rgba(
                                    lockSurface.colOnSurface.r,
                                    lockSurface.colOnSurface.g,
                                    lockSurface.colOnSurface.b,
                                    0.3
                                )
                            border.width: passwordBox.activeFocus ? 2 : 1
                            opacity: Math.min(1, Math.max(0, loginContent.animationProgress * 3 - 0.5))
                            transform: Translate {
                                x: passwordPill.shakeOffset
                                y: passwordPill.staggerY
                            }
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: 1
                                shadowVerticalOffset: 4
                                shadowColor: Qt.rgba(0, 0, 0, 0.3)
                            }

                            SequentialAnimation {
                                id: shakeAnimation
                                NumberAnimation { target: passwordPill; property: "shakeOffset"; to: -20; duration: 50 }
                                NumberAnimation { target: passwordPill; property: "shakeOffset"; to: 20; duration: 50 }
                                NumberAnimation { target: passwordPill; property: "shakeOffset"; to: -10; duration: 40 }
                                NumberAnimation { target: passwordPill; property: "shakeOffset"; to: 10; duration: 40 }
                                NumberAnimation { target: passwordPill; property: "shakeOffset"; to: 0; duration: 30 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 8
                                spacing: 8

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: lockSurface.loginFailed ? "Incorrect password" : "Password"
                                        font.pixelSize: 16
                                        color: lockSurface.loginFailed
                                            ? lockSurface.colError : lockSurface.colOnSurfaceVariant
                                        visible: passwordBox.text.length === 0
                                    }
                                    PixelDots {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        dotCount: passwordBox.text.length
                                        dotColor: lockSurface.colOnSurface
                                        animColor: lockSurface.colPrimary
                                        visible: lockSurface.materialShapeChars
                                            && !lockContext.responseVisible
                                            && passwordBox.text.length > 0
                                    }
                                    TextInput {
                                        id: passwordBox
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        echoMode: lockContext.responseVisible ? TextInput.Normal : TextInput.Password
                                        color: lockSurface.materialShapeChars && !lockContext.responseVisible
                                            ? "transparent" : lockSurface.colOnSurface
                                        selectionColor: lockSurface.colPrimary
                                        selectedTextColor: lockSurface.colOnPrimary
                                        cursorVisible: false
                                        cursorDelegate: Item {}
                                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase
                                        enabled: !lockContext.authenticating
                                        focus: true
                                        font.pixelSize: 16
                                        Accessible.name: "Enter your password"

                                        onTextEdited: {
                                            lockSurface.loginFailed = false
                                            lockContext.password = text
                                        }
                                        Keys.onReturnPressed: lockSurface.attemptUnlock()
                                        Keys.onEnterPressed: lockSurface.attemptUnlock()
                                        Keys.onEscapePressed: {
                                            if (lockContext.password.length > 0) lockContext.password = ""
                                            else {
                                                lockSurface.currentView = "clock"
                                                visualRoot.forceActiveFocus()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: width / 2
                                    color: submitMouse.pressed ? Qt.darker(lockSurface.colPrimary, 1.2)
                                        : submitMouse.containsMouse ? Qt.lighter(lockSurface.colPrimary, 1.1)
                                        : lockSurface.colPrimary
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    MSymbol {
                                        anchors.centerIn: parent
                                        text: lockContext.authenticating ? "progress_activity" : "arrow_forward"
                                        iconSize: 20
                                        iconColor: lockSurface.colOnPrimary
                                        symFont: lockSurface.symbolFont()
                                        RotationAnimation on rotation {
                                            running: lockContext.authenticating
                                            loops: Animation.Infinite
                                            from: 0
                                            to: 360
                                            duration: 1000
                                        }
                                    }
                                    MouseArea {
                                        id: submitMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !lockContext.authenticating
                                        onClicked: lockSurface.attemptUnlock()
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 420
                            text: lockSurface.loginFailed ? lockContext.message : ""
                            color: lockSurface.colError
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            opacity: text.length > 0 ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                        }
                    }
                }

                Row {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.bottomMargin: 24
                    anchors.rightMargin: 24
                    spacing: 8
                    z: 10

                    LockIconButton {
                        icon: "dark_mode"
                        tooltip: "Sleep"
                        onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                    }
                    LockIconButton {
                        icon: "power_settings_new"
                        tooltip: "Shut down"
                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                    LockIconButton {
                        icon: "restart_alt"
                        tooltip: "Restart"
                        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                    }
                }

                Rectangle {
                    id: unlockOverlay
                    anchors.fill: parent
                    color: lockSurface.colBackground
                    opacity: 0
                    z: 100
                    NumberAnimation {
                        id: unlockFadeAnimation
                        target: unlockOverlay
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 300
                        easing.type: Easing.InQuad
                    }
                }

                Component.onCompleted: {
                    lockSurface.currentView = "clock"
                    Qt.callLater(function() {
                        visualRoot.forceActiveFocus()
                    })
                }
            }

            component LockIconButton: Rectangle {
                id: lockButton
                required property string icon
                property string tooltip: ""
                signal clicked

                width: 44
                height: 44
                radius: 12
                color: {
                    if (lockButtonMouse.pressed) {
                        return Qt.rgba(lockSurface.colOnSurface.r, lockSurface.colOnSurface.g,
                            lockSurface.colOnSurface.b, 0.3)
                    }
                    if (lockButtonMouse.containsMouse) {
                        return Qt.rgba(lockSurface.colOnSurface.r, lockSurface.colOnSurface.g,
                            lockSurface.colOnSurface.b, 0.15)
                    }
                    return Qt.rgba(lockSurface.colSurface.r, lockSurface.colSurface.g,
                        lockSurface.colSurface.b, 0.3)
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1
                    shadowVerticalOffset: 2
                    shadowColor: Qt.rgba(0, 0, 0, 0.3)
                }
                Behavior on color { ColorAnimation { duration: 150 } }

                MSymbol {
                    anchors.centerIn: parent
                    text: lockButton.icon
                    iconSize: 22
                    iconColor: lockSurface.colOnSurface
                    symFont: lockSurface.symbolFont()
                }
                MouseArea {
                    id: lockButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: lockButton.clicked()
                }
                Rectangle {
                    visible: lockButtonMouse.containsMouse && lockButton.tooltip.length > 0
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(lockSurface.colSurface.r, lockSurface.colSurface.g,
                        lockSurface.colSurface.b, 0.95)
                    border.color: Qt.rgba(lockSurface.colOnSurface.r, lockSurface.colOnSurface.g,
                        lockSurface.colOnSurface.b, 0.2)
                    border.width: 1
                    radius: 6
                    width: tooltipLabel.implicitWidth + 16
                    height: tooltipLabel.implicitHeight + 10
                    z: 99
                    Text {
                        id: tooltipLabel
                        anchors.centerIn: parent
                        text: lockButton.tooltip
                        font.pixelSize: 12
                        color: lockSurface.colOnSurface
                    }
                }
            }
        }
    }
}
