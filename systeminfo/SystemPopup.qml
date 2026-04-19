import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: popupRoot
    
    // 1. Nhận dữ liệu từ Main.qml truyền vào
    property string cpuValue: "0%"
    property string ramValue: "0%"

    // 2. Gọi cái ruột Dashboard (Phải khớp tên file SystemDashboard.qml)
    SystemDashboard {
        id: dashboard
        anchors.centerIn: parent
        
        // Truyền tiếp dữ liệu vào trong file SystemDashboard
        // (Đảm bảo bên file SystemDashboard.qml cũng có 2 property này)
        cpuValue: popupRoot.cpuValue
        ramValue: popupRoot.ramValue
    }
}