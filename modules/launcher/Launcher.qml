pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core
import qs.ui
import "LauncherSearch.js" as LauncherSearch

Scope {
    id: root

    required property var coordinator
    required property var configStore
    property bool opened: false
    property var targetScreen: null
    property string mode: "apps"
    property var clipboardItems: []
    property var actions: []
    property var projects: []
    property string projectError: ""
    property string projectConfigPath: ""
    readonly property var modeNames: ["apps", "clipboard", "actions", "projects"]
    readonly property int clipboardHistoryLimit: configStore ? configStore.clipboardHistoryLimit : 50

    signal actionRequested(string actionId)
    signal projectRequested(string projectId)

    function preferredScreen() {
        const outputName = coordinator && coordinator.preferredOutputName
            ? String(coordinator.preferredOutputName()) : ""
        const screens = Quickshell.screens || []
        for (let index = 0; index < screens.length; index++) {
            if (String(screens[index].name || "") === outputName) return screens[index]
        }
        return screens.length > 0 ? screens[0] : null
    }

    function setMode(nextMode) {
        const normalizedMode = String(nextMode || "").toLowerCase()
        if (modeNames.indexOf(normalizedMode) === -1) return false
        mode = normalizedMode
        search.text = ""
        if (mode === "clipboard") root.refreshClipboard()
        Qt.callLater(function() {
            results.currentIndex = results.count > 0 ? 0 : -1
            search.forceActiveFocus()
        })
        return true
    }

    function switchMode(offset) {
        const current = Math.max(0, modeNames.indexOf(mode))
        const next = (current + offset + modeNames.length) % modeNames.length
        setMode(modeNames[next])
    }

    function toggle() {
        if (opened) close()
        else open()
    }

    function open() {
        openMode("apps")
    }

    function openMode(modeName) {
        coordinator.close("launcher")
        targetScreen = preferredScreen()
        setMode(modeNames.indexOf(String(modeName || "").toLowerCase()) === -1 ? "apps" : modeName)
        opened = targetScreen !== null
    }

    function close() {
        opened = false
    }

    function refreshClipboard() {
        if (clipboardQuery.running) return
        clipboardQuery.buffer = []
        clipboardQuery.running = true
    }

    function adjustClipboardHistoryLimit(delta) {
        if (!configStore || !configStore.setClipboardHistoryLimit) return
        const next = Math.max(10, Math.min(750, root.clipboardHistoryLimit + delta))
        if (next === root.clipboardHistoryLimit) return
        configStore.setClipboardHistoryLimit(next)
    }

    function copyClipboard(id) {
        const numericId = Number(id)
        if (!Number.isInteger(numericId) || numericId < 0) return
        Quickshell.execDetached(["sh", "-c", "printf '%s' " + String(numericId) + " | cliphist decode | wl-copy"])
        close()
    }

    function activate(item) {
        if (!item) return
        if (item.kind === "clipboard") {
            copyClipboard(item.id)
        } else if (item.kind === "action") {
            if (!item.enabled) return
            close()
            actionRequested(String(item.id))
        } else if (item.kind === "project") {
            close()
            projectRequested(String(item.id))
        } else if (item.kind === "app") {
            item.entry.execute()
            close()
        }
    }

    function activateDesktopAction(action) {
        if (!action || !action.execute) return
        close()
        action.execute()
    }

    Process {
        id: clipboardQuery
        property var buffer: []
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: line => clipboardQuery.buffer.push(line)
        }
        onRunningChanged: if (running) buffer = []
        onExited: exitCode => {
            if (exitCode !== 0) return
            const next = []
            for (let index = 0; index < buffer.length; index++) {
                const separator = buffer[index].indexOf("\t")
                if (separator <= 0) continue
                next.push({ id: buffer[index].slice(0, separator), text: buffer[index].slice(separator + 1) })
            }
            const previous = root.clipboardItems
            if (previous.length === next.length) {
                let unchanged = true
                for (let index = 0; index < next.length; index++) {
                    if (previous[index].id !== next[index].id || previous[index].text !== next[index].text) {
                        unchanged = false
                        break
                    }
                }
                if (unchanged) return
            }
            root.clipboardItems = next
        }
    }

    Timer {
        interval: 800
        repeat: true
        running: root.opened && root.mode === "clipboard"
        onTriggered: root.refreshClipboard()
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            if (root.opened && root.mode === "clipboard") root.refreshClipboard()
        }
    }

    PanelWindow {
        id: window
        screen: root.targetScreen
        visible: root.opened && root.targetScreen !== null
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "rashell-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.42)

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            width: Math.min(680, window.width - Theme.spaceXl * 2)
            height: Math.min(600, window.height - Theme.spaceXl * 4)
            anchors.centerIn: parent
            color: Theme.surface
            border.color: Theme.border
            border.width: Theme.borderWidth
            radius: Theme.radius

            MouseArea {
                anchors.fill: parent
                onClicked: event => event.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spaceXl
                spacing: Theme.spaceLg

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceLg

                    TextField {
                        id: search
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.rowHeight + Theme.spaceXl
                        placeholderText: root.mode === "apps" ? "Search applications…"
                            : root.mode === "clipboard" ? "Search clipboard…"
                            : root.mode === "actions" ? "Search actions…"
                            : "Search projects…"
                        placeholderTextColor: Theme.textMuted
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.textOnAccent
                        leftPadding: Theme.controlHeight + Theme.spaceMd
                        rightPadding: Theme.spaceMd
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle + Theme.spaceXs
                        focus: root.opened
                        Accessible.name: placeholderText

                        onTextChanged: Qt.callLater(function() {
                            results.currentIndex = results.count > 0 ? 0 : -1
                        })

                        background: Item {}

                        Item {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spaceMd
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20

                            Rectangle {
                                width: 13
                                height: 13
                                radius: width / 2
                                color: "transparent"
                                border.color: search.activeFocus ? Theme.accent : Theme.textMuted
                                border.width: 1.5
                                antialiasing: true
                            }
                            Rectangle {
                                x: 12
                                y: 13
                                width: 8
                                height: 1.5
                                radius: 1
                                rotation: 45
                                transformOrigin: Item.Left
                                color: search.activeFocus ? Theme.accent : Theme.textMuted
                                antialiasing: true
                            }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                results.currentIndex = Math.min(results.count - 1, results.currentIndex + 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                results.currentIndex = Math.max(0, results.currentIndex - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (results.currentIndex >= 0) root.activate(results.model[results.currentIndex])
                                event.accepted = true
                            } else if ((event.modifiers & Qt.ControlModifier)
                                    && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
                                root.switchMode(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1)
                                event.accepted = true
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_4) {
                                root.setMode(root.modeNames[event.key - Qt.Key_1])
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                root.close()
                                event.accepted = true
                            }
                        }
                    }

                    CloseButton {
                        accessibleName: "Close launcher"
                        onClicked: root.close()
                    }
                }

                RowLayout {
                    id: tabRow
                    Layout.fillWidth: true
                    spacing: Theme.spaceSm

                    Repeater {
                        model: [
                            { mode: "apps", label: "Applications" },
                            { mode: "clipboard", label: "Clipboard" },
                            { mode: "actions", label: "Actions" },
                            { mode: "projects", label: "Projects" }
                        ]
                        Button {
                            id: tabButton
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: Theme.controlHeight
                            text: modelData.label
                            hoverEnabled: true
                            onClicked: root.setMode(modelData.mode)

                            background: Rectangle {
                                color: root.mode === tabButton.modelData.mode
                                    ? Theme.surfaceRaised
                                    : tabButton.down || tabButton.hovered ? Theme.hoverSurface : "transparent"
                                border.color: tabButton.visualFocus ? Theme.focus : "transparent"
                                border.width: tabButton.visualFocus ? Theme.focusWidth : 0
                                radius: Theme.radius
                            }
                            contentItem: Text {
                                text: tabButton.text
                                color: root.mode === tabButton.modelData.mode ? Theme.text : Theme.textMuted
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: root.mode === tabButton.modelData.mode ? Font.DemiBold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Theme.borderWidth
                    color: Theme.border
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0

                    ListView {
                        id: results
                        anchors.fill: parent
                        spacing: Theme.spaceXs
                        clip: true
                        currentIndex: count > 0 ? 0 : -1
                        model: {
                            const query = search.text.trim().toLowerCase()
                            if (root.mode === "clipboard") {
                                return root.clipboardItems.filter(function(item) {
                                    return query === "" || item.text.toLowerCase().indexOf(query) !== -1
                                }).slice(0, root.clipboardHistoryLimit).map(function(item) {
                                    return {
                                        kind: "clipboard",
                                        id: item.id,
                                        name: item.text,
                                        comment: "Copy to clipboard",
                                        icon: "edit-copy",
                                        enabled: true
                                    }
                                })
                            }
                            if (root.mode === "actions") {
                                return LauncherSearch.records(root.actions, query, 40).map(function(action) {
                                    return {
                                        kind: "action",
                                        id: action.id,
                                        name: action.name,
                                        comment: action.comment || "",
                                        icon: action.icon || "system-run",
                                        enabled: action.enabled !== false
                                    }
                                })
                            }
                            if (root.mode === "projects") {
                                return LauncherSearch.records(root.projects, query, 40).map(function(project) {
                                    return {
                                        kind: "project",
                                        id: project.id,
                                        name: project.name,
                                        comment: project.comment || project.path || "",
                                        icon: project.icon || "folder",
                                        enabled: true
                                    }
                                })
                            }
                            const all = DesktopEntries.applications ? DesktopEntries.applications.values : []
                            return LauncherSearch.applicationItems(all, query)
                        }

                        delegate: ItemDelegate {
                            id: resultDelegate
                            required property var modelData
                            required property int index
                            width: ListView.view.width - Theme.spaceMd
                            height: Theme.rowHeight + Theme.spaceXl
                            padding: 0
                            hoverEnabled: true
                            highlighted: ListView.isCurrentItem
                            enabled: modelData.kind !== "action" || modelData.enabled
                            property bool suppressLaunch: false
                            readonly property var deleteAction: modelData.kind === "app"
                                ? LauncherSearch.deleteAction(modelData.entry) : null

                            function launch() {
                                if (resultDelegate.suppressLaunch) {
                                    resultDelegate.suppressLaunch = false
                                    return
                                }
                                root.activate(resultDelegate.modelData)
                            }

                            contentItem: Item {
                                opacity: resultDelegate.enabled ? 1 : 0.55

                                Image {
                                    id: resultIcon
                                    width: Theme.controlHeight
                                    height: Theme.controlHeight
                                    smooth: true
                                    mipmap: true
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spaceLg
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: Quickshell.iconPath(resultDelegate.modelData.icon)
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    id: unavailableLabel
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spaceLg
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: resultDelegate.modelData.kind === "action" && !resultDelegate.modelData.enabled
                                    text: "Unavailable"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                }

                                Button {
                                    id: deleteAppButton
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spaceLg
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Theme.compactControlSize
                                    height: Theme.compactControlSize
                                    visible: resultDelegate.deleteAction !== null
                                        && (resultDelegate.highlighted || resultDelegate.hovered)
                                    focusPolicy: Qt.NoFocus
                                    hoverEnabled: true
                                    Accessible.name: resultDelegate.deleteAction
                                        ? String(resultDelegate.deleteAction.name) : "Delete"
                                    onPressed: resultDelegate.suppressLaunch = true
                                    onCanceled: resultDelegate.suppressLaunch = false
                                    onClicked: {
                                        root.activateDesktopAction(resultDelegate.deleteAction)
                                        resultDelegate.suppressLaunch = false
                                    }

                                    ToolTip {
                                        id: deleteAppTip
                                        visible: deleteAppButton.hovered && resultDelegate.deleteAction !== null
                                        delay: 450
                                        timeout: 5000
                                        text: resultDelegate.deleteAction
                                            ? String(resultDelegate.deleteAction.name) : "Delete"
                                        y: -implicitHeight - Theme.spaceSm
                                        leftPadding: Theme.spaceLg
                                        rightPadding: Theme.spaceLg
                                        topPadding: Theme.spaceMd
                                        bottomPadding: Theme.spaceMd

                                        contentItem: Text {
                                            text: deleteAppTip.text
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSmall
                                        }

                                        background: Rectangle {
                                            color: Theme.surfaceRaised
                                            border.color: Theme.border
                                            border.width: Theme.borderWidth
                                            radius: Theme.radius
                                        }
                                    }

                                    contentItem: Item {
                                        Image {
                                            id: deleteAppIcon
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            visible: status === Image.Ready
                                            source: Quickshell.iconPath("edit-delete", "user-trash")
                                            fillMode: Image.PreserveAspectFit
                                        }

                                        Text {
                                            anchors.fill: parent
                                            visible: !deleteAppIcon.visible
                                            text: "×"
                                            color: deleteAppButton.hovered || deleteAppButton.down
                                                ? Theme.accent : Theme.textMuted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontTitle
                                            font.weight: Font.Medium
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    background: Rectangle {
                                        color: deleteAppButton.down || deleteAppButton.hovered
                                            ? Theme.selectedSurface
                                            : Theme.surfaceRaised
                                        border.color: deleteAppButton.activeFocus ? Theme.focus : "transparent"
                                        border.width: deleteAppButton.activeFocus ? Theme.focusWidth : 0
                                        radius: Theme.radius
                                    }
                                }

                                Column {
                                    anchors.left: resultIcon.right
                                    anchors.leftMargin: Theme.spaceLg
                                    anchors.right: unavailableLabel.visible ? unavailableLabel.left
                                        : deleteAppButton.visible ? deleteAppButton.left : parent.right
                                    anchors.rightMargin: Theme.spaceLg
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spaceSm

                                    Text {
                                        width: parent.width
                                        text: resultDelegate.modelData.name
                                        textFormat: Text.PlainText
                                        color: Theme.text
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        width: parent.width
                                        visible: text.length > 0
                                        text: resultDelegate.modelData.comment
                                        textFormat: Text.PlainText
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSmall
                                    }
                                }
                            }

                            background: Rectangle {
                                color: resultDelegate.highlighted
                                    ? Theme.hoverSurface
                                    : resultDelegate.hovered ? Theme.surfaceRaised : "transparent"
                                radius: Theme.radius
                                border.color: resultDelegate.activeFocus ? Theme.focus : "transparent"
                                border.width: resultDelegate.activeFocus ? Theme.focusWidth : 0


                            }

                            onHoveredChanged: if (hovered) results.currentIndex = index
                            onClicked: launch()
                        }

                        ScrollBar.vertical: ScrollBar {
                            visible: results.contentHeight > results.height
                            active: true
                            policy: ScrollBar.AsNeeded
                            width: Theme.spaceMd
                            contentItem: Rectangle {
                                implicitWidth: Theme.spaceSm
                                radius: Theme.spaceXs
                                color: Theme.borderInteractive
                            }
                            background: Item {}
                        }
                    }

                    Column {
                        width: Math.max(0, parent.width - Theme.spaceXl * 4)
                        anchors.centerIn: parent
                        spacing: Theme.spaceMd
                        visible: results.count === 0

                        Text {
                            width: parent.width
                            text: {
                                if (root.mode === "clipboard") {
                                    if (clipboardQuery.running) return "Loading clipboard…"
                                    return search.text.trim() === "" ? "Your clipboard is empty" : "No clipboard matches"
                                }
                                if (root.mode === "apps") return "No applications found"
                                if (root.mode === "actions") return search.text.trim() === "" ? "No actions available" : "No actions found"
                                if (root.projectError !== "") return "Projects unavailable"
                                return search.text.trim() === "" ? "No projects configured" : "No projects found"
                            }
                            color: Theme.text
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.Medium
                        }

                        Text {
                            width: parent.width
                            text: {
                                if (root.mode === "projects" && root.projectError !== "") return root.projectError
                                if (root.mode === "clipboard" && clipboardQuery.running) return "Fetching your recent copies."
                                if (search.text.trim() !== "") return "Try another name or keyword."
                                if (root.mode === "clipboard") return "Copied text will appear here, ready to use again."
                                if (root.mode === "projects" && root.projectConfigPath !== "") return "Add projects to " + root.projectConfigPath
                                if (root.mode === "projects") return "Configured projects will appear here."
                                if (root.mode === "actions") return "Configured desktop actions will appear here."
                                return "Installed desktop applications will appear here."
                            }
                            textFormat: Text.PlainText
                            color: root.mode === "projects" && root.projectError !== "" ? Theme.danger : Theme.textMuted
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.mode === "clipboard"
                    spacing: Theme.spaceMd
                    Text {
                        text: "History limit"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                    Row {
                        id: sliceStepper

                        height: Theme.compactControlSize
                        spacing: Theme.spaceXs

                        Button {
                            width: Theme.compactControlSize
                            height: Theme.compactControlSize
                            text: "−"
                            hoverEnabled: true
                            Accessible.name: "Show fewer clipboard items"
                            enabled: root.clipboardHistoryLimit > 10
                            onClicked: {
                                root.adjustClipboardHistoryLimit(-10)
                                search.forceActiveFocus()
                            }

                            background: Rectangle {
                                color: parent.hovered
                                    ? Theme.selectedSurface : Theme.surfaceRaised
                                border.color: parent.activeFocus ? Theme.focus : "transparent"
                                border.width: parent.activeFocus ? Theme.focusWidth : 0
                                radius: Theme.radius
                                opacity: parent.enabled ? 1 : 0.45
                            }

                            contentItem: Text {
                                text: parent.text
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontTitle
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text {
                            width: 28
                            height: Theme.compactControlSize
                            text: String(root.clipboardHistoryLimit)
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Button {
                            width: Theme.compactControlSize
                            height: Theme.compactControlSize
                            text: "+"
                            hoverEnabled: true
                            Accessible.name: "Show more clipboard items"
                            enabled: root.clipboardHistoryLimit < 750
                            onClicked: {
                                root.adjustClipboardHistoryLimit(10)
                                search.forceActiveFocus()
                            }

                            background: Rectangle {
                                color: parent.hovered
                                    ? Theme.selectedSurface : Theme.surfaceRaised
                                border.color: parent.activeFocus ? Theme.focus : "transparent"
                                border.width: parent.activeFocus ? Theme.focusWidth : 0
                                radius: Theme.radius
                                opacity: parent.enabled ? 1 : 0.45
                            }

                            contentItem: Text {
                                text: parent.text
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontTitle
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.mode === "projects" && root.projectError !== "" && results.count > 0
                    text: root.projectError
                    textFormat: Text.PlainText
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Theme.borderWidth
                    color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceLg

                    Text {
                        text: results.count + (results.count === 1 ? " result" : " results")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "↑↓ Select"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                    Text {
                        text: root.mode === "clipboard" ? "Enter Copy" : root.mode === "actions" ? "Enter Run" : "Enter Open"
                        color: results.currentIndex >= 0 && results.model[results.currentIndex] && (root.mode !== "actions" || results.model[results.currentIndex].enabled)
                            ? Theme.text : Theme.textDisabled
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                    Text {
                        text: "Ctrl+Tab Switch"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                    Text {
                        text: "Esc Close"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                search.text = ""
                Qt.callLater(function() { search.forceActiveFocus() })
            }
        }
    }
}
