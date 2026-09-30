import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var downloadState
    required property var coordinator
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight
    readonly property var anchorWindow: coordinator.anchorItem ? coordinator.anchorItem.QsWindow.window : null
    readonly property var targetScreen: anchorWindow ? anchorWindow.screen : null
    readonly property real availableHeight: Math.max(180,
        (targetScreen ? targetScreen.height : 720) - Theme.barHeight - Theme.panelGap - Theme.spaceXl)

    function revealFocusedControl(): void {
        const window = root.Window.window
        const item = window ? window.activeFocusItem : null
        if (!item) return
        let ancestor = item
        while (ancestor && ancestor !== contentColumn) ancestor = ancestor.parent
        if (!ancestor) return
        const top = contentColumn.mapFromItem(item, 0, 0).y
        if (top < scroll.contentY) scroll.contentY = Math.max(0, top - Theme.spaceMd)
        else if (top + item.height > scroll.contentY + scroll.height)
            scroll.contentY = Math.min(scroll.contentHeight - scroll.height, top + item.height - scroll.height + Theme.spaceMd)
    }

    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() { root.revealFocusedControl() }
    }

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: panel
        width: parent.width
        title: "Download media"
        contentWidth: Math.min(460, root.targetScreen ? root.targetScreen.width - Theme.spaceXl * 2 : 460)
        onCloseRequested: root.coordinator.close("close-control")

        Flickable {
            id: scroll
            width: parent.width
            implicitHeight: Math.min(contentColumn.implicitHeight, root.availableHeight
                - Theme.compactControlSize - Theme.panelPadding * 2 - Theme.spaceLg * 2 - Theme.borderWidth)
            height: implicitHeight
            contentHeight: contentColumn.implicitHeight
            contentWidth: width
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: contentColumn
                width: scroll.width - (scroll.contentHeight > scroll.height ? Theme.spaceLg : 0)
                spacing: Theme.spaceXl

                Row {
                    width: parent.width
                    spacing: Theme.spaceLg

                    Rectangle {
                        width: 48
                        height: 48
                        radius: Theme.radius
                        color: Theme.selectedSurface
                        border.color: Theme.accentMuted

                        Text {
                            anchors.centerIn: parent
                            text: "↓"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                        }
                    }

                    Column {
                        width: parent.width - 48 - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spaceSm

                        Text {
                            text: "From link to clipboard"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTitle
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: "Video or image. Paste a link to download and copy it."
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spaceMd

                    TextField {
                        id: linkInput
                        width: parent.width
                        height: 46
                        text: root.downloadState.url
                        placeholderText: "Paste a link…"
                        color: Theme.text
                        placeholderTextColor: Theme.textMuted
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.textOnAccent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        leftPadding: Theme.spaceLg
                        rightPadding: Theme.spaceLg
                        selectByMouse: true
                        readOnly: root.downloadState.busy
                        Accessible.name: "Video or image URL"
                        onTextEdited: root.downloadState.url = text
                        onAccepted: root.downloadState.start()
                        background: Rectangle {
                            radius: Theme.radius
                            color: Theme.background
                            border.width: linkInput.activeFocus ? Theme.focusWidth : Theme.borderWidth
                            border.color: linkInput.activeFocus ? Theme.accent : Theme.borderInteractive
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spaceMd

                        ActionButton {
                            width: parent.width - (cancelButton.visible ? cancelButton.width + parent.spacing : 0)
                            height: 40
                            text: root.downloadState.copying ? "Copying…" : root.downloadState.busy ? "Downloading…" : "Download and copy"
                            selected: enabled
                            enabled: root.downloadState.canStart
                            onClicked: root.downloadState.start()
                        }

                        ActionButton {
                            id: cancelButton
                            width: 92
                            height: 40
                            visible: root.downloadState.busy
                            text: "Cancel"
                            enabled: root.downloadState.canCancel
                            onClicked: root.downloadState.cancel()
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spaceMd

                    Row {
                        width: parent.width
                        spacing: Theme.spaceMd

                        Text {
                            width: parent.width - percentText.width - parent.spacing
                            text: root.downloadState.status
                            color: root.downloadState.error !== "" ? Theme.danger : Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                        }

                        Text {
                            id: percentText
                            text: root.downloadState.busy && root.downloadState.progress >= 0
                                ? Math.floor(root.downloadState.progress) + "%" : ""
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Theme.border
                        visible: root.downloadState.busy
                        clip: true

                        Rectangle {
                            id: progressFill
                            height: parent.height
                            width: root.downloadState.progress >= 0
                                ? parent.width * Math.max(0.02, root.downloadState.progress / 100) : parent.width * 0.25
                            radius: parent.radius
                            color: Theme.accent
                            x: 0

                            SequentialAnimation on x {
                                running: root.downloadState.busy && root.downloadState.progress < 0
                                loops: Animation.Infinite
                                NumberAnimation { from: -progressFill.width; to: progressFill.parent.width; duration: 1200; easing.type: Easing.InOutSine }
                            }
                            Connections {
                                target: root.downloadState
                                function onProgressChanged() {
                                    if (root.downloadState.progress >= 0) progressFill.x = 0
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.downloadState.busy && root.downloadState.details !== ""
                        text: root.downloadState.details
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }

                Rectangle {
                    width: parent.width
                    height: resultColumn.implicitHeight + Theme.spaceLg * 2
                    visible: root.downloadState.savedPath !== "" && !root.downloadState.busy
                    radius: Theme.radius
                    color: Theme.surfaceRaised
                    border.color: root.downloadState.copied ? Theme.accentMuted : Theme.border

                    Column {
                        id: resultColumn
                        x: Theme.spaceLg
                        y: Theme.spaceLg
                        width: parent.width - Theme.spaceLg * 2
                        spacing: Theme.spaceMd

                        Image {
                            width: parent.width
                            height: 120
                            visible: root.downloadState.savedKind === "image"
                            source: visible ? root.downloadState.savedUrl : ""
                            sourceSize.width: 800
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        Text {
                            width: parent.width
                            text: root.downloadState.title
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                            elide: Text.ElideMiddle
                            textFormat: Text.PlainText
                        }

                        Text {
                            width: parent.width
                            text: root.downloadState.copied ? "Ready. Press Ctrl+V in your app." : "File saved. You can copy it again."
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spaceMd

                            ActionButton {
                                width: (parent.width - parent.spacing) / 2
                                text: "Copy again"
                                onClicked: root.downloadState.copySaved()
                            }

                            ActionButton {
                                width: (parent.width - parent.spacing) / 2
                                text: "Open folder"
                                onClicked: root.downloadState.openFolder()
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: root.downloadState.error !== ""
                    text: root.downloadState.error
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                ActionButton {
                    width: parent.width
                    visible: !root.downloadState.available && !root.downloadState.checking
                    text: "Recheck tools"
                    onClicked: root.downloadState.refreshAvailability()
                }

                Text {
                    width: parent.width
                    text: "Downloads continue when this panel is closed. Video pasting requires an app that accepts files."
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Component.onCompleted: Qt.callLater(function() { linkInput.forceActiveFocus() })
}
