import QtQuick 2.15
import QtQuick.Controls 2.15
import "../Theme" as Theme

Rectangle {
    id: root
    width: message.width + Theme.Theme.spacing * 4
    height: message.height + Theme.Theme.spacing * 2
    radius: Theme.Theme.radius
    opacity: 0
    
    property string text: ""
    property string type: "info" // info, error, success
    
    color: {
        switch(type) {
            case "error": return "#4D2C2C"
            case "success": return "#2C4D2C"
            default: return Theme.Theme.frameColor
        }
    }
    
    border.color: {
        switch(type) {
            case "error": return "#FF4444"
            case "success": return "#44FF44"
            default: return Theme.Theme.borderColor
        }
    }
    border.width: 1
    
    Label {
        id: message
        anchors.centerIn: parent
        text: root.text
        color: Theme.Theme.primaryText
        font.pixelSize: Theme.Theme.smallSize
    }
    
    // Анимации
    NumberAnimation {
        id: showAnim
        target: root
        property: "opacity"
        to: 1
        duration: 200
    }
    
    NumberAnimation {
        id: hideAnim
        target: root
        property: "opacity"
        to: 0
        duration: 200
    }
    
    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: hideAnim.start()
    }
    
    function show() {
        showAnim.start()
        hideTimer.restart()
    }
} 