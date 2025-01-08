import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Dialog {
    id: root
    title: "О программе"
    modal: true
    
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 400
    height: 300
    
    Material.background: Theme.Theme.frameColor
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.Theme.spacing
        
        Image {
            source: "qml/images/logo.png"
            Layout.preferredWidth: 200
            Layout.preferredHeight: 100
            Layout.alignment: Qt.AlignHCenter
            fillMode: Image.PreserveAspectFit
        }
        
        Label {
            text: "World of Warcraft 3.3.5a Launcher"
            font.pixelSize: Theme.Theme.titleSize
            font.bold: true
            color: Theme.Theme.primaryText
            Layout.alignment: Qt.AlignHCenter
        }
        
        Label {
            text: "Версия: " + (launcher ? launcher.version : "3.3.5")
            color: Theme.Theme.secondaryText
            Layout.alignment: Qt.AlignHCenter
        }
        
        Item { Layout.fillHeight: true }
        
        Label {
            text: "© 2024 Your Server Name"
            color: Theme.Theme.secondaryText
            Layout.alignment: Qt.AlignHCenter
        }
    }
    
    footer: DialogButtonBox {
        Button {
            text: "Закрыть"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: root.reject()
        }
    }
} 