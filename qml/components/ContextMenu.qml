import QtQuick 2.15
import QtQuick.Controls 2.15
import "../Theme" as Theme

Menu {
    id: contextMenu
    
    MenuItem {
        text: "Открыть папку с игрой"
        enabled: launcher && launcher.gamePath
        onTriggered: launcher.openGameFolder()
    }
    
    MenuItem {
        text: "Проверить файлы"
        enabled: launcher && launcher.gamePath && !launcher.isDownloading
        onTriggered: launcher.verifyFiles()
    }
    
    MenuItem {
        text: "Восстановить клиент"
        enabled: launcher && launcher.gamePath && !launcher.isDownloading
        onTriggered: launcher.repairClient()
    }
    
    MenuSeparator { }
    
    MenuItem {
        text: "Настройки"
        onTriggered: settingsDialog.open()
    }
    
    MenuItem {
        text: "О программе"
        onTriggered: aboutDialog.open()
    }
} 