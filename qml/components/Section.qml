import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Pane {
    id: root
    padding: Theme.Theme.margin
    
    Material.elevation: 6
    Material.background: Theme.Theme.frameColor
    
    // Анимация появления
    opacity: 0
    Component.onCompleted: appearAnimation.start()
    
    NumberAnimation {
        id: appearAnimation
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: 500
        easing.type: Easing.OutCubic
    }
    
    background: Rectangle {
        color: Qt.rgba(Theme.Theme.frameColor.r, Theme.Theme.frameColor.g, Theme.Theme.frameColor.b, 0.35)
        radius: Theme.Theme.radius
        
        // Граница с тенью
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Qt.rgba(Theme.Theme.borderColor.r, Theme.Theme.borderColor.g, Theme.Theme.borderColor.b, 0.4)
            border.width: 1
            
            // Нижняя тень
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: "#000000"
                opacity: 0.1
            }
            
            // Верхний блик
            Rectangle {
                width: parent.width
                height: 1
                color: "#FFFFFF"
                opacity: 0.1
            }
        }
        
        // Внутренний градиент
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.1) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
    }
    
    // Контент
    contentItem: ColumnLayout {
        spacing: Theme.Theme.spacing
    }
} 