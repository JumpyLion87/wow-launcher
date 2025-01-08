import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "./qml/Theme" as Theme
import "./qml/components" as Components

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1010
    height: 650
    minimumWidth: 1010
    minimumHeight: 650
    maximumWidth: 1010
    maximumHeight: 650
    title: "World of Warcraft 3.3.5a Launcher"

    // Добавляем фоновое изображение
    background: Rectangle {
        color: Theme.Theme.backgroundColor

        Image {
            anchors.fill: parent
            source: "qml/images/background.jpg" // Путь к изображению
            fillMode: Image.PreserveAspectCrop
            opacity: 0.3

            // Добавляем затемнение
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.6
            }
        }
    }
    
    Material.theme: Material.Dark
    Material.accent: Theme.Theme.accentColor
    Material.background: Theme.Theme.backgroundColor
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Основной контент
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Theme.Theme.margin
            spacing: Theme.Theme.spacing
            
            // Левая панель
            Components.Section {
                Layout.preferredWidth: 300
                Layout.minimumWidth: 300
                Layout.fillHeight: true
                
                // Заголовок
                Components.Header {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 70
                }
                
                // Информационная панель
                Components.InfoPanel {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 150
                    serverInfo: "x2 WotLK"
                    requirements: "• OS: Windows 7/8/10/11\n• CPU: 2.4 GHz\n• RAM: 2 GB\n• HDD: 15 GB"
                }
                
                // Растягивающийся элемент
                Item { 
                    Layout.fillHeight: true 
                }
                
                // Статус текст
                Label {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 50
                    text: launcher ? launcher.statusText : "Пожалуйста, выберите папку с игрой"
                    color: Theme.Theme.primaryText
                    font.pixelSize: Theme.Theme.normalSize
                    wrapMode: Text.WordWrap
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.darker(Theme.Theme.borderColor, 1.2)
                    Layout.margins: Theme.Theme.spacing
                }
                
                // Кнопки
                Components.WoWButton {
                    Layout.fillWidth: true
                    Layout.minimumHeight: Theme.Theme.buttonHeight
                    text: "Выбрать папку с игрой"
                    visible: launcher ? !launcher.gamePath : true
                    onClicked: launcher && launcher.selectGamePath()
                    tooltip: "Выберите папку, где будет установлена игра"
                }
                
                Components.WoWButton {
                    Layout.fillWidth: true
                    Layout.minimumHeight: Theme.Theme.buttonHeight
                    text: launcher && launcher.isDownloading ? "Остановить загрузку" : "Скачать клиент"
                    onClicked: launcher && launcher.startDownload()
                    tooltip: launcher && launcher.isDownloading ? 
                        "Остановить текущую загрузку" : 
                        "Загрузить клиент World of Warcraft"
                }
                
                // Добавляем отступ после кнопок
                Item {
                    Layout.fillWidth: true
                    Layout.minimumHeight: Theme.Theme.spacing * 2  // Отступ снизу
                }
            }
            
            // Правая панель
            Components.Section {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 400
                
                // Слайд-шоу
                Components.SlideShow {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 300
                    imageUrls: [
                        "qml/images/slide1.jpg",
                        "qml/images/slide2.jpg",
                        "qml/images/slide3.jpg",
                        "qml/images/slide4.jpg"
                    ]
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.darker(Theme.Theme.borderColor, 1.2)
                    Layout.margins: Theme.Theme.spacing
                }
                
                // Нижняя часть с прогрессом и кнопкой
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Theme.Theme.spacing
                    spacing: Theme.Theme.spacing
                    
                    // Прогресс-бар и имя файла
                    ColumnLayout {
                        Layout.fillWidth: true                        
                        spacing: Theme.Theme.spacing / 2
                        
                        Label {
                            Layout.fillWidth: true
                            text: launcher ? launcher.currentFileName : ""
                            color: Theme.Theme.primaryText
                            font.pixelSize: Theme.Theme.smallSize
                            visible: text !== ""
                        }
                        
                        Components.ProgressSection {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 40
                            Layout.leftMargin: 1
                            Layout.rightMargin: 1
                            Layout.topMargin: 1
                            Layout.bottomMargin: 1
                            value: launcher ? launcher.downloadProgress : 0
                            text: {
                                if (launcher) {
                                    if (launcher.downloadSpeed && launcher.downloadSizeInfo) {
                                        return launcher.downloadSpeed + " / " + launcher.downloadSizeInfo
                                    }
                                    return launcher.downloadSpeed
                                }
                                return ""                            
                            }
                        }
                    }
                    
                    // Кнопка запуска
                    Components.WoWButton {
                        Layout.alignment: Qt.AlignBottom
                        Layout.minimumWidth: 120
                        Layout.minimumHeight: Theme.Theme.buttonHeight
                        text: "ИГРАТЬ"
                        enabled: launcher ? launcher.canPlay : false
                        onClicked: launcher && launcher.launchGame()
                        tooltip: enabled ? 
                            "Запустить World of Warcraft" : 
                            "Сначала установите игру"
                    }
                }
            }
        }
        
        // Статус бар
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 30
            height: 30
            color: Qt.rgba(Theme.Theme.frameColor.r, Theme.Theme.frameColor.g, Theme.Theme.frameColor.b, 0.35)
            border.color: Qt.rgba(Theme.Theme.borderColor.r, Theme.Theme.borderColor.g, Theme.Theme.borderColor.b, 0.4)
            
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Theme.Theme.margin
                    rightMargin: Theme.Theme.margin
                    topMargin: Theme.Theme.margin / 2
                    bottomMargin: Theme.Theme.margin / 2
                }
                spacing: Theme.Theme.spacing
                
                // Статус сервера
                Label {
                    Layout.minimumWidth: 100
                    text: launcher ? launcher.serverStatus : "⚫ Offline"
                    color: launcher && launcher.isServerOnline ? Theme.Theme.primaryText : Theme.Theme.disabledText
                    font.bold: true
                    
                    ToolTip.visible: serverMouseArea.containsMouse
                    ToolTip.text: launcher && launcher.isServerOnline ? 
                        "Сервер доступен" : 
                        "Сервер недоступен"
                    
                    MouseArea {
                        id: serverMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
                
                // Растягивающийся элемент
                Item { Layout.fillWidth: true }
                
                // Версия
                Label {
                    Layout.minimumWidth: 80
                    text: "Версия: " + (launcher ? launcher.version : "3.3.5")
                    color: Theme.Theme.secondaryText
                }
                
                // Кнопка настроек
                ToolButton {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    icon.source: "qml/components/qml/images/icons/settings.png"
                    icon.color: Theme.Theme.secondaryText
                    icon.width: 16
                    icon.height: 16
                    ToolTip.visible: hovered
                    ToolTip.text: "Настройки"
                    onClicked: settingsDialog.open()
                }
            }
        }
    }
    
    Components.Notification {
        id: notification
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.Theme.margin * 2
        }
        z: 999
    }
    
    // Функция для показа уведомлений
    function showNotification(message, type) {
        notification.type = type || "info"
        notification.text = message
        notification.show()
    }
    
    Components.SettingsDialog {
        id: settingsDialog
    }
    
    Components.AboutDialog {
        id: aboutDialog
    }
    
    Components.ContextMenu {
        id: contextMenu
    }
    
    // Добавить MouseArea для всего окна
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: {
            if (mouse.button === Qt.RightButton)
                contextMenu.popup()
        }
    }

    // Добавляем обработку закрытия окна
    onClosing: function(close) {
        if (launcher.settings.closeToTray) {
            close.accepted = false
            launcher.minimizeToTray()
        }
    }
} 