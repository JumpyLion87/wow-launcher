import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Pane {
    id: root
    Layout.fillWidth: true
    padding: Theme.Theme.margin
    
    Material.elevation: 6
    Material.background: Qt.darker(Theme.Theme.frameColor, 1.1)
    
    property alias serverInfo: serverLabel.text
    property alias requirements: reqLabel.text
    
    background: Rectangle {
        color: Qt.darker(Theme.Theme.frameColor, 1.1)
        radius: Theme.Theme.radius / 2
        border.color: Qt.darker(Theme.Theme.borderColor, 1.2)
        border.width: 1
        
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#20FFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }
    }
    
    ColumnLayout {
        width: parent.width
        spacing: Theme.Theme.spacing * 1.5
        
        // Секция сервера
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Theme.spacing
            
            Image {
                source: "qml/images/icons/server.png"
                sourceSize: Qt.size(24, 24)
                Layout.alignment: Qt.AlignTop
                opacity: 0.8
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.Theme.spacing / 2
                
                Label {
                    text: "ИНФОРМАЦИЯ О СЕРВЕРЕ"
                    color: Theme.Theme.secondaryText
                    font.pixelSize: Theme.Theme.smallSize
                    font.bold: true
                }
                
                Label {
                    id: serverLabel
                    Layout.fillWidth: true
                    color: "#77A7D1"
                    font.pixelSize: Theme.Theme.normalSize
                    font.bold: true
                    
                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation { target: serverLabel; property: "opacity"; to: 0; duration: 100 }
                            PropertyAction { target: serverLabel; property: "text" }
                            NumberAnimation { target: serverLabel; property: "opacity"; to: 1; duration: 100 }
                        }
                    }
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.darker(Theme.Theme.borderColor, 1.2)
            opacity: 0.5
        }
        
        // Секция системных требований
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Theme.spacing
            
            Image {
                source: "qml/images/icons/requirements.png"
                sourceSize: Qt.size(24, 24)
                Layout.alignment: Qt.AlignTop
                opacity: 0.8
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.Theme.spacing / 2
                
                Label {
                    text: "СИСТЕМНЫЕ ТРЕБОВАНИЯ"
                    color: Theme.Theme.secondaryText
                    font.pixelSize: Theme.Theme.smallSize
                    font.bold: true
                }
                
                Label {
                    id: reqLabel
                    Layout.fillWidth: true
                    color: Theme.Theme.secondaryText
                    font.pixelSize: Theme.Theme.smallSize
                    wrapMode: Text.WordWrap
                    
                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation { target: reqLabel; property: "opacity"; to: 0; duration: 100 }
                            PropertyAction { target: reqLabel; property: "text" }
                            NumberAnimation { target: reqLabel; property: "opacity"; to: 1; duration: 100 }
                        }
                    }
                }
            }
        }
    }
} 