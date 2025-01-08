import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Item {
    id: root
    Layout.fillWidth: true
    Layout.minimumHeight: 40
    visible: value > 0 || text !== ""
    
    property alias value: progressBar.value
    property alias text: speedLabel.text
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.Theme.spacing
        
        ProgressBar {
            id: progressBar
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            from: 0
            to: 1.0
            
            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 14
                color: "#0A0A0A"
                radius: 2
                border.width: 1
                border.color: "#2A4055"
                clip: true
                
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "#152536"
                    visible: progressBar.value > 0 && progressBar.value < 1
                    clip: true
                    
                    Rectangle {
                        id: animatedBackground
                        width: parent.width
                        height: parent.height
                        color: "#1E3346"
                        radius: parent.radius
                        
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: progressBar.value > 0 && progressBar.value < 1
                            NumberAnimation { to: 0.3; duration: 1000 }
                            NumberAnimation { to: 0.1; duration: 1000 }
                        }
                    }
                }
            }
            
            contentItem: Item {
                implicitWidth: 200
                implicitHeight: 14
                clip: true
                
                Rectangle {
                    width: progressBar.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    clip: true
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1E3346" }
                        GradientStop { position: 0.5; color: "#2B4869" }
                        GradientStop { position: 1.0; color: "#1E3346" }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#3A5570"
                        opacity: 0.7
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: parent.height
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#20FFFFFF" }
                            GradientStop { position: 0.5; color: "#40FFFFFF" }
                            GradientStop { position: 1.0; color: "#20FFFFFF" }
                        }
                        
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: progressBar.value > 0 && progressBar.value < 1
                            NumberAnimation { to: 0.1; duration: 1000 }
                            NumberAnimation { to: 0.3; duration: 1000 }
                        }
                    }
                    
                    Behavior on width {
                        NumberAnimation { 
                            duration: 100
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Theme.spacing
            
            Label {
                id: speedLabel
                color: "#77A7D1"
                font.pixelSize: Theme.Theme.smallSize
                font.bold: true
                visible: text !== ""
                
                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: speedLabel; property: "opacity"; to: 0.7; duration: 100 }
                        PropertyAction { target: speedLabel; property: "text" }
                        NumberAnimation { target: speedLabel; property: "opacity"; to: 1.0; duration: 100 }
                    }
                }
            }
            
            Label {
                Layout.fillWidth: true
                text: Math.round(progressBar.value * 100) + "%"
                color: "#77A7D1"
                font.pixelSize: Theme.Theme.smallSize
                font.bold: true
                horizontalAlignment: Text.AlignRight
                visible: progressBar.value > 0
                
                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: parent; property: "opacity"; to: 0.7; duration: 100 }
                        PropertyAction { target: parent; property: "text" }
                        NumberAnimation { target: parent; property: "opacity"; to: 1.0; duration: 100 }
                    }
                }
            }
        }
    }
} 