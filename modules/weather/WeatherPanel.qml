pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var weatherState
    required property var configStore

    readonly property var anchorWindow: coordinator.anchorItem ? coordinator.anchorItem.QsWindow.window : null
    readonly property var targetScreen: anchorWindow ? anchorWindow.screen : null
    readonly property real availablePanelHeight: {
        const anchor = coordinator.anchorItem
        const anchorBottom = anchorWindow && anchor
            ? anchorWindow.contentItem.mapFromItem(anchor.parent, anchor.x, anchor.y + anchor.height + Theme.panelGap).y
            : Theme.barHeight + Theme.panelGap
        return Math.max(1, (targetScreen ? targetScreen.height : 900)
            - Math.max(Theme.barHeight + Theme.panelGap, anchorBottom) - Theme.edgeMargin - Theme.spaceMd)
    }
    readonly property real frameChromeHeight: Math.max(Theme.compactControlSize, 36)
        + Theme.panelPadding * 2 + Theme.spaceLg * 2 + Theme.borderWidth

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight
    property bool editingLocation: false
    readonly property var dailyForecast: Array.isArray(weatherState.dailyForecast) ? weatherState.dailyForecast : []
    readonly property var dailyScale: {
        let minimum = Infinity
        let maximum = -Infinity
        for (const day of dailyForecast) {
            const range = dailyRange(day)
            if (!range) continue
            minimum = Math.min(minimum, range.minimum)
            maximum = Math.max(maximum, range.maximum)
        }
        return isFinite(minimum) && isFinite(maximum) ? { minimum, maximum } : null
    }

    function dailyTemperature(value) {
        return typeof value === "number" && isFinite(value) ? value : null
    }

    function dailyRange(day) {
        const minimum = dailyTemperature(day ? day.minimum : null)
        const maximum = dailyTemperature(day ? day.maximum : null)
        if (minimum === null || maximum === null) return null
        return { minimum: Math.min(minimum, maximum), maximum: Math.max(minimum, maximum) }
    }

    function dailyPosition(value) {
        if (!dailyScale || dailyScale.minimum === dailyScale.maximum) return 0.5
        const span = dailyScale.maximum - dailyScale.minimum
        const position = isFinite(span)
            ? (value - dailyScale.minimum) / span
            : (value / 2 - dailyScale.minimum / 2) / (dailyScale.maximum / 2 - dailyScale.minimum / 2)
        return isFinite(position) ? Math.max(0, Math.min(1, position)) : 0.5
    }

    function beginLocationEdit() {
        cityField.text = configStore.weatherLocation
        editingLocation = true
        Qt.callLater(() => {
            cityField.forceActiveFocus()
            root.revealFocusedControl()
        })
    }

    function revealFocusedControl() {
        const window = root.Window.window
        const item = window ? window.activeFocusItem : null
        if (!item) return
        let ancestor = item
        while (ancestor && ancestor !== weatherContent) ancestor = ancestor.parent
        if (!ancestor) return
        const top = weatherContent.mapFromItem(item, 0, 0).y
        const bottom = top + item.height
        if (top < weatherScroll.contentY) weatherScroll.contentY = Math.max(0, top - Theme.spaceSm)
        else if (bottom > weatherScroll.contentY + weatherScroll.height) {
            weatherScroll.contentY = Math.max(0, Math.min(weatherScroll.contentHeight - weatherScroll.height,
                bottom - weatherScroll.height + Theme.spaceSm))
        }
    }

    function saveLocation() {
        if (configStore.setWeatherLocation(cityField.text)) coordinator.close("weather-location")
    }

    function updatedText() {
        if (!weatherState.available) return "Waiting for weather data"
        if (weatherState.refreshing) return "Updating weather…"
        if (weatherState.stale) return "Last known weather · " + Qt.formatTime(weatherState.updatedAt, "HH:mm")
        return "Updated " + Qt.formatTime(weatherState.updatedAt, "HH:mm")
    }

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() { Qt.callLater(root.revealFocusedControl) }
    }

    PanelFrame {
        id: frame
        anchors.fill: parent
        title: "Weather"
        contentWidth: 504
        onCloseRequested: root.coordinator.close("close-control")

        Flickable {
            id: weatherScroll
            width: parent.width
            height: Math.min(contentHeight, Math.max(0, root.availablePanelHeight - root.frameChromeHeight))
            contentWidth: width
            contentHeight: weatherContent.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            onHeightChanged: Qt.callLater(root.revealFocusedControl)
            onContentHeightChanged: Qt.callLater(root.revealFocusedControl)

            ScrollBar.vertical: ScrollBar {
                id: weatherScrollbar
                policy: ScrollBar.AsNeeded
                visible: weatherScroll.contentHeight > weatherScroll.height
                width: 5
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 2
                    color: weatherScrollbar.pressed || weatherScrollbar.hovered ? Theme.accent : Theme.accentMuted
                }
                background: Item {}
            }

            Column {
                id: weatherContent
                width: weatherScroll.width - (weatherScrollbar.visible ? Theme.spaceMd : 0)
                spacing: Theme.spaceLg

                Item {
                    id: hero
                    width: parent.width
                    height: 258

                    WeatherScene {
                        anchors.fill: parent
                        weatherCode: root.weatherState.available ? root.weatherState.weatherCode : 0
                        scenePhase: root.weatherState.scenePhase
                        active: root.visible
                        stale: root.weatherState.stale
                    }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 18

                        Column {
                            anchors {
                                left: parent.left
                                top: parent.top
                            }
                            width: parent.width - 94
                            spacing: 4

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: root.weatherState.location || "Weather"
                                color: "white"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontTitle
                                font.bold: true
                                style: Text.Raised
                                styleColor: Qt.rgba(0, 0, 0, 0.55)
                            }

                            Text {
                                text: root.updatedText()
                                color: Qt.rgba(1, 1, 1, 0.76)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        Text {
                            anchors {
                                right: parent.right
                                top: parent.top
                            }
                            text: root.weatherState.icon
                            color: Qt.rgba(1, 1, 1, 0.94)
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                        }

                        Text {
                            anchors {
                                right: parent.right
                                top: parent.top
                                topMargin: 38
                            }
                            text: root.weatherState.cityTimeText
                            visible: text !== ""
                            color: Qt.rgba(1, 1, 1, 0.86)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                        }

                        Text {
                            anchors {
                                right: parent.right
                                top: parent.top
                                topMargin: 58
                            }
                            text: root.weatherState.sceneLabel
                            visible: root.weatherState.cityTimeAvailable
                            color: Qt.rgba(1, 1, 1, 0.66)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        Column {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: stats.top
                                bottomMargin: Theme.spaceMd
                            }
                            spacing: 1

                            Item {
                                width: parent.width
                                height: 66

                                Text {
                                    id: heroTemperature
                                    anchors.left: parent.left
                                    text: root.weatherState.available ? root.weatherState.temperatureCelsius : "--"
                                    color: "white"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 58
                                    font.bold: true
                                    font.letterSpacing: -2
                                    style: Text.Raised
                                    styleColor: Qt.rgba(0, 0, 0, 0.62)
                                }

                                Text {
                                    anchors {
                                        left: heroTemperature.right
                                        leftMargin: Theme.spaceSm
                                        top: heroTemperature.top
                                        topMargin: 11
                                    }
                                    text: "°C"
                                    color: Qt.rgba(1, 1, 1, 0.88)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 21
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.weatherState.available ? root.weatherState.condition : "Weather unavailable"
                                color: Qt.rgba(1, 1, 1, 0.92)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: root.weatherState.available
                                    ? "Feels like " + root.weatherState.feelsLikeCelsius + "°"
                                    : "Check the configured city"
                                color: Qt.rgba(1, 1, 1, 0.76)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            id: stats
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            spacing: Theme.spaceMd

                            Repeater {
                                model: [
                                    {
                                        value: root.weatherState.windMetersPerSecond.toFixed(1) + " m/s",
                                        label: "Wind"
                                    },
                                    {
                                        value: root.weatherState.humidityPercent + "%",
                                        label: "Humidity"
                                    },
                                    {
                                        value: root.weatherState.precipitationMm.toFixed(1) + " mm",
                                        label: "Rain"
                                    }
                                ]

                                Rectangle {
                                    id: statChip
                                    required property var modelData
                                    width: (stats.width - stats.spacing * 2) / 3
                                    height: 42
                                    radius: Math.min(Theme.radius, 9)
                                    color: Qt.rgba(0.07, 0.06, 0.12, 0.78)
                                    border.color: Qt.rgba(1, 1, 1, 0.12)
                                    border.width: Theme.borderWidth

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 0

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.weatherState.available ? statChip.modelData.value : "—"
                                            color: "white"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontBody
                                            font.bold: true
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: statChip.modelData.label
                                            color: Qt.rgba(1, 1, 1, 0.72)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }

                    }
                }

                Rectangle {
                    id: hourlyCard
                    width: parent.width
                    height: 136
                    color: Theme.surfaceRaised
                    radius: Theme.radius
                    border.color: Theme.border
                    border.width: Theme.borderWidth

                    Row {
                        id: hourlyRow
                        anchors {
                            fill: parent
                            margins: Theme.spaceSm
                        }
                        spacing: 2

                        Repeater {
                            model: root.weatherState.hourlyForecast

                            Item {
                                id: hourCell
                                required property var modelData
                                required property int index
                                width: (hourlyRow.width - hourlyRow.spacing * 6) / 7
                                height: hourlyRow.height

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.accent
                                    opacity: 0.06
                                    radius: Math.max(0, Theme.radius - 3)
                                    visible: hourCell.index === 0
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 8
                                    text: hourCell.modelData.time
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 28
                                    text: hourCell.modelData.icon
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontTitle
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 54
                                    text: hourCell.modelData.temperature + "°"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.bold: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 105
                                    text: hourCell.modelData.probability + "%"
                                    color: hourCell.modelData.probability > 0 ? Theme.accentMuted : Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    Canvas {
                        id: temperatureTrend
                        anchors {
                            left: hourlyRow.left
                            right: hourlyRow.right
                            top: hourlyRow.top
                            topMargin: 78
                        }
                        height: 24
                        property var forecast: root.weatherState.hourlyForecast
                        onForecastChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onVisibleChanged: if (visible) requestPaint()
                        Component.onCompleted: requestPaint()

                        onPaint: {
                            const context = getContext("2d")
                            context.clearRect(0, 0, width, height)
                            if (forecast.length < 2) return
                            const temperatures = forecast.map(hour => Number(hour.temperature))
                            const minimum = Math.min.apply(null, temperatures)
                            const span = Math.max(2, Math.max.apply(null, temperatures) - minimum)
                            const cellWidth = (width - hourlyRow.spacing * 6) / 7
                            const points = temperatures.map((temperature, index) => ({
                                x: cellWidth / 2 + index * (cellWidth + hourlyRow.spacing),
                                y: height - 4 - (temperature - minimum) / span * (height - 8)
                            }))
                            context.beginPath()
                            context.moveTo(points[0].x, points[0].y)
                            for (let index = 1; index < points.length; index++) {
                                const previous = points[index - 1]
                                const point = points[index]
                                const middle = (previous.x + point.x) / 2
                                context.bezierCurveTo(middle, previous.y, middle, point.y, point.x, point.y)
                            }
                            context.strokeStyle = Theme.accent
                            context.globalAlpha = 0.58
                            context.lineWidth = 1.5
                            context.stroke()
                            context.lineTo(points[points.length - 1].x, height)
                            context.lineTo(points[0].x, height)
                            context.closePath()
                            const gradient = context.createLinearGradient(0, 0, 0, height)
                            gradient.addColorStop(0, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2))
                            gradient.addColorStop(1, "transparent")
                            context.fillStyle = gradient
                            context.fill()
                            context.globalAlpha = 0.8
                            context.fillStyle = Theme.accent
                            for (const point of points) {
                                context.beginPath()
                                context.arc(point.x, point.y, 2, 0, Math.PI * 2)
                                context.fill()
                            }
                            context.globalAlpha = 1
                        }
                    }

                    Connections {
                        target: Theme
                        function onActiveNameChanged() { temperatureTrend.requestPaint() }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.weatherState.hourlyForecast.length === 0
                        text: "Hourly forecast unavailable"
                        color: Theme.textDisabled
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }

                Column {
                    width: parent.width
                    height: Math.max(34, root.dailyForecast.length * 34)

                    Repeater {
                        model: root.weatherState.dailyForecast

                        Item {
                            id: dailyRow
                            required property var modelData
                            readonly property var interval: root.dailyRange(modelData)
                            readonly property var minimum: interval ? interval.minimum
                                : root.dailyTemperature(modelData ? modelData.minimum : null)
                            readonly property var maximum: interval ? interval.maximum
                                : root.dailyTemperature(modelData ? modelData.maximum : null)
                            width: parent.width
                            height: 34

                            Text {
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                                width: 46
                                text: dailyRow.modelData ? dailyRow.modelData.day : "—"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: 52
                                    verticalCenter: parent.verticalCenter
                                }
                                width: 28
                                text: dailyRow.modelData ? dailyRow.modelData.icon : ""
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontTitle
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: 88
                                    right: dailyValues.left
                                    rightMargin: Theme.spaceMd
                                    verticalCenter: parent.verticalCenter
                                }
                                text: dailyRow.modelData ? dailyRow.modelData.description : ""
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                            }

                            Row {
                                id: dailyValues
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: Theme.spaceMd

                                Text {
                                    width: 44
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                    text: dailyRow.minimum !== null ? dailyRow.minimum + "°" : "—"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                }

                                Rectangle {
                                    id: dailyTrack
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 72
                                    height: 6
                                    radius: 3
                                    color: dailyRow.interval !== null ? Theme.border : "transparent"
                                    readonly property real startPosition: dailyRow.interval
                                        ? root.dailyPosition(dailyRow.interval.minimum) : 0.5
                                    readonly property real endPosition: dailyRow.interval
                                        ? root.dailyPosition(dailyRow.interval.maximum) : 0.5
                                    readonly property bool singleTemperature: dailyRow.interval !== null
                                        && dailyRow.interval.minimum === dailyRow.interval.maximum

                                    Rectangle {
                                        visible: dailyRow.interval !== null
                                        x: 3 + dailyTrack.startPosition * (dailyTrack.width - 6)
                                            - (dailyTrack.singleTemperature ? 3 : 0)
                                        y: (dailyTrack.height - height) / 2
                                        width: dailyTrack.singleTemperature ? 6
                                            : Math.max(0, dailyTrack.endPosition - dailyTrack.startPosition) * (dailyTrack.width - 6)
                                        height: dailyTrack.singleTemperature ? 6 : 4
                                        radius: height / 2
                                        color: Theme.accent
                                    }
                                }

                                Text {
                                    width: 44
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                    text: dailyRow.maximum !== null ? dailyRow.maximum + "°" : "—"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.dailyForecast.length === 0
                        text: "Daily forecast unavailable"
                        color: Theme.textDisabled
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }

                Rectangle {
                    width: parent.width
                    height: Theme.borderWidth
                    color: Theme.border
                }

                Row {
                    width: parent.width
                    height: Theme.compactControlSize
                    spacing: Theme.spaceMd
                    visible: !root.editingLocation

                    Text {
                        width: 38
                        height: parent.height
                        text: "City"
                        color: Theme.accentMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width - changeLocationButton.width - 38 - parent.spacing * 2
                        height: parent.height
                        text: String(root.configStore.weatherLocation || "").trim() || "Automatic location"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    ActionButton {
                        id: changeLocationButton
                        width: 96
                        text: "Change"
                        accessibleName: "Change weather city"
                        onClicked: root.beginLocationEdit()
                    }
                }

                TextField {
                    id: cityField
                    width: parent.width
                    height: Theme.rowHeight
                    visible: root.editingLocation
                    text: root.configStore.weatherLocation
                    placeholderText: "Automatic location"
                    color: Theme.text
                    placeholderTextColor: Theme.textMuted
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.textOnAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    leftPadding: Theme.spaceLg
                    rightPadding: Theme.spaceLg
                    Accessible.name: "Weather city"
                    onAccepted: root.saveLocation()

                    background: Rectangle {
                        color: Theme.surfaceRaised
                        border.color: cityField.activeFocus ? Theme.focus : Theme.borderInteractive
                        border.width: cityField.activeFocus ? Theme.focusWidth : Theme.borderWidth
                        radius: Theme.radius
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spaceMd
                    visible: root.editingLocation

                    ActionButton {
                        width: (parent.width - parent.spacing) / 2
                        text: "Auto"
                        accessibleName: "Use automatic weather location"
                        onClicked: cityField.text = ""
                    }

                    ActionButton {
                        width: (parent.width - parent.spacing) / 2
                        text: "Save"
                        selected: true
                        accessibleName: "Save weather city"
                        onClicked: root.saveLocation()
                    }
                }
            }
        }
    }

    Component.onCompleted: root.forceActiveFocus()
}
