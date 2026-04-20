import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell"

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }

    function s(val) {
        return scaler.s(val)
    }

    function clampPercent(value) {
        return Math.max(0, Math.min(100, Number(value) || 0))
    }

    function formatUptime(seconds) {
        var total = Number(seconds) || 0
        var days = Math.floor(total / 86400)
        var hours = Math.floor((total % 86400) / 3600)
        var mins = Math.floor((total % 3600) / 60)
        if (days > 0) return days + "d " + hours + "h"
        if (hours > 0) return hours + "h " + mins + "m"
        return mins + "m"
    }

    function alpha(color, amount) {
        return Qt.rgba(color.r, color.g, color.b, amount)
    }

    function formatGiB(value) {
        var n = Number(value) || 0
        return n.toFixed(1) + " GiB"
    }

    function formatDiskUsage() {
        var used = Number(diskUsedGiB) || 0
        var total = Number(diskTotalGiB) || 0
        if (total <= 0) return "-- / --"
        return used.toFixed(1) + "/" + total.toFixed(1) + " GiB"
    }

    function ringAngle(percent) {
        return -210 + 240 * clampPercent(percent) / 100
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color blue: _theme.blue
    readonly property color teal: _theme.teal
    readonly property color yellow: _theme.yellow
    readonly property color peach: _theme.peach
    readonly property color green: _theme.green
    readonly property color mauve: _theme.mauve
    readonly property color sapphire: _theme.sapphire
    readonly property color lavender: _theme.lavender

    property string cpuPercent: "0"
    property string ramPercent: "0"
    property string cpuTemp: "0"
    property string cpuFreq: "0"
    property string loadAvg: "0.00"
    property string uptime: "0m"
    property string procCount: "0"
    property string diskPercent: "0"
    property string cpuModel: "System Processor"
    property string ifaceName: "--"
    property string diskUsedGiB: "0"
    property string diskTotalGiB: "0"
    property string gpuName: "Graphics Adapter"
    property string gpuPercent: "0"
    property string gpuMemUsed: "0"
    property string gpuMemTotal: "0"
    property string netDown: "0.0"
    property string netUp: "0.0"
    property var cpuHistory: [8, 11, 12, 14, 16, 19, 22, 24, 27, 31, 35, 39, 41, 40, 37, 34, 30, 27, 23, 20, 18, 15, 9, 9]
    property var ramHistory: [16, 16, 17, 18, 19, 20, 22, 23, 25, 27, 28, 31, 34, 34, 33, 31, 29, 28, 27, 27, 26, 26, 26, 26]
    property var tempHistory: [32, 33, 33, 34, 34, 35, 36, 37, 38, 40, 41, 42, 43, 43, 42, 41, 40, 39, 38, 38, 37, 37, 38, 43]

    readonly property real cpuValue: clampPercent(cpuPercent)
    readonly property real ramValue: clampPercent(ramPercent)
    readonly property real diskValue: clampPercent(diskPercent)
    readonly property real gpuValue: clampPercent(gpuPercent)
    readonly property real ramAllocValue: ramValue
    readonly property string memoryFootprintText: formatGiB(memUsedGiB) + " / " + formatGiB(memTotalGiB)
    readonly property real memTotalGiB: Number(memTotalMiB) / 1024
    readonly property real memUsedGiB: Number(memUsedMiB) / 1024
    property string memUsedMiB: "0"
    property string memTotalMiB: "0"

    function updateHistories() {
        cpuHistory = cpuHistory.slice(1).concat([cpuValue])
        ramHistory = ramHistory.slice(1).concat([ramValue])
        tempHistory = tempHistory.slice(1).concat([Math.max(0, Math.min(100, Number(cpuTemp) || 0))])
    }

    Process {
        id: sysinfoReader
        command: ["bash", "-c", window.scriptsDir + "/watchers/sysinfo_fetch.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = this.text.trim()
                if (txt === "")
                    return
                try {
                    var data = JSON.parse(txt)
                    window.cpuPercent = String(data.cpu || 0)
                    window.ramPercent = String(data.ram || 0)
                    window.cpuTemp = String(data.temp || 0)
                    window.cpuFreq = String(data.freq || 0)
                    window.loadAvg = String(data.load || "0.00")
                    window.uptime = formatUptime(data.uptime)
                    window.procCount = String(data.procs || 0)
                    window.diskPercent = String(data.disk || 0)
                    updateHistories()
                } catch (e) {
                    console.log("SystemInfoPopup: failed to parse sysinfo json", e)
                }
            }
        }
    }

    Process {
        id: profileReader
        command: ["bash", "-lc", "cpu_model=$(awk -F: '/model name/ {gsub(/^ +/, \"\", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null); iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}'); disk=$(df -BG / 2>/dev/null | awk 'NR==2 {gsub(/G/, \"\", $2); gsub(/G/, \"\", $3); print $3 \"|\" $2}'); mem=$(free -m 2>/dev/null | awk '/^Mem:/ {print $3 \"|\" $2}'); if command -v nvidia-smi >/dev/null 2>&1; then gpu=$(nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1); fi; printf '{\"cpuModel\":\"%s\",\"iface\":\"%s\",\"disk\":\"%s\",\"mem\":\"%s\",\"gpu\":\"%s\"}' \"${cpu_model:-System Processor}\" \"${iface:---}\" \"${disk:-0|0}\" \"${mem:-0|0}\" \"${gpu:-Integrated GPU,0,0,0}\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = this.text.trim()
                if (txt === "")
                    return
                try {
                    var data = JSON.parse(txt)
                    window.cpuModel = data.cpuModel || window.cpuModel
                    window.ifaceName = data.iface || "--"

                    var diskParts = String(data.disk || "0|0").split("|")
                    window.diskUsedGiB = diskParts[0] || "0"
                    window.diskTotalGiB = diskParts[1] || "0"

                    var memParts = String(data.mem || "0|0").split("|")
                    window.memUsedMiB = memParts[0] || "0"
                    window.memTotalMiB = memParts[1] || "0"

                    var gpuParts = String(data.gpu || "Integrated GPU,0,0,0").split(",")
                    window.gpuName = (gpuParts[0] || "Graphics Adapter").trim()
                    window.gpuPercent = (gpuParts[1] || "0").trim()
                    window.gpuMemUsed = (gpuParts[2] || "0").trim()
                    window.gpuMemTotal = (gpuParts[3] || "0").trim()
                } catch (e) {
                    console.log("SystemInfoPopup: failed to parse profile json", e)
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: window.s(20)
        color: alpha(window.base, 0.98)
        border.width: 1
        border.color: alpha(window.lavender, 0.14)

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: alpha(window.surface2, 0.4)
        }

        Rectangle {
            width: window.s(300)
            height: width
            radius: width / 2
            x: window.s(70)
            y: window.s(100)
            color: alpha(window.blue, 0.08)
        }

        Rectangle {
            width: window.s(260)
            height: width
            radius: width / 2
            x: window.s(980)
            y: window.s(360)
            color: alpha(window.mauve, 0.06)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: window.s(18)
            spacing: window.s(14)

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }

                Text {
                    text: window.cpuModel
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(11)
                    color: alpha(window.subtext0, 0.9)
                    elide: Text.ElideRight
                    Layout.preferredWidth: window.s(420)
                    horizontalAlignment: Text.AlignRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: window.s(184)
                Layout.maximumHeight: window.s(184)
                spacing: window.s(14)

                Repeater {
                    model: [
                        { title: "CPU", value: window.cpuValue, detail: window.cpuTemp + "°C  |  " + window.cpuFreq + " MHz", color: window.blue, revealDelay: 0 },
                        { title: "GPU", value: window.gpuValue, detail: window.gpuMemUsed + " / " + window.gpuMemTotal + " MiB", color: window.mauve, revealDelay: 120 },
                        { title: "RAM", value: window.ramValue, detail: window.memoryFootprintText, color: window.sapphire, revealDelay: 240 }
                    ]

                    delegate: Rectangle {
                        id: gaugeCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: window.s(198)
                        Layout.maximumHeight: window.s(198)
                        Layout.preferredWidth: window.s(260)
                        Layout.maximumWidth: window.s(260)
                        radius: window.s(18)
                        color: alpha(window.mantle, 0.84)
                        border.width: 1
                        border.color: alpha(window.surface2, 0.55)
                        property real targetPercent: modelData.value
                        property real displayPercent: 0
                        property bool introPlayed: false

                        onTargetPercentChanged: {
                            displayPercent = targetPercent
                        }

                        Timer {
                            id: introStart
                            interval: modelData.revealDelay
                            repeat: false
                            onTriggered: {
                                gaugeCard.displayPercent = gaugeCard.targetPercent
                            }
                        }

                        Timer {
                            id: introFinish
                            interval: modelData.revealDelay + 1200
                            repeat: false
                            onTriggered: {
                                gaugeCard.introPlayed = true
                            }
                        }

                        Component.onCompleted: {
                            introStart.restart()
                            introFinish.restart()
                        }

                        Behavior on displayPercent {
                            enabled: !gaugeCard.introPlayed
                            SequentialAnimation {
                                NumberAnimation { duration: 1100; easing.type: Easing.OutCubic }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: window.s(14)
                            spacing: window.s(6)

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Canvas {
                                    id: gaugeCanvas
                                    anchors.centerIn: parent
                                    width: window.s(154)
                                    height: width
                                    property real percent: gaugeCard.displayPercent
                                    property color strokeColor: modelData.color

                                    onPercentChanged: requestPaint()

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.reset()

                                        var cx = width / 2
                                        var cy = height / 2
                                        var radius = width / 2 - window.s(14)
                                        var startAngle = -90 * Math.PI / 180
                                        var sweepAngle = Math.PI * 2 * percent / 100

                                        ctx.beginPath()
                                        ctx.strokeStyle = alpha(window.surface2, 0.7)
                                        ctx.lineWidth = window.s(13)
                                        ctx.lineCap = "round"
                                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
                                        ctx.stroke()

                                        ctx.beginPath()
                                        ctx.strokeStyle = strokeColor
                                        ctx.lineWidth = window.s(13)
                                        ctx.lineCap = "round"
                                        ctx.arc(cx, cy, radius, startAngle, startAngle + sweepAngle, false)
                                        ctx.stroke()
                                    }
                                }

                                Rectangle {
                                    width: window.s(166)
                                    height: width
                                    radius: width / 2
                                    anchors.centerIn: gaugeCanvas
                                    color: alpha(modelData.color, 0.06)
                                    border.width: 1
                                    border.color: alpha(modelData.color, 0.12)
                                    scale: 0.96
                                    opacity: 0.42

                                    SequentialAnimation on scale {
                                        running: true
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 1.04; duration: 1700; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 0.96; duration: 1700; easing.type: Easing.InOutSine }
                                    }

                                    SequentialAnimation on opacity {
                                        running: true
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.68; duration: 1700; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 0.42; duration: 1700; easing.type: Easing.InOutSine }
                                    }
                                }

                                Rectangle {
                                    width: window.s(88)
                                    height: width
                                    radius: width / 2
                                    anchors.centerIn: gaugeCanvas
                                    color: alpha(window.base, 0.95)
                                    border.width: 1
                                    border.color: alpha(modelData.color, 0.35)

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: window.s(3)

                                        Text {
                                            text: Math.round(gaugeCard.displayPercent) + "%"
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.DemiBold
                                            font.pixelSize: window.s(22)
                                            color: alpha(window.text, 0.99)
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }

                                        Text {
                                            text: modelData.title
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: window.s(9.5)
                                            color: alpha(modelData.color, 1.0)
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }
                            }

                            Text {
                                text: modelData.detail
                                font.family: "JetBrains Mono"
                                font.pixelSize: window.s(12)
                                color: alpha(window.text, 0.82)
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: window.s(14)
                rowSpacing: window.s(10)

                Repeater {
                    model: [
                        { title: "DISK I/O", value: "R " + window.netDown + " MB/s  |  W " + window.netUp + " MB/s", detail: "LIVE READ / WRITE THROUGHPUT", color: window.sapphire },
                        { title: "SESSION", value: "IFACE " + window.ifaceName.toUpperCase() + "  |  UPTIME " + window.uptime, detail: "CURRENT LINK AND RUNTIME", color: window.blue },
                        { title: "LOAD AVG", value: window.loadAvg, detail: "CURRENT SYSTEM LOAD", color: window.lavender },
                        { title: "PROCESSES", value: window.procCount, detail: "ACTIVE TASK COUNT", color: window.blue },
                        { title: "DISK STATUS", value: formatDiskUsage(), detail: "ROOT USAGE " + Math.round(window.diskValue) + "%", color: window.yellow },
                        { title: "NETWORK", value: "↓ " + window.netDown + " MB/s  ↑ " + window.netUp + " MB/s", detail: "LINK " + window.ifaceName.toUpperCase(), color: window.blue }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: window.s(60)
                        Layout.maximumHeight: window.s(66)
                        radius: window.s(16)
                        color: alpha(window.mantle, 0.8)
                        border.width: 1
                        border.color: alpha(window.surface2, 0.48)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: window.s(12)
                            spacing: window.s(4)

                            Text {
                                text: modelData.title
                                font.family: "JetBrains Mono"
                                font.pixelSize: window.s(9)
                                font.letterSpacing: 2
                                color: alpha(window.text, 0.8)
                            }

                            Text {
                                text: modelData.value
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                                font.pixelSize: window.s(13)
                                color: alpha(modelData.color, 0.98)
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                Layout.fillWidth: true
                            }

                            Item { Layout.fillHeight: true }

                            // Text {
                            //     text: modelData.detail
                            //     font.family: "JetBrains Mono"
                            //     font.pixelSize: window.s(9)
                            //     color: alpha(window.subtext0, 0.92)
                            //     elide: Text.ElideRight
                            //     Layout.fillWidth: true
                            // }
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 2200
        running: true
        repeat: true
        onTriggered: {
            sysinfoReader.running = false
            sysinfoReader.running = true
        }
    }

}
