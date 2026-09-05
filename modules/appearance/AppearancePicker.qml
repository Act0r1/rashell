pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Scope {
    id: root

    required property var configStore
    property bool opened: false
    property var targetScreen: null
    property string selectedId: "muninn"
    property string query: ""
    property string kind: "all"
    property string error: ""

    readonly property var selectedTheme: Theme.themeInfo(selectedId)
    readonly property var filteredThemes: Theme.catalog.filter(function(theme) {
        const needle = root.query.trim().toLowerCase()
        return (root.kind === "all" || theme.kind === root.kind)
            && (theme.name + " " + theme.id + " " + theme.description).toLowerCase().indexOf(needle) !== -1
    })

    signal wallpaperRequested(var screen)

    function open(screen, themeId) {
        targetScreen = screen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        query = ""
        search.text = ""
        kind = "all"
        error = ""
        selectedId = Theme.names.indexOf(themeId) !== -1 ? themeId : configStore.theme
        opened = targetScreen !== null
        Qt.callLater(function() {
            catalog.positionViewAtIndex(catalog.currentIndex, ListView.Contain)
            search.forceActiveFocus()
        })
    }

    function close() {
        opened = false
    }

    function selectAt(index) {
        if (index < 0 || index >= filteredThemes.length) return
        selectedId = filteredThemes[index].id
        error = ""
        catalog.positionViewAtIndex(index, ListView.Contain)
    }

    function step(delta) {
        const count = filteredThemes.length
        if (count === 0) return
        const index = filteredThemes.findIndex(function(theme) { return theme.id === root.selectedId })
        selectAt((Math.max(0, index) + delta + count) % count)
    }

    function applySelected() {
        if (filteredThemes.length === 0) return
        if (configStore.setTheme(selectedId)) close()
        else error = "Could not apply this theme."
    }

    onFilteredThemesChanged: {
        if (filteredThemes.length > 0 && !filteredThemes.some(function(theme) { return theme.id === root.selectedId })) {
            selectedId = filteredThemes[0].id
        }
    }

    PanelWindow {
        id: window
        objectName: "appearanceWindow"
        screen: root.targetScreen
        visible: root.opened && root.targetScreen !== null
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "rashell-appearance"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.72)
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        FocusScope {
            id: content
            objectName: "appearanceContent"
            anchors.centerIn: parent
            width: Math.min(1180, window.width - 48)
            height: Math.min(780, window.height - 64)
            readonly property bool compact: width < 800
            focus: true

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                    root.step(event.key === Qt.Key_Down ? 1 : -1)
                    event.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.background
                border.color: Theme.borderInteractive
                border.width: 1
                radius: 16
                MouseArea { anchors.fill: parent }
            }

            ColumnLayout {
                anchors { fill: parent; margins: content.compact ? 16 : 28 }
                spacing: 20

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Column {
                        Layout.fillWidth: true
                        spacing: 5
                        Text {
                            text: "Appearance"
                            color: Theme.text
                            font { family: Theme.fontFamily; pixelSize: 24; bold: true }
                        }
                        Text {
                            text: Theme.catalog.length + " themes · find your atmosphere"
                            color: Theme.textMuted
                            font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
                        }
                    }
                    CloseButton { onClicked: root.close() }
                }

                Flickable {
                    id: bodyScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: bodyGrid.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    GridLayout {
                    id: bodyGrid
                    width: bodyScroll.width - 8
                    height: Math.max(bodyScroll.height, implicitHeight)
                    columns: content.compact ? 1 : 2
                    rowSpacing: 16
                    columnSpacing: 26

                    ColumnLayout {
                        Layout.preferredWidth: content.compact ? -1 : 260
                        Layout.fillWidth: content.compact
                        Layout.fillHeight: !content.compact
                        spacing: 12

                        TextField {
                            id: search
                            objectName: "appearanceSearch"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            placeholderText: "Search themes…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.textOnAccent
                            font { family: Theme.fontFamily; pixelSize: Theme.fontBody }
                            leftPadding: 12
                            rightPadding: 12
                            Accessible.name: "Search themes"
                            onTextChanged: root.query = text
                            onAccepted: root.applySelected()
                            background: Rectangle {
                                color: Theme.surface
                                radius: 8
                                border.color: search.activeFocus ? Theme.accent : Theme.borderInteractive
                                border.width: 1
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: ["all", "dark", "light"]
                                ActionButton {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    selected: root.kind === modelData
                                    subtleSelected: true
                                    onClicked: root.kind = modelData
                                }
                            }
                        }

                        ListView {
                            id: catalog
                            objectName: "appearanceCatalog"
                            Layout.fillWidth: true
                            Layout.fillHeight: !content.compact
                            Layout.preferredHeight: content.compact ? 72 : -1
                            clip: true
                            spacing: 6
                            orientation: content.compact ? ListView.Horizontal : ListView.Vertical
                            model: root.filteredThemes
                            currentIndex: root.filteredThemes.findIndex(function(theme) { return theme.id === root.selectedId })
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: content.compact ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded }
                            ScrollBar.horizontal: ScrollBar { policy: content.compact ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }

                            delegate: Button {
                                id: choice
                                required property var modelData
                                required property int index
                                width: content.compact ? 190 : catalog.width - 12
                                height: 56
                                hoverEnabled: true
                                leftPadding: 12
                                rightPadding: 12
                                Accessible.name: modelData.name + (root.configStore.theme === modelData.id ? ", current theme" : "")
                                onClicked: root.selectAt(index)
                                onActiveFocusChanged: if (activeFocus) root.selectAt(index)
                                Keys.onReturnPressed: root.applySelected()
                                Keys.onEnterPressed: root.applySelected()

                                background: Rectangle {
                                    color: root.selectedId === choice.modelData.id || choice.hovered ? Theme.surfaceRaised : Theme.surface
                                    radius: 8
                                    border.color: choice.activeFocus ? Theme.focus : root.selectedId === choice.modelData.id ? Theme.accent : Theme.border
                                    border.width: choice.activeFocus ? 2 : 1
                                }

                                contentItem: RowLayout {
                                    spacing: 12
                                    Rectangle {
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                        radius: 6
                                        color: choice.modelData.palette.background
                                        border.color: choice.modelData.palette.borderInteractive
                                        border.width: 1
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: choice.modelData.palette.accent
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: choice.modelData.name
                                        color: root.selectedId === choice.modelData.id ? Theme.accent : Theme.text
                                        font { family: Theme.fontFamily; pixelSize: Theme.fontSmall; bold: root.selectedId === choice.modelData.id }
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        visible: root.configStore.theme === choice.modelData.id
                                        text: "✓"
                                        color: Theme.accent
                                        font.pixelSize: 14
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: catalog.count === 0
                                text: "No matching themes"
                                color: Theme.textMuted
                                font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 16

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "DESKTOP PREVIEW"
                                color: Theme.textMuted
                                font { family: Theme.fontFamily; pixelSize: Theme.fontSmall; bold: true }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.selectedTheme.kind === "light" ? "Light" : "Dark"
                                color: Theme.textMuted
                                font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
                            }
                        }

                        DesktopPreview {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: content.compact ? 130 : 220
                            colors: root.selectedTheme.palette
                            metrics: Theme.metricsFor(root.selectedId)
                            wallpaper: root.configStore.wallpaperPath
                            themeName: root.selectedTheme.name
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: root.selectedTheme.name
                                color: Theme.text
                                font { family: Theme.fontFamily; pixelSize: content.compact ? 20 : 28; bold: true }
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.selectedTheme.description
                                color: Theme.textMuted
                                font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            spacing: 8
                            visible: !content.compact
                            Repeater {
                                model: ["background", "surface", "surfaceRaised", "accent", "accentMuted", "text", "textMuted", "danger"]
                                Rectangle {
                                    required property string modelData
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: root.selectedTheme.palette[modelData]
                                    border.color: Theme.borderInteractive
                                    border.width: 1
                                }
                            }
                        }
                    }
                }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ActionButton {
                        text: "󰸉  Wallpaper"
                        accessibleName: "Choose wallpaper"
                        onClicked: {
                            const target = root.targetScreen
                            root.close()
                            root.wallpaperRequested(target)
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !content.compact
                        text: root.error !== "" ? root.error : "↑ ↓ Browse    Enter Apply    Esc Close"
                        color: root.error !== "" ? Theme.danger : Theme.textMuted
                        font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillWidth: true; visible: content.compact }
                    ActionButton {
                        objectName: "appearanceApply"
                        text: root.configStore.theme === root.selectedId ? "Current theme" : "Apply theme"
                        enabled: root.filteredThemes.length > 0
                        selected: true
                        implicitHeight: 38
                        onClicked: root.applySelected()
                    }
                }
            }
        }
    }
}
