import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Dialog {
    id: root
    title: qsTr("Join Channel")
    standardButtons: Dialog.Ok | Dialog.Cancel
    width: Math.min(400, parent.width * 0.8)
    modal: true
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: parent
    
    // Colors (from Telegram dark theme)
    readonly property color colorBackground: "#17212b"        // Main background
    readonly property color colorItemBg: "#242f3d"           // Item background
    readonly property color colorText: "#ffffff"             // Main text
    readonly property color colorSecondaryText: "#93a3bc"    // Secondary text
    readonly property color colorBorder: "#293747"           // Border
    readonly property color colorHighlight: "#2b5278"        // Selection
    readonly property color colorButton: "#5288c1"           // Button
    readonly property color colorInput: "#242f3d"            // Input field
    readonly property color colorInputText: "#ffffff"        // Input text
    readonly property color colorPlaceholder: "#717d89"      // Placeholder text
    
    // Server and channel names
    property string serverName: ""
    property string channelName: channelField.text
    property bool autoJoin: autoJoinCheckbox.checked
    
    // Input validation
    property bool isValidInput: serverName.trim() !== "" && 
                               channelName.trim() !== "" && 
                               (channelName.startsWith("#") || channelName.startsWith("&"))
    
    // Dialog styling
    background: Rectangle {
        color: colorBackground
        border.color: colorBorder
        border.width: 1
        radius: 6
    }
    
    header: Rectangle {
        color: colorItemBg
        height: 40
        
        Label {
            text: root.title
            anchors.centerIn: parent
            color: colorText
            font.bold: true
            font.pixelSize: 14
        }
    }
    
    onAboutToShow: {
        // Reset field and set focus on open
        channelField.text = "#"
        channelField.forceActiveFocus()
        
        // Position cursor after # symbol
        channelField.cursorPosition = 1
        
        // Set default autoJoin value (if possible to get from controller)
        if (appController && serverName && channelField.text) {
            autoJoinCheckbox.checked = appController.get_channel_auto_join(serverName, channelField.text)
        } else {
            autoJoinCheckbox.checked = true // Enabled by default
        }
    }
    
    // Enable/disable OK button
    onIsValidInputChanged: {
        standardButton(Dialog.Ok).enabled = isValidInput
    }
    
    // Configure buttons
    footer: DialogButtonBox {
        standardButtons: root.standardButtons
        alignment: Qt.AlignRight
        spacing: 10
        padding: 16
        
        background: Rectangle {
            color: colorItemBg
        }
        
        delegate: Button {
            id: dialogButton
            
            contentItem: Text {
                text: dialogButton.text
                color: colorText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 30
                color: dialogButton.down ? Qt.darker(root.colorButton, 1.2) :
                       dialogButton.hovered ? Qt.lighter(root.colorButton, 1.1) : root.colorButton
                radius: 4
                opacity: dialogButton.enabled ? 1.0 : 0.5
            }
        }
    }
    
    // Dialog content
    contentItem: ColumnLayout {
        spacing: 16
        
        Label {
            text: qsTr("Enter channel name to join on server:") + "\n" + serverName
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: colorText
        }
        
        // Channel name input field
        TextField {
            id: channelField
            text: "#"
            placeholderText: qsTr("Channel name (starts with # or &)")
            Layout.fillWidth: true
            selectByMouse: true
            
            color: colorInputText
            placeholderTextColor: colorPlaceholder
            selectionColor: colorHighlight
            
            background: Rectangle {
                color: colorInput
                border.color: parent.activeFocus ? colorButton : colorBorder
                border.width: 1
                radius: 4
            }
            
            // Live validation
            onTextChanged: {
                if (text.trim() === "") {
                    text = "#"
                    cursorPosition = 1
                } else if (!text.startsWith("#") && !text.startsWith("&")) {
                    text = "#" + text
                    cursorPosition = text.length
                }
                
                // Update autoJoin value according to channel settings
                if (appController && serverName && text) {
                    autoJoinCheckbox.checked = appController.get_channel_auto_join(serverName, text)
                }
            }
        }
        
        // Auto-join channel option
        CheckBox {
            id: autoJoinCheckbox
            text: qsTr("Automatically join this channel when connecting to server")
            checked: true
            Layout.fillWidth: true
            
            contentItem: Text {
                text: autoJoinCheckbox.text
                leftPadding: autoJoinCheckbox.indicator.width + autoJoinCheckbox.spacing
                verticalAlignment: Text.AlignVCenter
                color: colorText
                wrapMode: Text.WordWrap
            }
            
            indicator: Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                x: autoJoinCheckbox.leftPadding
                y: parent.height / 2 - height / 2
                radius: 3
                color: colorInput
                border.color: autoJoinCheckbox.activeFocus ? colorButton : colorBorder
                
                Rectangle {
                    width: 12
                    height: 12
                    anchors.centerIn: parent
                    radius: 2
                    color: colorButton
                    visible: autoJoinCheckbox.checked
                }
            }
        }
        
        // Channel information
        Label {
            text: qsTr("Regular channels start with # symbol (e.g. #general).\nLocal channels start with & symbol (e.g. &local).")
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: colorSecondaryText
            font.pixelSize: 12
        }
    }
    
    // Center window
    Overlay.modal: Rectangle {
        color: "#aa000000"
    }
    
    // Timer for channel activation after joining
    Timer {
        id: timer
        interval: 1000 // Wait 1 second for join completion
        
        property string savedServer: ""
        property string savedChannel: ""
        
        onTriggered: {
            if (appController) {
                console.log("Timer activation: " + savedServer + "/" + savedChannel);
                appController.activate_channel(savedServer, savedChannel);
            }
        }
    }
    
    onAccepted: {
        if (appController && activeServer) {
            // Save data for timer
            timer.savedServer = activeServer;
            timer.savedChannel = channelName;
            
            appController.join_channel(activeServer, channelName);
            console.log("Join channel request sent: " + channelName);
            
            // Wait a bit and activate channel manually
            timer.start();
        }
    }
} 