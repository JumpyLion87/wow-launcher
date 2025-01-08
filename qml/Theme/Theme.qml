pragma Singleton
import QtQuick 2.15

QtObject {
    // Цвета
    readonly property color backgroundColor: "#0A0A0A"
    readonly property color frameColor: "#1A1A1A"
    readonly property color borderColor: "#393939"
    readonly property color primaryText: "#FFB100"
    readonly property color secondaryText: "#CD8500"
    readonly property color disabledText: "#4A4A4A"
    readonly property color accentColor: "#4B0082"
    
    // Размеры
    readonly property int margin: 10
    readonly property int spacing: 15
    readonly property int radius: 8
    readonly property int buttonHeight: 45
    
    // Шрифты
    readonly property int titleSize: 24
    readonly property int subtitleSize: 16
    readonly property int normalSize: 14
    readonly property int smallSize: 12
    
    // Градиенты
    readonly property var buttonGradient: Gradient {
        GradientStop { position: 0.0; color: "#1B3859" }
        GradientStop { position: 1.0; color: "#0A1B2A" }
    }
    
    readonly property var buttonHoverGradient: Gradient {
        GradientStop { position: 0.0; color: "#2B4869" }
        GradientStop { position: 1.0; color: "#1A2B3A" }
    }
    
    readonly property var buttonPressedGradient: Gradient {
        GradientStop { position: 0.0; color: "#0A1B2A" }
        GradientStop { position: 1.0; color: "#1B3859" }
    }
} 