import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes

Item {
    id: dashboardRoot
    // Thêm 2 dòng này vào đầu file SysDashboard.qml
    property string cpuValue: "0%"
    property string ramValue: "0%"
    width: s(600)
    height: s(400)

    // Giả lập dữ liệu (Sau này ông bind từ sys_info.sh vào đây)
    property var sysStats: {
        "cpuName": "Ryzen 5 5600H",
        "cpuTemp": "52°C",
        "cpuSpeed": "3.8 GHz",
        "ramTotal": "16GB",
        "ramUsed": "6.2GB",
        "uptime": "02h 45m"
    }

    // Tâm điểm: Logo Hệ thống / Icon CPU lớn
    Rectangle {
        id: centerNode
        anchors.centerIn: parent
        width: s(120); height: s(120); radius: width/2
        color: Qt.rgba(mocha.blue.r, mocha.blue.g, mocha.blue.b, 0.2)
        border.color: mocha.blue
        border.width: 2

        Column {
            anchors.centerIn: parent
            spacing: s(2)
            Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: s(40); color: mocha.blue; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: "SYSTEM"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: s(12); color: mocha.text }
        }
        
        // Hiệu ứng vòng tròn xoay bên ngoài cho nó "nguy hiểm"
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + s(20); height: width; radius: width/2
            fillColor: "transparent"; border.color: Qt.rgba(mocha.blue.r, mocha.blue.g, mocha.blue.b, 0.1)
            border.width: 1
        }
    }

    // Các Node thông tin vệ tinh
    InfoNode {
        id: cpuTempNode
        title: "Temperature"
        value: sysStats.cpuTemp
        icon: ""
        anchors.horizontalCenter: centerNode.horizontalCenter
        anchors.bottom: centerNode.top
        anchors.bottomMargin: s(60)
        lineDirection: "bottom"
    }

    InfoNode {
        id: ramNode
        title: "Memory Used"
        value: barWindow.ramPercent // Dùng luôn biến từ bar của ông
        icon: ""
        anchors.left: centerNode.right
        anchors.leftMargin: s(80)
        anchors.verticalCenter: centerNode.verticalCenter
        lineDirection: "left"
    }

    InfoNode {
        id: uptimeNode
        title: "Uptime"
        value: sysStats.uptime
        icon: "󱎫"
        anchors.horizontalCenter: centerNode.horizontalCenter
        anchors.top: centerNode.bottom
        anchors.topMargin: s(60)
        lineDirection: "top"
    }

    InfoNode {
        id: cpuModelNode
        title: "CPU Model"
        value: sysStats.cpuName
        icon: "󰻠"
        anchors.right: centerNode.left
        anchors.rightMargin: s(80)
        anchors.verticalCenter: centerNode.verticalCenter
        lineDirection: "right"
    }
}