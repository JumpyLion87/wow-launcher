import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Button {
    id: control
    height: Theme.Theme.buttonHeight
    
    background: Rectangle {
        color: {
            if (!control.enabled) return "#0A0A0A"
            if (control.pressed) return "#1A2A3A"
            if (control.hovered) return "#1E3346"
            return "#152536"
        }
        radius: 3
        
        // Верхняя грань (блик)
        Rectangle {
            width: parent.width
            height: 1
            color: {
                if (!control.enabled) return "#252525"
                if (control.pressed) return "#2A4055"
                if (control.hovered) return "#3A5570"
                return "#2A4055"
            }
            opacity: control.pressed ? 0.5 : 1
        }
        
        // Нижняя грань (тень)
        Rectangle {
            width: parent.width
            height: 1
            anchors.bottom: parent.bottom
            color: "#000000"
            opacity: 0.5
        }
        
        // Боковые грани
        Rectangle {
            width: 1
            height: parent.height
            color: {
                if (!control.enabled) return "#252525"
                if (control.pressed) return "#2A4055"
                if (control.hovered) return "#3A5570"
                return "#2A4055"
            }
        }
        
        Rectangle {
            width: 1
            height: parent.height
            anchors.right: parent.right
            color: {
                if (!control.enabled) return "#252525"
                if (control.pressed) return "#2A4055"
                if (control.hovered) return "#3A5570"
                return "#2A4055"
            }
        }
        
        // Эффект свечения при наведении
        Rectangle {
            anchors.fill: parent
            color: "#3A5570"
            opacity: control.hovered ? 0.1 : 0
            radius: parent.radius
            
            SequentialAnimation on opacity {
                running: control.hovered
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 1000 }
                NumberAnimation { to: 0.1; duration: 1000 }
            }
        }
    }
    
    contentItem: Text {
        text: control.text
        font {
            family: "Arial"
            pixelSize: Theme.Theme.normalSize
            bold: true
            capitalization: Font.AllUppercase
        }
        color: {
            if (!control.enabled) return "#4A4A4A"
            if (control.pressed) return "#88BBDD"
            if (control.hovered) return "#BDE0FF"
            return "#77A7D1"
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // Улучшенная анимация нажатия
    states: [
        State {
            name: "pressed"
            when: control.pressed
            PropertyChanges {
                target: control
                scale: 0.97
            }
        }
    ]
    
    transitions: Transition {
        NumberAnimation {
            properties: "scale"
            duration: 50
            easing.type: Easing.OutQuad
        }
    }
    
    ToolTip {
        text: parent.tooltip || ""
        visible: parent.hovered && text
        delay: 500
    }
    
    property string tooltip: ""
} 