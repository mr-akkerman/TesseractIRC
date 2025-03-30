import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: ListView.view ? ListView.view.width : 0
    height: contentItem.height + 16  // Add padding
    
    // Properties from model
    property string sender: model.sender || ""
    property string content: model.content || ""
    property string formattedTime: model.formattedTime || ""
    property bool isSystem: model.isSystem || false
    property bool isOwnMessage: model.isOwnMessage || false
    
    // Dimensions for message bubble
    property int maxBubbleWidth: width * 0.75
    property int bubblePadding: 10
    
    // Colors (modernized)
    readonly property color colorOwnBubble: "#3a75b0"      // Own message bubble (more saturated blue)
    readonly property color colorOtherBubble: "#222e3c"    // Other message bubble (deeper gray)
    readonly property color colorSystemBubble: "#1d2733"   // System message (darker and more noticeable)
    readonly property color colorTextMain: "#ffffff"       // Main text
    readonly property color colorTextSecondary: "#93a3bc"  // Secondary text
    readonly property color colorSenderName: "#5e9bd6"     // Sender name (brighter for better visibility)
    readonly property color colorSystemText: "#a7b8d0"     // System message text (lighter for better visibility)
    readonly property color colorShadow: "#18000000"       // Shadow color (slightly more visible)
    
    Item {
        id: contentItem
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        height: isSystem ? systemMessage.height : messageBubble.height
        
        // System message (centered on screen)
        Item {
            id: systemMessage
            anchors.horizontalCenter: parent.horizontalCenter
            visible: isSystem
            height: systemContent.height
            width: systemContent.width
            
            // Container with shadow for system message
            Rectangle {
                id: systemContentShadow
                anchors.fill: systemContent
                anchors.rightMargin: -1
                anchors.bottomMargin: -1
                radius: 12
                color: colorShadow
                visible: isSystem
            }
            
            Rectangle {
                id: systemContent
                anchors.centerIn: parent
                height: systemText.contentHeight + 1.8 * root.bubblePadding  // Increase padding
                width: Math.min(systemText.contentWidth + 2.2 * root.bubblePadding, root.maxBubbleWidth)
                radius: 10  // Reduce radius for more modern look
                color: colorSystemBubble
                
                // Add gradient for system message
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(colorSystemBubble, 1.05) }
                    GradientStop { position: 1.0; color: colorSystemBubble }
                }
                
                Text {
                    id: systemText
                    anchors.centerIn: parent
                    width: Math.min(contentWidth, root.maxBubbleWidth - 2 * root.bubblePadding)
                    text: content
                    wrapMode: Text.Wrap
                    font.pixelSize: 13
                    color: colorSystemText
                    font.italic: true
                }
                
                // System message time (visually hidden but kept for sorting)
                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 6
                    anchors.bottomMargin: 4
                    text: formattedTime
                    font.pixelSize: 10
                    color: colorTextSecondary
                    visible: false  // Hide timestamp for system messages
                }
            }
        }
        
        // Regular message (bubble)
        Column {
            id: messageBubble
            anchors.left: isOwnMessage ? undefined : parent.left
            anchors.right: isOwnMessage ? parent.right : undefined
            width: Math.min(bubbleContainer.width + (isOwnMessage ? 0 : senderName.width), root.maxBubbleWidth)
            spacing: 2
            visible: !isSystem
            
            // Show sender only for other messages
            Text {
                id: senderName
                anchors.left: parent.left
                anchors.leftMargin: 2
                text: sender
                font.bold: true
                font.pixelSize: 12
                color: colorSenderName
                visible: !isOwnMessage && !isSystem
            }
            
            // Bubble container with shadow
            Item {
                id: bubbleContainer
                anchors.left: isOwnMessage ? undefined : parent.left
                anchors.right: isOwnMessage ? parent.right : undefined
                width: bubble.width
                height: bubble.height
                
                // Light shadow (just slightly offset rectangle of same size)
                Rectangle {
                    id: bubbleShadow
                    anchors.fill: bubble
                    anchors.rightMargin: -1
                    anchors.bottomMargin: -1
                    radius: 14
                    color: colorShadow
                    visible: !isSystem
                }
                
                // Message bubble
                Rectangle {
                    id: bubble
                    anchors.left: isOwnMessage ? undefined : parent.left
                    anchors.right: isOwnMessage ? parent.right : undefined
                    
                    // Fix cyclic binding by using fixed width calculations
                    width: {
                        // Calculate maximum bubble width
                        var maxWidth = root.maxBubbleWidth;
                        
                        // Use fixed calculations avoiding contentWidth/implicitWidth references
                        // Calculate approximate text width based on character count and average character size
                        var textLen = content.length;
                        var avgCharWidth = 8;  // Average character width in pixels for 14px font
                        var estimatedWidth = Math.min(textLen * avgCharWidth, maxWidth - 2 * root.bubblePadding);
                        
                        // Check if message is too short
                        if (textLen < 20) {
                            // Set minimum width for short messages
                            return Math.max(estimatedWidth, 80) + 2 * root.bubblePadding;
                        } else {
                            // Use estimated width for long messages
                            return estimatedWidth + 2 * root.bubblePadding;
                        }
                    }
                    
                    height: messageText.contentHeight + 2 * root.bubblePadding + timeText.height
                    radius: 14
                    color: isOwnMessage ? colorOwnBubble : colorOtherBubble
                    
                    // Add thin border for better visual effect
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.05) // Very light border
                    
                    // Gradient for bubble
                    gradient: Gradient {
                        GradientStop { 
                            position: 0.0; 
                            color: isOwnMessage ? 
                                   Qt.lighter(colorOwnBubble, 1.05) : 
                                   Qt.lighter(colorOtherBubble, 1.05) 
                        }
                        GradientStop { 
                            position: 1.0; 
                            color: isOwnMessage ? colorOwnBubble : colorOtherBubble 
                        }
                    }
                    
                    // Message content
                    Text {
                        id: messageText
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: root.bubblePadding
                        anchors.bottomMargin: timeText.height + 4
                        text: content
                        wrapMode: Text.Wrap
                        font.pixelSize: 14
                        font.weight: isOwnMessage ? Font.Medium : Font.Normal
                        color: colorTextMain
                    }
                    
                    // Message time
                    Text {
                        id: timeText
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 6
                        anchors.bottomMargin: 4
                        text: formattedTime
                        font.pixelSize: 10
                        color: isOwnMessage ? 
                              Qt.rgba(colorTextSecondary.r, colorTextSecondary.g, colorTextSecondary.b, 0.85) :
                              Qt.rgba(colorTextSecondary.r, colorTextSecondary.g, colorTextSecondary.b, 0.75)
                    }
                }
            }
        }
    }
} 