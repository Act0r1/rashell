pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    property string activeName: "ayu-dark"

    readonly property FileView catalogFile: FileView {
        path: Quickshell.shellDir + "/core/themes.json"
        blockLoading: true
    }
    readonly property var catalog: JSON.parse(catalogFile.text())
    readonly property var names: catalog.map(function(entry) { return entry.id })
    readonly property var palettes: {
        const result = {}
        for (let index = 0; index < catalog.length; index++) {
            result[catalog[index].id] = catalog[index].palette
        }
        return result
    }

    function themeInfo(name) {
        const requested = String(name)
        for (let index = 0; index < catalog.length; index++) {
            if (catalog[index].id === requested) return catalog[index]
        }
        for (let index = 0; index < catalog.length; index++) {
            if (catalog[index].id === "ayu-dark") return catalog[index]
        }
        return catalog[0]
    }

    function metricsFor(name) {
        const requested = String(name)
        return {
            radius: 12,
            barHeight: 40,
            edgeMargin: requested === "raven" ? 4 : 0,
            sliderTrackHeight: 8
        }
    }

    function paletteFor(name) {
        const source = palettes[name] || palettes["ayu-dark"]
        return Object.assign({}, source, {
            accentMuted: source.accentSecondary || source.accentMuted,
            danger: source.dangerText || source.danger,
            borderInteractive: source.borderControl || source.borderInteractive
        })
    }

    readonly property var palette: paletteFor(activeName)
    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color surfaceRaised: palette.surfaceRaised
    readonly property color accent: palette.accent
    readonly property color accentMuted: palette.accentMuted
    readonly property color accentSecondary: palette.accentMuted
    readonly property color text: palette.text
    readonly property color textMuted: palette.textMuted
    readonly property color textDisabled: palette.textDisabled
    readonly property color textOnAccent: palette.textOnAccent
    readonly property color border: palette.border
    readonly property color borderInteractive: palette.borderInteractive
    readonly property color focus: palette.accent
    readonly property color danger: palette.danger
    readonly property color textOnDanger: palette.textOnDanger
    readonly property color success: palette.success || palette.accent
    readonly property color warning: palette.warning || palette.accent
    readonly property color info: palette.info || palette.accent
    readonly property color hoverSurface: Qt.tint(surface, Qt.alpha(accent, 0.04))
    readonly property color pressedSurface: Qt.tint(surface, Qt.alpha(accent, 0.08))
    readonly property color selectedSurface: Qt.tint(surface, Qt.alpha(accent, 0.06))
    readonly property color selectedHoverSurface: Qt.tint(surface, Qt.alpha(accent, 0.08))
    readonly property color selectedPressedSurface: Qt.tint(surface, Qt.alpha(accent, 0.10))
    readonly property color accentHover: Qt.lighter(accent, 1.08)
    readonly property color accentPressed: Qt.darker(accent, 1.08)
    readonly property color dangerSurface: Qt.tint(surface, Qt.alpha(danger, 0.10))

    property string selectedFontFamily: "Adwaita Sans"
    readonly property var fontFamilies: Qt.fontFamilies()
    readonly property string fontFamily: fontFamilies.indexOf(selectedFontFamily) !== -1
        ? selectedFontFamily : "Adwaita Sans"
    readonly property int fontSmall: 12
    readonly property int fontBody: 14
    readonly property int fontTitle: 17

    readonly property int spaceXs: 2
    readonly property int spaceSm: 4
    readonly property int spaceMd: 8
    readonly property int spaceLg: 12
    readonly property int spaceXl: 16

    readonly property int panelGap: 8
    readonly property int panelPadding: 16
    readonly property int controlHeight: 32
    readonly property int compactControlSize: 30
    readonly property int rowHeight: 40
    readonly property var metrics: metricsFor(activeName)
    readonly property int barHeight: metrics.barHeight
    readonly property int edgeMargin: metrics.edgeMargin
    readonly property int barHorizontalMargin: edgeMargin
    readonly property int radius: metrics.radius
    readonly property int borderWidth: 1
    readonly property int focusWidth: 2
    readonly property int sliderTrackHeight: metrics.sliderTrackHeight
}
