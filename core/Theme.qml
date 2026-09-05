pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    property string activeName: "muninn"

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
            if (catalog[index].id === "muninn") return catalog[index]
        }
        return catalog[0]
    }

    function metricsFor(name) {
        const requested = String(name)
        return {
            radius: requested === "talon" ? 0 : requested === "muninn" ? 2 : requested === "nevermore" ? 8 : 12,
            barHeight: requested === "talon" || requested === "nevermore" ? controlHeight
                : requested === "oilslick" ? 44 : 40,
            edgeMargin: requested === "nevermore" ? 2
                : requested === "ember" || requested === "raven" || requested === "jade" ? 4 : 0,
            sliderTrackHeight: requested === "talon" || requested === "muninn" ? 6 : 8
        }
    }

    readonly property var palette: palettes[activeName] || palettes.muninn
    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color surfaceRaised: palette.surfaceRaised
    readonly property color accent: palette.accent
    readonly property color accentMuted: palette.accentMuted
    readonly property color text: palette.text
    readonly property color textMuted: palette.textMuted
    readonly property color textDisabled: palette.textDisabled
    readonly property color textOnAccent: palette.textOnAccent
    readonly property color border: palette.border
    readonly property color borderInteractive: palette.borderInteractive
    readonly property color focus: palette.accent
    readonly property color danger: palette.danger
    readonly property color textOnDanger: palette.textOnDanger

    readonly property string fontFamily: "FiraCode Nerd Font"
    readonly property int fontSmall: 11
    readonly property int fontBody: 13
    readonly property int fontTitle: 15

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
