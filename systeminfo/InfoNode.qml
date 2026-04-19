// InfoNode.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    property string title: ""
    property string value: ""
    property string icon: ""
    property string lineDirection: ""

    width: s(150); height: s(60)
    color: Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.8)
    radius: s(10)
    border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1)

    RowLayout {
        anchors.fill: parent; anchors.margins: s(10)
        Text { text: icon; font.family: "Iosevka Nerd Font"; font.pixelSize: s(20); color: mocha.blue }
        Column {
            Text { text: value; color: mocha.text; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: s(14) }
            Text { text: title; color: mocha.subtext0; font.family: "JetBrains Mono"; font.pixelSize: s(10) }
        }
    }

    // Vẽ đường line nối vào tâm (Sử dụng Shape hoặc đơn giản là Rectangle)
    Rectangle {
        visible: lineDirection !== ""
        width: (lineDirection === "left" || lineDirection === "right") ? s(80) : 1
        height: (lineDirection === "top" || lineDirection === "bottom") ? s(60) : 1
        color: Qt.rgba(mocha.blue.r, mocha.blue.g, mocha.blue.b, 0.3)
        
        anchors {
            top: lineDirection === "bottom" ? parent.bottom : undefined
            bottom: lineDirection === "top" ? parent.top : undefined
            left: lineDirection === "right" ? parent.right : undefined
            right: lineDirection === "left" ? parent.left : undefined
            horizontalCenter: (lineDirection === "top" || lineDirection === "bottom") ? parent.horizontalCenter : undefined
            verticalCenter: (lineDirection === "left" || lineDirection === "right") ? parent.verticalCenter : undefined
        }
    }
}