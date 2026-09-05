pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core
import "LauncherSearch.js" as LauncherSearch

Scope {
    id: root

    required property var coordinator
    property bool opened: false
    property var targetScreen: null
    property string mode: "apps"
    property var clipboardItems: []
    property var actions: []
    property var projects: []
    property string projectError: ""
    property string projectConfigPath: ""
    readonly property var modeNames: ["apps", "clipboard", "actions", "projects"]

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
        if (mode === "clipboard") clipboardQuery.running = true
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

    Process {
        id: clipboardQuery
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const next = []
                for (let index = 0; index < lines.length; index++) {
                    const separator = lines[index].indexOf("\t")
                    if (separator <= 0) continue
                    next.push({ id: lines[index].slice(0, separator), text: lines[index].slice(separator + 1) })
                }
                root.clipboardItems = next
            }
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
            width: Math.min(620, window.width - Theme.spaceXl * 2)
            height: Math.min(560, window.height - Theme.spaceXl * 4)
            anchors.centerIn: parent
            color: Theme.surface
            border.color: Theme.border
            border.width: Theme.borderWidth
            radius: Theme.radius

            MouseArea {
                anchors.fill: parent
                onClicked: event => event.accepted = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spaceXl
                spacing: Theme.spaceLg

                Item {
                    width: parent.width
                    height: Theme.controlHeight

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Launcher"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle + 2
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ctrl+tab switch"
                        color: Theme.textDisabled
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }

                Row {
                    id: tabRow
                    width: parent.width
                    height: Theme.compactControlSize
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
                            width: (tabRow.width - tabRow.spacing * 3) / 4
                            height: tabRow.height
                            text: modelData.label
                            onClicked: root.setMode(modelData.mode)

                            background: Rectangle {
                                color: root.mode === tabButton.modelData.mode
                                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : "transparent"
                                border.color: root.mode === tabButton.modelData.mode ? Theme.accent : Theme.border
                                border.width: Theme.borderWidth
                                radius: Theme.radius
                            }

                            contentItem: Text {
                                text: tabButton.text
                                color: root.mode === tabButton.modelData.mode ? Theme.accent : Theme.textMuted
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 9
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                TextField {
                    id: search
                    width: parent.width
                    height: 44
                    placeholderText: root.mode === "apps" ? "Search applications…"
                        : root.mode === "clipboard" ? "Search clipboard…"
                        : root.mode === "actions" ? "Search actions…"
                        : "Search projects…"
                    placeholderTextColor: Theme.textMuted
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.textOnAccent
                    leftPadding: Theme.spaceLg
                    rightPadding: 44
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    focus: root.opened

                    onTextChanged: Qt.callLater(function() {
                        results.currentIndex = results.count > 0 ? 0 : -1
                    })

                    background: Rectangle {
                        color: Theme.surfaceRaised
                        border.color: search.activeFocus ? Theme.accent : Theme.border
                        border.width: search.activeFocus ? Theme.focusWidth : Theme.borderWidth
                        radius: Theme.radius
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spaceLg
                        anchors.verticalCenter: parent.verticalCenter
                        text: "/"
                        color: Theme.textDisabled
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
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

                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: results.count + (results.count === 1 ? " result" : " results")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.72
                        text: root.mode === "projects" && root.projectError !== ""
                            ? root.projectError : "↑↓ navigate   enter open   esc close"
                        color: root.mode === "projects" && root.projectError !== ""
                            ? Theme.danger : Theme.textDisabled
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - Theme.controlHeight - tabRow.height - search.height - 18 - Theme.spaceLg * 4

                    ListView {
                        id: results
                        anchors.fill: parent
                        spacing: Theme.spaceSm
                        clip: true
                        currentIndex: count > 0 ? 0 : -1
                        model: {
                            const query = search.text.trim().toLowerCase()
                            if (root.mode === "clipboard") {
                                return root.clipboardItems.filter(function(item) {
                                    return query === "" || item.text.toLowerCase().indexOf(query) !== -1
                                }).slice(0, 40).map(function(item) {
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
                            return LauncherSearch.applications(all, query, 40).map(function(entry) {
                                return {
                                    kind: "app",
                                    entry: entry,
                                    name: entry.name,
                                    comment: entry.comment || "",
                                    icon: entry.icon,
                                    enabled: true
                                }
                            })
                        }

                        delegate: ItemDelegate {
                            id: resultDelegate
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 48
                            hoverEnabled: true
                            highlighted: ListView.isCurrentItem
                            enabled: modelData.kind !== "action" || modelData.enabled

                            function launch() {
                                root.activate(resultDelegate.modelData)
                            }

                            contentItem: Item {
                                opacity: resultDelegate.enabled ? 1 : 0.55

                                Image {
                                    id: resultIcon
                                    width: 28
                                    height: 28
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
                                    color: Theme.textDisabled
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                }

                                Column {
                                    anchors.left: resultIcon.right
                                    anchors.leftMargin: Theme.spaceLg
                                    anchors.right: unavailableLabel.visible ? unavailableLabel.left : parent.right
                                    anchors.rightMargin: Theme.spaceLg
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1

                                    Text {
                                        width: parent.width
                                        text: resultDelegate.modelData.name
                                        color: Theme.text
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        width: parent.width
                                        visible: text.length > 0
                                        text: resultDelegate.modelData.comment
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSmall
                                    }
                                }
                            }

                            background: Rectangle {
                                color: resultDelegate.highlighted
                                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.13)
                                    : resultDelegate.hovered ? Theme.surfaceRaised : "transparent"
                                radius: Theme.radius

                                Rectangle {
                                    width: Theme.focusWidth
                                    height: parent.height - Theme.spaceLg * 2
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: resultDelegate.highlighted
                                    color: Theme.accent
                                    radius: width
                                }
                            }

                            onHoveredChanged: if (hovered) results.currentIndex = index
                            onClicked: launch()
                        }

                        ScrollBar.vertical: ScrollBar {
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

                    Text {
                        width: parent.width - Theme.spaceXl * 2
                        anchors.centerIn: parent
                        visible: results.count === 0
                        text: {
                            if (root.mode === "clipboard") {
                                return clipboardQuery.running ? "Loading clipboard…" : "Clipboard is empty"
                            }
                            if (root.mode === "apps") return "No applications found"
                            if (root.mode === "actions") {
                                return search.text.trim() === "" ? "No actions configured" : "No actions found"
                            }
                            if (root.projectError !== "") return root.projectError
                            if (search.text.trim() !== "") return "No projects found"
                            return root.projectConfigPath !== ""
                                ? "No projects configured\nAdd projects to " + root.projectConfigPath
                                : "No projects configured"
                        }
                        color: root.mode === "projects" && root.projectError !== "" ? Theme.danger : Theme.textMuted
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
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
