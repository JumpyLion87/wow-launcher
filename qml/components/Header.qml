import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.minimumHeight: 70
    color: "transparent"
    
    // Анимированный фон логотипа
    Rectangle {
        id: logoBackground
        anchors.left: parent.left
        width: logo.width
        height: parent.height
        color: "transparent"
        
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00152536" }
                GradientStop { position: 0.5; color: "#20152536" }
                GradientStop { position: 1.0; color: "#00152536" }
            }
            
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 2000; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutQuad }
            }
        }
    }
    
    Image {
        id: logo
        source: "qml/images/logo.png"
        width: parent.height * 1.5
        height: parent.height
        fillMode: Image.PreserveAspectFit
        
        // Эффект свечения для логотипа
        Rectangle {
            anchors.fill: parent
            color: "#3A5570"
            opacity: 0
            
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 2000; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0; duration: 2000; easing.type: Easing.InOutQuad }
            }
        }
    }
    
    // Статистика сервера
    Row {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: Theme.Theme.spacing
        }
        spacing: Theme.Theme.spacing * 2
        
        // Онлайн
        StatsBox {
            label: "ОНЛАЙН"
            value: "1234"
            
            // Анимация при изменении значения
            Behavior on value {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutBack
                }
            }
        }
        
        // Рейты
        StatsBox {
            label: "РЕЙТЫ"
            value: "x2"
        }
    }
    
    // Компонент для отображения статистики
    component StatsBox: Column {
        property string label: ""
        property string value: ""
        spacing: 2
        
        Label {
            text: label
            color: Theme.Theme.secondaryText
            font.pixelSize: Theme.Theme.smallSize
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Label {
            text: value
            color: "#00AAFF"
            font.pixelSize: Theme.Theme.titleSize
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Подсветка при наведении
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.color = "#40AAFF"
                onExited: parent.color = "#00AAFF"
            }
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }
} 