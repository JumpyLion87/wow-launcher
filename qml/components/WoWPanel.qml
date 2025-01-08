import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../Theme" as Theme

Rectangle {
    color: Theme.Theme.frameColor
    radius: Theme.Theme.radius
    border.color: Theme.Theme.borderColor
    border.width: 2
    
    default property alias content: container.children
    
    ColumnLayout {
        id: container
        anchors.fill: parent
        anchors.margins: Theme.Theme.margin * 2
        spacing: Theme.Theme.spacing
    }
} 