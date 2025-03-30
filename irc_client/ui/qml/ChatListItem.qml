import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    height: 70
    
    // Properties from model
    property string name: model.name || ""
    property string server: model.server || ""
    property int unreadCount: model.unreadCount || 0
    property bool isPrivate: model.isPrivate || false
    property string lastMessage: model.lastMessage || ""
    property string lastMessageTime: model.lastMessageTime || ""
    
    // Selection state
    property bool highlighted: false
    
    // Click signal
    signal itemClicked()
    
    // Colors (from Telegram)
    readonly property color colorBackground: "#232e3c"      // Sidebar background
    readonly property color colorHighlighted: "#2b5278"     // Selected item
    readonly property color colorHover: "#293747"           // Hover effect
    readonly property color colorText: "#ffffff"            // Text color
    readonly property color colorSecondaryText: "#93a3bc"   // Secondary text
    readonly property color colorBorder: "#293747"          // Separator
    readonly property color colorServerIcon: "#5288c1"      // Server
    readonly property color colorChannelIcon: "#64a0da"     // Channel
    readonly property color colorPrivateIcon: "#6b93d6"     // Private messages
    readonly property color colorUnreadBadge: "#3ba6f2"     // Unread counter
    
    // Background color
    color: highlighted ? colorHighlighted : 
           mouseArea.containsMouse ? colorHover : colorBackground
    
    // Color change animation
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    // Click handler
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.itemClicked()
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Icon (server or channel)
        Rectangle {
            width: 40
            height: 40
            radius: isPrivate ? 20 : 4
            color: isPrivate ? colorPrivateIcon : 
                   (name === server ? colorServerIcon : colorChannelIcon)
            
            Text {
                anchors.centerIn: parent
                text: name === server ? qsTr("С") : 
                      isPrivate ? name[0].toUpperCase() : "#"
                color: colorText
                font.bold: true
                font.pixelSize: 16
            }
        }
        
        // Chat information
        Column {
            Layout.fillWidth: true
            spacing: 4
            
            // Channel/server name
            Text {
                text: name
                color: colorText
                font.bold: true
                font.pixelSize: 14
                elide: Text.ElideRight
                width: parent.width
            }
            
            // Last message
            Text {
                text: lastMessage || (name === server ? "Сервер" : "Канал")
                color: colorSecondaryText
                font.pixelSize: 12
                elide: Text.ElideRight
                width: parent.width
                visible: true
            }
        }
        
        // Last message time and unread count
        Column {
            spacing: 4
            
            // Last message time
            Text {
                text: lastMessageTime
                font.pixelSize: 12
                color: colorSecondaryText
                visible: lastMessageTime !== ""
                horizontalAlignment: Text.AlignRight
            }
            
            // Unread messages counter
            Rectangle {
                width: unreadCountText.width + 10
                height: 20
                radius: 10
                color: colorUnreadBadge
                visible: unreadCount > 0
                
                Text {
                    id: unreadCountText
                    anchors.centerIn: parent
                    text: unreadCount > 99 ? "99+" : unreadCount.toString()
                    color: colorText
                    font.bold: true
                    font.pixelSize: 10
                }
            }
        }
    }
    
    // Separator line
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: colorBorder
    }
}