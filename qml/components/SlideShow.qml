import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 300
    
    property var imageUrls: []
    property int interval: 5000
    
    // Добавляем второе изображение для плавного перехода
    Image {
        id: fadeOutImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        opacity: 0
    }
    
    Image {
        id: mainImage
        anchors.fill: parent
        source: imageUrls.length > 0 ? imageUrls[currentIndex] : ""
        fillMode: Image.PreserveAspectFit
        
        property int currentIndex: 0
        
        Timer {
            interval: root.interval
            running: imageUrls.length > 1
            repeat: true
            onTriggered: nextSlide()
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 800; easing.type: Easing.InOutQuad }
        }
    }
    
    // Кнопки навигации
    Rectangle {
        id: prevButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 40
        color: "transparent"
        opacity: prevMouse.containsMouse ? 1 : 0.3
        visible: imageUrls.length > 1
        
        Text {
            anchors.centerIn: parent
            text: "❮"
            color: "#FFFFFF"
            font.pixelSize: 24
        }
        
        MouseArea {
            id: prevMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: prevSlide()
        }
    }
    
    Rectangle {
        id: nextButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 40
        color: "transparent"
        opacity: nextMouse.containsMouse ? 1 : 0.3
        visible: imageUrls.length > 1
        
        Text {
            anchors.centerIn: parent
            text: "❯"
            color: "#FFFFFF"
            font.pixelSize: 24
        }
        
        MouseArea {
            id: nextMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: nextSlide()
        }
    }
    
    // Индикаторы в стиле WoW
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 10
        spacing: 8
        
        Repeater {
            model: imageUrls.length
            
            Rectangle {
                width: 30
                height: 4
                radius: 2
                color: mainImage.currentIndex === index ? "#00AAFF" : "#80FFFFFF"
                opacity: mainImage.currentIndex === index ? 1.0 : 0.5
                
                Rectangle {
                    visible: mainImage.currentIndex === index
                    anchors.fill: parent
                    color: "#40FFFFFF"
                    radius: parent.radius
                    
                    SequentialAnimation on opacity {
                        running: mainImage.currentIndex === index
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 1000 }
                        NumberAnimation { to: 1.0; duration: 1000 }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: showSlide(index)
                }
            }
        }
    }
    
    function nextSlide() {
        fadeOutImage.source = mainImage.source
        fadeOutImage.opacity = 1
        mainImage.currentIndex = (mainImage.currentIndex + 1) % imageUrls.length
        fadeOutImage.opacity = 0
    }
    
    function prevSlide() {
        fadeOutImage.source = mainImage.source
        fadeOutImage.opacity = 1
        mainImage.currentIndex = mainImage.currentIndex === 0 ? imageUrls.length - 1 : mainImage.currentIndex - 1
        fadeOutImage.opacity = 0
    }
    
    function showSlide(index) {
        if (index !== mainImage.currentIndex) {
            fadeOutImage.source = mainImage.source
            fadeOutImage.opacity = 1
            mainImage.currentIndex = index
            fadeOutImage.opacity = 0
        }
    }
} 