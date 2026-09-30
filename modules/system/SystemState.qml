import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state

    property int cpuPercent: 0
    property var cpuHistory: []
    property int memoryPercent: 0
    property real memoryUsedBytes: 0
    property real memoryTotalBytes: 0
    property int gpuMemoryPercent: 0
    property real gpuMemoryUsedBytes: 0
    property real gpuMemoryTotalBytes: 0
    property string gpuMemorySource: ""
    property real temperatureCelsius: -1
    property real uptimeSeconds: 0
    property int diskIoPercent: 0
    property real diskReadBytesPerSecond: 0
    property real diskWriteBytesPerSecond: 0
    property real diskFreeBytes: 0
    property real diskTotalBytes: 0
    property int diskUsedPercent: 0
    property int updates: 0
    property bool updatesChecked: false
    property date updatesLastChecked: new Date(0)
    property string updatesError: ""
    readonly property alias topProcesses: processModel
    readonly property alias availableUpdates: updatesModel
    readonly property bool updatesRefreshing: updatesProcess.running

    ListModel {
        id: processModel
    }

    ListModel {
        id: updatesModel
    }

    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    property real previousDiskReadSectors: 0
    property real previousDiskWriteSectors: 0
    property real previousDiskIoMilliseconds: 0
    property real previousSampleMilliseconds: 0
    property string previousDiskDevice: ""

    function formatBytes(bytes, suffix) {
        if (!isFinite(bytes) || bytes < 0) return "0 B" + (suffix || "")

        const units = ["B", "KiB", "MiB", "GiB", "TiB"]
        let value = bytes
        let unit = 0
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024
            unit++
        }

        const precision = value >= 100 || unit === 0 ? 0 : value >= 10 ? 1 : 2
        return value.toFixed(precision) + " " + units[unit] + (suffix || "")
    }

    function formatUptime(seconds) {
        const totalHours = Math.max(0, Math.floor(seconds / 3600))
        const days = Math.floor(totalHours / 24)
        const hours = totalHours % 24
        const minutes = Math.floor((Math.max(0, seconds) % 3600) / 60)
        const paddedHours = hours < 10 ? "0" + hours : String(hours)
        const paddedMinutes = minutes < 10 ? "0" + minutes : String(minutes)
        return days > 0 ? days + "d " + paddedHours + "h" : hours + "h " + paddedMinutes + "m"
    }

    function sendProcessSignal(processId, signalName) {
        const allowedSignals = ["TERM", "KILL", "STOP", "CONT", "HUP"]
        const pid = Number(processId)
        if (!Number.isInteger(pid) || pid <= 1 || allowedSignals.indexOf(signalName) === -1) return false

        Quickshell.execDetached(["kill", "-s", signalName, String(pid)])
        return true
    }

    function refreshStats() {
        if (!statsProcess.running) statsProcess.running = true
    }

    function refreshUpdates() {
        if (updatesProcess.running) return
        updatesError = ""
        updatesProcess.running = true
    }

    function applyUpdates(output) {
        const lines = output.trim() === "" ? [] : output.trim().split(/\r?\n/)
        const packages = []

        for (let index = 0; index < lines.length; index++) {
            const match = lines[index].match(/^(\S+)\s+(\S+)\s+->\s+(\S+)$/)
            if (!match) return false
            packages.push({
                name: match[1],
                currentVersion: match[2],
                newVersion: match[3]
            })
        }

        updatesModel.clear()
        for (let index = 0; index < packages.length; index++) updatesModel.append(packages[index])
        updates = updatesModel.count
        return true
    }

    function finishUpdates(exitCode, output, errorOutput) {
        if (exitCode !== 0 && exitCode !== 2) {
            updatesError = exitCode === 124 ? "The check timed out. Try again."
                : exitCode === 127 ? "Install pacman-contrib to check repository updates."
                : errorOutput.trim().split(/\r?\n/)[0].slice(0, 220)
                    || "Could not check repositories. Try again."
            return
        }
        if (!applyUpdates(exitCode === 2 ? "" : output)) {
            updatesError = "Could not read the package list. Try checking again."
            return
        }
        updatesError = ""
        updatesChecked = true
        updatesLastChecked = new Date()
    }

    Process {
        id: statsProcess
        command: ["sh", "-c",
            "export LC_ALL=C; "
            + "cpu=$(awk '/^cpu / { total=0; for (i=2; i<=9 && i<=NF; i++) total += $i; print total, $5+$6; exit }' /proc/stat); "
            + "mem=$(awk '/^MemTotal:/ { total=$2 } /^MemAvailable:/ { available=$2 } END { print total, available }' /proc/meminfo); "
            + "source=$(findmnt -evrn -o SOURCE -T / 2>/dev/null | head -n1); resolved=$(readlink -f -- \"$source\" 2>/dev/null); device=$(basename -- \"$resolved\" 2>/dev/null); "
            + "if [ -b \"$resolved\" ] && [ -r \"/sys/class/block/$device/stat\" ]; then set -- $(cat \"/sys/class/block/$device/stat\"); disk=\"$3 $7 $10\"; else device=-; disk='0 0 0'; fi; "
            + "space=$(df -B1 --output=size,avail / 2>/dev/null | tail -n1); uptime=$(cut -d' ' -f1 /proc/uptime); "
            + "gpu='NONE 0 0'; if command -v nvidia-smi >/dev/null 2>&1; then nvidia=$(timeout 2s nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk -F',' 'function trim(value) { gsub(/^[ \\t]+|[ \\t]+$/, \"\", value); return value } { used=trim($1); total=trim($2); if (used ~ /^[0-9]+$/ && total ~ /^[0-9]+$/) { usedSum += used; totalSum += total; valid=1 } } END { if (valid && totalSum > 0) printf \"%d %d\", usedSum, totalSum }'); [ -n \"$nvidia\" ] && gpu=\"NVIDIA $nvidia\"; fi; "
            + "if [ \"$gpu\" = 'NONE 0 0' ]; then for memory in /sys/class/drm/card*/device/mem_info_vram_used; do total=\"${memory%_used}_total\"; [ -r \"$memory\" ] && [ -r \"$total\" ] || continue; used=$(cat \"$memory\" 2>/dev/null); totalBytes=$(cat \"$total\" 2>/dev/null); case \"$used\" in ''|*[!0-9]*) continue;; esac; case \"$totalBytes\" in ''|*[!0-9]*) continue;; esac; [ \"$totalBytes\" -gt 0 ] 2>/dev/null || continue; gpu=\"AMD $used $totalBytes\"; break; done; fi; "
            + "preferred=-1; fallback=-1; for input in /sys/class/hwmon/hwmon*/temp*_input; do [ -r \"$input\" ] || continue; value=$(cat \"$input\" 2>/dev/null); case \"$value\" in ''|*[!0-9-]*) continue;; esac; [ \"$value\" -ge 0 ] 2>/dev/null || continue; [ \"$value\" -le 200000 ] 2>/dev/null || continue; [ \"$value\" -gt \"$fallback\" ] && fallback=$value; sensor=$(cat \"$(dirname \"$input\")/name\" 2>/dev/null); label=$(cat \"${input%_input}_label\" 2>/dev/null); case \"$sensor $label\" in *coretemp*|*k10temp*|*zenpower*|*Package*|*Core*|*Tctl*|*Tdie*|*CPU*) [ \"$value\" -gt \"$preferred\" ] && preferred=$value;; esac; done; for input in /sys/class/thermal/thermal_zone*/temp; do [ -r \"$input\" ] || continue; value=$(cat \"$input\" 2>/dev/null); type=$(cat \"$(dirname \"$input\")/type\" 2>/dev/null); case \"$value\" in ''|*[!0-9-]*) continue;; esac; [ \"$value\" -ge 0 ] 2>/dev/null || continue; [ \"$value\" -le 200000 ] 2>/dev/null || continue; [ \"$value\" -gt \"$fallback\" ] && fallback=$value; case \"$type\" in *cpu*|*CPU*|*x86_pkg_temp*) [ \"$value\" -gt \"$preferred\" ] && preferred=$value;; esac; done; [ \"$preferred\" -ge 0 ] && temperature=$preferred || temperature=$fallback; "
            + "printf 'STAT\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' $cpu $mem \"$device\" $disk $space \"$uptime\" \"$temperature\"; printf 'GPU\\t%s\\t%s\\t%s\\n' $gpu; "
            + "ps -eo pid=,ppid=,pcpu=,rss=,comm= --sort=-pcpu 2>/dev/null | awk -v collector=$$ '$1 != collector && $2 != collector { pid=$1; cpu=$3; rss=$4; $1=$2=$3=$4=\"\"; sub(/^[[:space:]]+/, \"\"); printf \"PROC\\t%s\\t%s\\t%s\\t%s\\n\", pid, cpu, rss, $0; if (++count == 5) exit }'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split(/\r?\n/)
                let values = null
                let gpuValues = null
                const processes = []

                for (let index = 0; index < lines.length; index++) {
                    const fields = lines[index].split("\t")
                    if (fields[0] === "STAT" && fields.length >= 13) values = fields
                    if (fields[0] === "GPU" && fields.length >= 4) gpuValues = fields
                    if (fields[0] === "PROC" && fields.length >= 5) {
                        processes.push({
                            processId: Number(fields[1]),
                            processName: fields[4],
                            cpuPercent: Number(fields[2]),
                            memoryBytes: Number(fields[3]) * 1024
                        })
                    }
                }

                if (!values) return

                const cpuTotal = Number(values[1])
                const cpuIdle = Number(values[2])
                const memoryTotal = Number(values[3]) * 1024
                const memoryAvailable = Number(values[4]) * 1024
                const diskDevice = values[5]
                const diskReadSectors = Number(values[6])
                const diskWriteSectors = Number(values[7])
                const diskIoMilliseconds = Number(values[8])
                const diskTotal = Number(values[9])
                const diskFree = Number(values[10])
                const uptime = Number(values[11])
                const temperature = Number(values[12])
                const sampledAt = Date.now()
                const gpuSource = gpuValues ? gpuValues[1] : "NONE"
                const gpuUnit = gpuSource === "NVIDIA" ? 1024 * 1024 : 1
                const gpuUsed = gpuValues ? Number(gpuValues[2]) * gpuUnit : 0
                const gpuTotal = gpuValues ? Number(gpuValues[3]) * gpuUnit : 0

                const cpuDelta = cpuTotal - state.previousCpuTotal
                const idleDelta = cpuIdle - state.previousCpuIdle
                if (state.previousCpuTotal > 0 && cpuDelta > 0) {
                    state.cpuPercent = Math.max(0, Math.min(100, Math.round(100 * (cpuDelta - idleDelta) / cpuDelta)))
                    const history = state.cpuHistory.slice(-29)
                    history.push(state.cpuPercent)
                    state.cpuHistory = history
                }

                state.memoryTotalBytes = memoryTotal
                state.memoryUsedBytes = Math.max(0, memoryTotal - memoryAvailable)
                state.memoryPercent = memoryTotal > 0 ? Math.round(100 * state.memoryUsedBytes / memoryTotal) : 0
                state.gpuMemorySource = gpuSource
                state.gpuMemoryUsedBytes = isFinite(gpuUsed) && gpuUsed >= 0 ? gpuUsed : 0
                state.gpuMemoryTotalBytes = isFinite(gpuTotal) && gpuTotal > 0 ? gpuTotal : 0
                state.gpuMemoryPercent = state.gpuMemoryTotalBytes > 0
                    ? Math.max(0, Math.min(100, Math.round(100 * state.gpuMemoryUsedBytes / state.gpuMemoryTotalBytes))) : 0
                state.temperatureCelsius = temperature >= 0 ? temperature / 1000 : -1
                state.uptimeSeconds = isFinite(uptime) ? uptime : 0
                state.diskTotalBytes = diskTotal
                state.diskFreeBytes = diskFree
                state.diskUsedPercent = diskTotal > 0 ? Math.max(0, Math.min(100, Math.round(100 * (diskTotal - diskFree) / diskTotal))) : 0

                processModel.clear()
                for (let index = 0; index < processes.length; index++) processModel.append(processes[index])

                const sameDisk = diskDevice !== "-" && diskDevice === state.previousDiskDevice
                const elapsed = sampledAt - state.previousSampleMilliseconds
                if (sameDisk && state.previousSampleMilliseconds > 0 && elapsed > 0) {
                    const readDelta = Math.max(0, diskReadSectors - state.previousDiskReadSectors)
                    const writeDelta = Math.max(0, diskWriteSectors - state.previousDiskWriteSectors)
                    const ioDelta = Math.max(0, diskIoMilliseconds - state.previousDiskIoMilliseconds)
                    state.diskReadBytesPerSecond = readDelta * 512000 / elapsed
                    state.diskWriteBytesPerSecond = writeDelta * 512000 / elapsed
                    state.diskIoPercent = Math.max(0, Math.min(100, Math.round(ioDelta * 100 / elapsed)))
                } else {
                    state.diskReadBytesPerSecond = 0
                    state.diskWriteBytesPerSecond = 0
                    state.diskIoPercent = 0
                }

                state.previousCpuTotal = cpuTotal
                state.previousCpuIdle = cpuIdle
                state.previousDiskDevice = diskDevice
                state.previousDiskReadSectors = diskReadSectors
                state.previousDiskWriteSectors = diskWriteSectors
                state.previousDiskIoMilliseconds = diskIoMilliseconds
                state.previousSampleMilliseconds = sampledAt
            }
        }
    }

    Process {
        id: updatesProcess
        command: ["sh", "-c", "LC_ALL=C timeout 45s checkupdates"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            state.finishUpdates(exitCode, stdout.text, stderr.text)
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: state.refreshStats()
    }

    Timer {
        interval: 120000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: state.refreshUpdates()
    }
}
