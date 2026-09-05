import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state

    required property var configStore

    property bool available: false
    property int temperatureCelsius: 0
    property int feelsLikeCelsius: 0
    property int humidityPercent: 0
    property real windMetersPerSecond: 0
    property real precipitationMm: 0
    property string condition: ""
    property string location: ""
    property int weatherCode: 0
    property string latitude: ""
    property string longitude: ""
    property date updatedAt: new Date(0)
    property bool refreshPending: false
    property bool forecastPending: false
    property var hourlyForecast: []
    property var dailyForecast: []
    property real utcOffsetSeconds: NaN
    property date clockUpdatedAt: new Date(0)
    property date clockNow: new Date()
    property var solarForecast: []

    readonly property bool stale: available && clockNow.getTime() - updatedAt.getTime() > 7200000
    readonly property bool cityTimeAvailable: isFinite(utcOffsetSeconds)
        && clockNow.getTime() - clockUpdatedAt.getTime() < 129600000
    readonly property date cityTime: new Date(clockNow.getTime() + utcOffsetSeconds * 1000)
    readonly property string cityTimeText: cityTimeAvailable
        ? String(cityTime.getUTCHours()).padStart(2, "0") + ":" + String(cityTime.getUTCMinutes()).padStart(2, "0") : ""
    readonly property string scenePhase: phaseAtCityTime()
    readonly property string sceneLabel: scenePhase === "unknown" ? "Local time unavailable"
        : scenePhase === "sunset" ? (cityTime.getUTCHours() < 12 ? "Dawn" : "Sunset")
        : scenePhase === "day" ? "Daylight" : "Night"

    readonly property string temperatureText: available ? temperatureCelsius + "°C" : "--°C"
    readonly property string icon: scenePhase === "night" && (weatherCode === 113 || weatherCode === 116)
        ? "󰖔" : iconForCode(weatherCode)
    readonly property bool refreshing: weatherProcess.running || forecastProcess.running
    readonly property string requestUrl: {
        const city = String(configStore.weatherLocation || "").trim()
        return "https://wttr.in/" + (city === "" ? "" : encodeURIComponent(city)) + "?format=j1"
    }
    readonly property string forecastUrl: latitude === "" || longitude === "" ? "" :
        "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + encodeURIComponent(latitude)
        + "&longitude=" + encodeURIComponent(longitude)
        + "&current=temperature_2m,is_day"
        + "&hourly=temperature_2m,precipitation_probability,weather_code"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
        + "&timezone=auto&forecast_days=6"

    function minutesFromTime(value) {
        const match = String(value || "").match(/(?:T|^| )(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$/i)
        if (!match) return NaN
        let hour = Number(match[1])
        const minute = Number(match[2])
        if (minute > 59 || (match[3] ? hour < 1 || hour > 12 : hour > 23)) return NaN
        if (match[3]) hour = hour % 12 + (match[3].toUpperCase() === "PM" ? 12 : 0)
        return hour * 60 + minute
    }

    function phaseAtCityTime() {
        if (!cityTimeAvailable || !isFinite(cityTime.getTime())) return "unknown"
        const date = cityTime.toISOString().slice(0, 10)
        const minutes = cityTime.getUTCHours() * 60 + cityTime.getUTCMinutes()
        const solar = solarForecast.find(day => day.date === date)
        if (solar && isFinite(solar.sunrise) && isFinite(solar.sunset) && solar.sunrise < solar.sunset) {
            if (Math.abs(minutes - solar.sunrise) <= 40 || Math.abs(minutes - solar.sunset) <= 45) return "sunset"
            return minutes > solar.sunrise && minutes < solar.sunset ? "day" : "night"
        }
        if (solar && solar.polarDay !== undefined) return solar.polarDay ? "day" : "night"
        if ((minutes >= 360 && minutes < 420) || (minutes >= 1050 && minutes < 1140)) return "sunset"
        return minutes >= 420 && minutes < 1050 ? "day" : "night"
    }

    function resetLocation() {
        available = false
        location = ""
        latitude = ""
        longitude = ""
        hourlyForecast = []
        dailyForecast = []
        solarForecast = []
        utcOffsetSeconds = NaN
        clockUpdatedAt = new Date(0)
        refresh()
    }

    function iconForCode(code) {
        if (code === 113) return "󰖙"
        if (code === 116) return "󰖕"
        if ([143, 248, 260].indexOf(code) !== -1) return "󰖑"
        if ([200, 386, 389, 392, 395].indexOf(code) !== -1) return "󰖓"
        if ([179, 182, 185, 227, 230, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].indexOf(code) !== -1) return "󰖘"
        if ([176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 317, 320, 353, 356, 359].indexOf(code) !== -1) return "󰖗"
        return "󰖐"
    }

    function iconForWmo(code) {
        if (code === 0) return "󰖙"
        if (code <= 2) return "󰖕"
        if (code === 3) return "󰖐"
        if (code <= 48) return "󰖑"
        if (code <= 67 || (code >= 80 && code <= 82)) return "󰖗"
        if (code <= 86) return "󰖘"
        return "󰖓"
    }

    function describeWmo(code) {
        if (code === 0) return "Clear"
        if (code <= 2) return "Partly cloudy"
        if (code === 3) return "Overcast"
        if (code <= 48) return "Fog"
        if (code <= 57) return "Drizzle"
        if (code <= 67) return "Rain"
        if (code <= 77) return "Snow"
        if (code <= 82) return "Rain showers"
        if (code <= 86) return "Snow showers"
        return "Thunderstorms"
    }

    function refresh() {
        if (weatherProcess.running) {
            refreshPending = true
            return
        }
        refreshPending = false
        weatherProcess.requestedUrl = requestUrl
        weatherProcess.running = true
    }

    function refreshForecast() {
        if (forecastUrl === "") return
        if (forecastProcess.running) {
            forecastPending = true
            return
        }
        forecastPending = false
        forecastProcess.requestedUrl = forecastUrl
        forecastProcess.running = true
    }

    function applyResponse(text) {
        try {
            const payload = JSON.parse(String(text || ""))
            const current = payload.current_condition && payload.current_condition.length > 0
                ? payload.current_condition[0] : null
            if (!current) return

            const temperature = Number(current.temp_C)
            const code = Number(current.weatherCode)
            if (!isFinite(temperature) || !isFinite(code)) return

            const description = current.weatherDesc && current.weatherDesc.length > 0
                ? current.weatherDesc[0].value : ""
            const area = payload.nearest_area && payload.nearest_area.length > 0
                ? payload.nearest_area[0] : null
            const areaName = area && area.areaName && area.areaName.length > 0
                ? area.areaName[0].value : ""

            const localMinutes = minutesFromTime(current.localObsDateTime)
            const observedMinutes = minutesFromTime(current.observation_time)
            const observationDate = String(current.localObsDateTime || "").match(/^(\d{4})-(\d{2})-(\d{2})/)
            if (!cityTimeAvailable && observationDate && isFinite(localMinutes) && isFinite(observedMinutes)) {
                const now = new Date()
                let observationUtc = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, observedMinutes)
                if (observationUtc > now.getTime() + 900000) observationUtc -= 86400000
                const localObservation = Date.UTC(Number(observationDate[1]), Number(observationDate[2]) - 1,
                    Number(observationDate[3]), 0, localMinutes)
                const offset = (localObservation - observationUtc) / 1000
                if (offset >= -43200 && offset <= 50400 && offset % 900 === 0 && now.getTime() - observationUtc < 10800000) {
                    utcOffsetSeconds = offset
                    clockUpdatedAt = now
                    clockNow = now
                }
            }
            if (solarForecast.length === 0 && payload.weather) {
                solarForecast = payload.weather.map(day => {
                    const astronomy = day.astronomy && day.astronomy.length ? day.astronomy[0] : {}
                    return { date: String(day.date), sunrise: minutesFromTime(astronomy.sunrise), sunset: minutesFromTime(astronomy.sunset) }
                })
            }

            temperatureCelsius = Math.round(temperature)
            feelsLikeCelsius = Math.round(Number(current.FeelsLikeC) || temperature)
            humidityPercent = Math.round(Number(current.humidity) || 0)
            windMetersPerSecond = (Number(current.windspeedKmph) || 0) / 3.6
            precipitationMm = Number(current.precipMM) || 0
            weatherCode = Math.round(code)
            condition = String(description || "")
            location = String(areaName || "")
            latitude = area ? String(area.latitude || "") : ""
            longitude = area ? String(area.longitude || "") : ""
            updatedAt = new Date()
            available = true
            Qt.callLater(refreshForecast)
        } catch (error) {
            console.warn("Weather response rejected: " + error)
        }
    }

    function applyForecastResponse(text) {
        try {
            const payload = JSON.parse(String(text || ""))
            if (!payload.hourly || !payload.daily || !Array.isArray(payload.hourly.time) || !Array.isArray(payload.daily.time)) return

            const offset = Number(payload.utc_offset_seconds)
            if (payload.utc_offset_seconds !== undefined && payload.utc_offset_seconds !== null && isFinite(offset) && Math.abs(offset) <= 50400) {
                utcOffsetSeconds = offset
                clockUpdatedAt = new Date()
                clockNow = new Date()
            }
            solarForecast = payload.daily.time.map((date, index) => {
                const sunrise = minutesFromTime(payload.daily.sunrise ? payload.daily.sunrise[index] : "")
                const sunset = minutesFromTime(payload.daily.sunset ? payload.daily.sunset[index] : "")
                const solar = { date: String(date), sunrise: sunrise, sunset: sunset }
                if (payload.daily.sunrise && payload.daily.sunset && (!isFinite(sunrise) || !isFinite(sunset)) && payload.current
                    && String(payload.current.time).slice(0, 10) === String(date)
                    && (payload.current.is_day === 0 || payload.current.is_day === 1)) solar.polarDay = payload.current.is_day === 1
                return solar
            })

            const currentTime = payload.current && payload.current.time ? payload.current.time : ""
            const hours = []
            for (let index = 0; index < payload.hourly.time.length && hours.length < 7; index++) {
                const time = String(payload.hourly.time[index])
                if (currentTime !== "" && time < currentTime) continue
                const code = Math.round(Number(payload.hourly.weather_code[index]) || 0)
                const hour = Number(time.slice(11, 13))
                const solar = solarForecast.find(day => day.date === time.slice(0, 10))
                const dark = solar && isFinite(solar.sunrise) && isFinite(solar.sunset)
                    ? hour * 60 < solar.sunrise || hour * 60 >= solar.sunset : hour < 6 || hour >= 19
                hours.push({
                    time: time.slice(11, 16),
                    temperature: Math.round(Number(payload.hourly.temperature_2m[index]) || 0),
                    probability: Math.round(Number(payload.hourly.precipitation_probability[index]) || 0),
                    icon: code <= 2 && dark ? "󰖔" : iconForWmo(code)
                })
            }
            hourlyForecast = hours

            const days = []
            for (let index = 1; index < payload.daily.time.length && days.length < 5; index++) {
                const code = Math.round(Number(payload.daily.weather_code[index]) || 0)
                const date = new Date(String(payload.daily.time[index]) + "T12:00:00")
                days.push({
                    day: Qt.formatDate(date, "ddd"),
                    icon: iconForWmo(code),
                    description: describeWmo(code),
                    minimum: Math.round(Number(payload.daily.temperature_2m_min[index]) || 0),
                    maximum: Math.round(Number(payload.daily.temperature_2m_max[index]) || 0)
                })
            }
            dailyForecast = days
        } catch (error) {
            console.warn("Weather forecast rejected: " + error)
        }
    }

    Process {
        id: weatherProcess
        property string requestedUrl: ""
        command: [
            "curl", "--fail", "--silent", "--show-error", "--max-time", "10",
            weatherProcess.requestedUrl
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (weatherProcess.requestedUrl === state.requestUrl) state.applyResponse(text)
            }
        }
        onExited: function() {
            if (state.refreshPending) Qt.callLater(state.refresh)
        }
    }

    Process {
        id: forecastProcess
        property string requestedUrl: ""
        command: [
            "curl", "--fail", "--silent", "--show-error", "--max-time", "10",
            forecastProcess.requestedUrl
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (forecastProcess.requestedUrl === state.forecastUrl) state.applyForecastResponse(text)
            }
        }
        onExited: function() {
            if (state.forecastPending) Qt.callLater(state.refreshForecast)
        }
    }

    Connections {
        target: state.configStore
        function onConfigLoaded() { state.refresh() }
        function onWeatherLocationChanged() { state.resetLocation() }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: state.clockNow = new Date()
    }

    Timer {
        interval: 1800000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: state.refresh()
    }
}
