pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core

GridLayout {
    id: root

    required property string selectedFamily
    required property string currentFamily
    readonly property bool compact: width < 750
    readonly property var families: {
        const preferred = ["Adwaita Sans", "Roboto Flex", "Noto Sans", "DejaVu Sans", "Open Sans", "JetBrainsMono Nerd Font", "FiraCode Nerd Font Mono"]
        const available = Theme.fontFamilies.slice().sort(function(a, b) { return a.localeCompare(b) })
        return preferred.filter(function(name) { return available.indexOf(name) !== -1 })
            .concat(available.filter(function(name) { return preferred.indexOf(name) === -1 }))
    }
    readonly property var filteredFamilies: families.filter(function(name) {
        return name.toLowerCase().indexOf(search.text.trim().toLowerCase()) !== -1
    })
    readonly property string previewFamily: Theme.fontFamilies.indexOf(selectedFamily) !== -1
        ? selectedFamily : "Adwaita Sans"

    signal familySelected(string family)
    signal applyRequested()

    columns: compact ? 1 : 2
    columnSpacing: 26
    rowSpacing: 20
    implicitHeight: compact ? 800 : 548

    function focusSearch(): void { search.forceActiveFocus() }
    function resetSearch(): void {
        search.text = ""
        Qt.callLater(function() { fontList.positionViewAtIndex(fontList.currentIndex, ListView.Contain) })
    }
    function step(delta): void {
        if (filteredFamilies.length === 0) return
        const index = filteredFamilies.indexOf(selectedFamily)
        const next = index < 0 ? 0 : Math.max(0, Math.min(filteredFamilies.length - 1, index + delta))
        familySelected(filteredFamilies[next])
        fontList.positionViewAtIndex(next, ListView.Contain)
    }

    ColumnLayout {
        Layout.preferredWidth: root.compact ? -1 : 280
        Layout.fillWidth: root.compact
        Layout.fillHeight: true
        Layout.preferredHeight: root.compact ? 260 : -1
        spacing: 12

        TextField {
            id: search
            objectName: "fontSearch"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            placeholderText: "Search installed fonts…"
            color: Theme.text
            placeholderTextColor: Theme.textMuted
            selectionColor: Theme.accent
            selectedTextColor: Theme.textOnAccent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            leftPadding: 12
            rightPadding: 12
            Accessible.name: "Search installed fonts"
            onAccepted: {
                if (root.filteredFamilies.length === 0) return
                if (root.filteredFamilies.indexOf(root.selectedFamily) === -1)
                    root.familySelected(root.filteredFamilies[0])
                root.applyRequested()
            }
            onTextChanged: fontList.positionViewAtBeginning()
            background: Rectangle {
                color: Theme.surface
                radius: 8
                border.color: search.activeFocus ? Theme.focus : Theme.borderInteractive
                border.width: search.activeFocus ? Theme.focusWidth : Theme.borderWidth
            }
        }

        Text {
            text: root.filteredFamilies.length + (root.filteredFamilies.length === 1 ? " installed family" : " installed families")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        ListView {
            id: fontList
            objectName: "fontFamilyList"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.filteredFamilies
            currentIndex: root.filteredFamilies.indexOf(root.selectedFamily)
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Button {
                id: choice
                required property string modelData
                width: fontList.width - 12
                height: 48
                hoverEnabled: true
                leftPadding: 12
                rightPadding: 12
                Accessible.name: modelData + (root.currentFamily === modelData ? ", current font" : "")
                onClicked: root.familySelected(modelData)
                onActiveFocusChanged: if (activeFocus) root.familySelected(modelData)
                Keys.onReturnPressed: root.applyRequested()
                Keys.onEnterPressed: root.applyRequested()

                contentItem: RowLayout {
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: choice.modelData
                        color: root.selectedFamily === choice.modelData ? Theme.accent : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.bold: root.selectedFamily === choice.modelData
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: root.currentFamily === choice.modelData
                        text: "✓"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }
                }
                background: Rectangle {
                    color: root.selectedFamily === choice.modelData ? Theme.selectedSurface
                        : choice.down ? Theme.pressedSurface : choice.hovered ? Theme.hoverSurface : Theme.surface
                    radius: 8
                    border.color: choice.visualFocus ? Theme.focus
                        : root.selectedFamily === choice.modelData ? Theme.accent : Theme.border
                    border.width: choice.visualFocus ? Theme.focusWidth : Theme.borderWidth
                }
            }

            Text {
                anchors.centerIn: parent
                visible: fontList.count === 0
                text: "No matching fonts"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: root.selectedFamily
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 24
            font.bold: true
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: samples.implicitHeight + 48
            color: Theme.surface
            radius: Theme.radius
            border.color: Theme.border
            border.width: Theme.borderWidth

            Column {
                id: samples
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
                spacing: 22

                Text {
                    width: parent.width
                    text: "Aa Бб 0123"
                    color: Theme.accent
                    font.family: root.previewFamily
                    font.pixelSize: 42
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: "A place for everything\nВсё на своём месте"
                    color: Theme.text
                    font.family: root.previewFamily
                    font.pixelSize: Theme.fontTitle
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: "The quick brown fox jumps over the lazy dog.\nСъешь ещё этих мягких французских булок, да выпей чаю."
                    color: Theme.text
                    font.family: root.previewFamily
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: "09:41   23°   100%   1 234,56"
                    color: Theme.text
                    font.family: root.previewFamily
                    font.pixelSize: Theme.fontBody
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: "Small details · Подписи и уведомления"
                    color: Theme.textMuted
                    font.family: root.previewFamily
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "One family across Rashell. Heading, body and caption sizes stay balanced."
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
        }
    }
}
