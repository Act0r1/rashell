.pragma library

function entry(id, name, comment, keywords, icon, enabled) {
    return { id: id, name: name, comment: comment, keywords: keywords, icon: icon, enabled: enabled !== false }
}

function entries(status, themes) {
    return [
        entry("panel.control", "Control center", "Connections, audio, appearance and session", "settings настройки управление", "preferences-system"),
        entry("panel.audio", "Audio devices", "Choose microphone and speakers", "sound volume звук микрофон наушники", "audio-card"),
        entry("audio.output-mute", "Toggle speaker mute", "Mute or unmute the current output", "sound volume звук динамики", "audio-volume-muted", status.outputUsable),
        entry("audio.input-mute", "Toggle microphone mute", "Mute or unmute the current input", "mic microphone микрофон", "microphone-sensitivity-muted", status.inputUsable),
        entry("panel.network", "Wi-Fi networks", "Connect to a wireless network", "network internet сеть интернет", "network-wireless"),
        entry("panel.bluetooth", "Bluetooth devices", "Connect headphones and other devices", "pair headphones блютуз наушники", "preferences-system-bluetooth"),
        entry("panel.notifications", "Notification history", "Read recent notifications", "alerts уведомления", "preferences-system-notifications"),
        entry("panel.dnd", "Do not disturb settings", "Choose how long to silence notification popups", "dnd quiet timer уведомления тишина таймер", "notifications-disabled"),
        entry("notifications.pause", "Pause notifications for 25 minutes", "Silence notification popups with a timer", "dnd quiet timer уведомления тишина таймер", "appointment-new"),
        entry("notifications.dnd", "Toggle do not disturb", status.doNotDisturb ? "Notifications are currently silenced" : "Silence notification popups", "dnd quiet уведомления тишина", "notifications-disabled"),
        entry("panel.calendar", "Calendar and reminders", "View dates and set a reminder", "time date календарь напоминания", "view-calendar"),
        entry("panel.weather", "Weather", "Forecast and location", "forecast погода", "weather-clear"),
        entry("panel.media", "Media controls", "Playback and current track", "music player музыка", "multimedia-player"),
        entry("panel.download", "Download media", "Download a video or image and copy it to the clipboard", "download yt-dlp video image скачать видео картинку загрузка буфер", "folder-download"),
        entry("panel.capture", "Screenshots and recording", "Capture an image or record the screen", "screenshot video скриншот запись", "camera-photo"),
        entry("panel.text", "Text capture and dictation", "Extract text or dictate locally", "ocr speech whisper текст диктовка", "insert-text"),
        entry("text.ocr", "Copy text from screen", status.ocrAvailable ? "Select an area for local text recognition" : status.ocrReason, "ocr screenshot распознать текст", "edit-copy", status.ocrAvailable && !status.captureBusy),
        entry("text.dictate", status.recording ? "Finish dictation" : "Start dictation", status.recording ? "Transcribe this recording to the clipboard" : status.dictationAvailable ? "Record speech and transcribe locally" : status.dictationReason, "speech whisper голос диктовка", "audio-input-microphone", status.recording || (status.dictationAvailable && !status.captureBusy)),
        entry("projects", "Open a project", "Choose a configured editor and terminal workspace", "code repository project код проект", "folder-development"),
        entry("session.keep-awake", status.keepAwake ? "Turn off keep awake" : "Keep screen awake", status.keepAwake ? "Allow the screen to sleep automatically" : "Prevent the screen from sleeping automatically", "screen sleep awake экран сон", "video-display"),
        entry("panel.system", "System monitor", "CPU, memory, storage and processes", "process memory cpu память процессы", "utilities-system-monitor"),
        entry("panel.updates", "Available updates", "Inspect package updates", "packages arch обновления пакеты", "system-software-update"),
        entry("wallpaper", "Choose wallpaper", "Pick a desktop background", "background обои", "preferences-desktop-wallpaper"),
        entry("appearance", "Appearance", "Browse themes with a desktop preview", "appearance colors theme тема темы оформление", "preferences-desktop-theme"),
        entry("bar-editor", "Customize bar", "Arrange the bar's widgets", "widgets panel панель виджеты", "preferences-desktop"),
        entry("bar-minimal", "Toggle minimal bar", "Switch between the full bar and a transparent clock and weather", "minimal mode bar panel", "preferences-desktop"),
        entry("lock", "Lock screen", "Lock the current session", "lock блокировка", "system-lock-screen")
    ].concat((themes || []).map(function(theme) {
        return entry("theme." + theme.id, "Theme · " + theme.name, theme.description,
            "appearance colors theme тема темы оформление " + theme.id, "preferences-desktop-theme")
    }))
}
