import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Dialog {
    id: root
    title: "Настройки"
    modal: true
    
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 400
    height: 500
    
    Material.background: Theme.Theme.frameColor
    
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        
        ColumnLayout {
            width: scrollView.availableWidth
            spacing: Theme.Theme.spacing
            
            // Игровые настройки
            GroupBox {
                Layout.fillWidth: true
                title: "Игровые настройки"
                
                ColumnLayout {
                    anchors.fill: parent
                    
                    // Путь к игре
                    Label {
                        text: "Путь к игре:"
                        color: Theme.Theme.secondaryText
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.Theme.spacing
                        
                        TextField {
                            id: gamePathField
                            Layout.fillWidth: true
                            text: launcher ? launcher.gamePath : ""
                            readOnly: true
                            color: Theme.Theme.primaryText
                            
                            background: Rectangle {
                                color: Qt.darker(Theme.Theme.frameColor, 1.2)
                                border.color: Theme.Theme.borderColor
                                radius: 3
                            }
                        }
                        
                        Button {
                            text: "Обзор"
                            onClicked: launcher && launcher.selectGamePath()
                        }
                    }
                    
                    CheckBox {
                        text: "Автозапуск при старте Windows"
                        checked: launcher && launcher.settings ? launcher.settings.autostart : false
                        onCheckedChanged: if (launcher && launcher.settings) launcher.settings.autostart = checked
                    }
                    
                    CheckBox {
                        text: "Закрывать лаунчер при запуске игры"
                        checked: launcher && launcher.settings ? launcher.settings.closeOnLaunch : false
                        onCheckedChanged: if (launcher && launcher.settings) launcher.settings.closeOnLaunch = checked
                    }
                    
                    // Выбор эмулятора для Linux
                    RowLayout {
                        Layout.fillWidth: true
                        visible: Qt.platform.os !== "windows"  // Показываем только на Linux/Mac
                        
                        Label {
                            text: "Эмулятор Windows:"
                            color: Theme.Theme.secondaryText
                        }
                        
                        ComboBox {
                            Layout.fillWidth: true
                            model: ["Wine", "Lutris", "Proton", "PortProton", "CrossOver"]
                            currentIndex: {
                                if (launcher && launcher.settings) {
                                    switch(launcher.settings.linuxEmulator) {
                                        case "wine": return 0;
                                        case "lutris": return 1;
                                        case "proton": return 2;
                                        case "portproton": return 3;
                                        case "crossover": return 4;
                                        default: return 0;
                                    }
                                }
                                return 0;
                            }
                            onCurrentIndexChanged: {
                                if (launcher && launcher.settings) {
                                    switch(currentIndex) {
                                        case 0: launcher.settings.linuxEmulator = "wine"; break;
                                        case 1: launcher.settings.linuxEmulator = "lutris"; break;
                                        case 2: launcher.settings.linuxEmulator = "proton"; break;
                                        case 3: launcher.settings.linuxEmulator = "portproton"; break;
                                        case 4: launcher.settings.linuxEmulator = "crossover"; break;
                                    }
                                }
                            }
                        }
                        
                        // Кнопка проверки эмулятора
                        Button {
                            text: "Проверить"
                            onClicked: if (launcher) launcher.checkEmulator()
                        }
                    }
                }
            }
            
            // Настройки загрузки
            GroupBox {
                Layout.fillWidth: true
                title: "Настройки загрузки"
                
                ColumnLayout {
                    anchors.fill: parent
                    
                    Label {
                        text: "Ограничение скорости загрузки:"
                    }
                    
                    ComboBox {
                        Layout.fillWidth: true
                        model: ["Без ограничений", "1 Мбит/с", "2 Мбит/с", "5 Мбит/с", "10 Мбит/с"]
                        currentIndex: launcher && launcher.settings ? launcher.settings.speedLimit : 0
                        onCurrentIndexChanged: if (launcher && launcher.settings) launcher.settings.speedLimit = currentIndex
                    }
                    
                    CheckBox {
                        text: "Автоматически загружать обновления"
                        checked: launcher && launcher.settings ? launcher.settings.autoUpdate : true
                        onCheckedChanged: if (launcher && launcher.settings) launcher.settings.autoUpdate = checked
                    }
                }
            }
            
            // Настройки интерфейса
            GroupBox {
                Layout.fillWidth: true
                title: "Настройки интерфейса"
                
                ColumnLayout {
                    anchors.fill: parent
                    
                    Label {
                        text: "Интервал слайд-шоу (сек):"
                    }
                    
                    SpinBox {
                        Layout.fillWidth: true
                        from: 3
                        to: 15
                        value: launcher && launcher.settings ? launcher.settings.slideInterval : 5
                        onValueChanged: if (launcher && launcher.settings) launcher.settings.slideInterval = value
                    }
                    
                    CheckBox {
                        text: "Показывать уведомления"
                        checked: launcher && launcher.settings ? launcher.settings.showNotifications : true
                        onCheckedChanged: if (launcher && launcher.settings) launcher.settings.showNotifications = checked
                    }
                }
            }
            
            Item { 
                Layout.fillWidth: true
                Layout.minimumHeight: Theme.Theme.spacing * 2
            }
        }
    }
    
    footer: DialogButtonBox {
        Button {
            text: "Применить"
            DialogButtonBox.buttonRole: DialogButtonBox.ApplyRole
            onClicked: {
                if (launcher) launcher.saveSettings()
                root.accept()
            }
        }
        Button {
            text: "Отмена"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: root.reject()
        }
    }
} 