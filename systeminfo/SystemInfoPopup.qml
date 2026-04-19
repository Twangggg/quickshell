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
        return scaler.s(val); 
    }

    function formatUptime(seconds) {
        var days = Math.floor(seconds / 86400);
        var hours = Math.floor((seconds % 86400) / 3600);
        var mins = Math.floor((seconds % 3600) / 60);
        if (days > 0) return days + "d " + hours + "h";
        if (hours > 0) return hours + "h " + mins + "m";
        return mins + "m";
    }

    function getBarWidth(percent, maxWidth) {
        return maxWidth * Math.min(100, percent) / 100;
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
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
    readonly property color red: _theme.red
    readonly property color sapphire: _theme.sapphire

    property real introState: 0
    property real globalOrbitAngle: 0

    property string cpuPercent: "0"
    property string ramPercent: "0"
    property string cpuTemp: "0"
    property string cpuFreq: "0"
    property string loadAvg: "0.00"
    property string uptime: "0m"
    property string procCount: "0"
    property string diskPercent: "0"

    Process {
        id: sysinfoReader
        command: ["bash", "-c", window.scriptsDir + "/watchers/sysinfo_fetch.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        window.cpuPercent = data.cpu;
                        window.ramPercent = data.ram;
                        window.cpuTemp = data.temp;
                        window.cpuFreq = data.freq;
                        window.loadAvg = data.load || "0.00";
                        window.uptime = formatUptime(data.uptime);
                        window.procCount = data.procs;
                        window.diskPercent = data.disk;
                    } catch(e) {}
                }
            }
        }
    }

    Component.onCompleted: {
        introState = 1.0;
    }

    Rectangle {
        anchors.fill: parent
        radius: window.s(16)
        color: window.base

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: window.s(16)
            spacing: window.s(12)

            // Header
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "System"
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    font.pixelSize: window.s(14)
                    color: window.text
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: window.uptime + " 󱎫"
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(11)
                    color: window.subtext0
                }
            }

            // CPU Section
            ColumnLayout {
                spacing: window.s(4)
                RowLayout {
                    Text {
                        text: "CPU"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: window.s(12)
                        color: window.blue
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: window.cpuPercent + "%"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        font.pixelSize: window.s(12)
                        color: window.text
                    }
                }
                // CPU Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(8)
                    radius: window.s(4)
                    color: window.surface0
                    Rectangle {
                        width: window.s(350) * parseInt(window.cpuPercent || 0) / 100
                        height: window.s(8)
                        radius: window.s(4)
                        color: window.blue
                    }
                }
                // CPU Details
                RowLayout {
                    Text {
                        text: window.cpuTemp + "°C 󰔏"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(10)
                        color: window.yellow
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: window.cpuFreq + " MHz 󰒍"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(10)
                        color: window.green
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Load: " + window.loadAvg
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(10)
                        color: window.mauve
                    }
                }
            }

            // RAM Section
            ColumnLayout {
                spacing: window.s(4)
                RowLayout {
                    Text {
                        text: "MEM"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: window.s(12)
                        color: window.teal
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: window.ramPercent + "%"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        font.pixelSize: window.s(12)
                        color: window.text
                    }
                }
                // RAM Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(8)
                    radius: window.s(4)
                    color: window.surface0
                    Rectangle {
                        width: window.s(350) * parseInt(window.ramPercent || 0) / 100
                        height: window.s(8)
                        radius: window.s(4)
                        color: window.teal
                    }
                }
                // RAM Details
                RowLayout {
                    Text {
                        text: window.procCount + " procs 󰀇"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(10)
                        color: window.sapphire
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            // Disk Section
            ColumnLayout {
                spacing: window.s(4)
                RowLayout {
                    Text {
                        text: "DISK"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: window.s(12)
                        color: window.peach
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: window.diskPercent + "%"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        font.pixelSize: window.s(12)
                        color: window.text
                    }
                }
                // Disk Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(8)
                    radius: window.s(4)
                    color: window.surface0
                    Rectangle {
                        width: window.s(350) * parseInt(window.diskPercent || 0) / 100
                        height: window.s(8)
                        radius: window.s(4)
                        color: window.peach
                    }
                }
            }

            // Quick Stats Row
            RowLayout {
                spacing: window.s(8)
                Layout.topMargin: window.s(8)

                // Temp
                Rectangle {
                    Layout.preferredWidth: window.s(100)
                    Layout.preferredHeight: window.s(40)
                    radius: window.s(8)
                    color: window.surface0
                    ColumnLayout {
                        anchors.centerIn: parent
                        Text {
                            text: window.cpuTemp + "°C"
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: window.s(14)
                            color: window.yellow
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Freq
                Rectangle {
                    Layout.preferredWidth: window.s(100)
                    Layout.preferredHeight: window.s(40)
                    radius: window.s(8)
                    color: window.surface0
                    ColumnLayout {
                        anchors.centerIn: parent
                        Text {
                            text: window.cpuFreq
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: window.s(14)
                            color: window.green
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Procs
                Rectangle {
                    Layout.preferredWidth: window.s(100)
                    Layout.preferredHeight: window.s(40)
                    radius: window.s(8)
                    color: window.surface0
                    ColumnLayout {
                        anchors.centerIn: parent
                        Text {
                            text: window.procCount
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: window.s(14)
                            color: window.mauve
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            sysinfoReader.running = false;
            sysinfoReader.running = true;
        }
    }
}