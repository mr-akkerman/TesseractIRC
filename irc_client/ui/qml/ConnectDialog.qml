import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Dialog {
    id: root
    title: qsTr("Connect to IRC Server") 
    standardButtons: Dialog.Ok | Dialog.Cancel
    width: Math.min(500, parent.width * 0.9)
    height: Math.min(400, parent.height * 0.8)
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
    
    // Variables to store input data
    property string serverAddress: serverField.text
    property int port: parseInt(portField.text) || 6667
    property string nickname: nicknameField.text
    property string username: usernameField.text || nicknameField.text
    property string realname: realnameField.text || nicknameField.text
    
    // Input validation
    property bool isValidInput: serverAddress.trim() !== "" && nickname.trim() !== ""
    
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
        // Set focus to first field when opening
        serverField.forceActiveFocus()
        
        // Load saved nickname if available
        if (appController) {
            nicknameField.text = appController.nickname
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
            text: qsTr("Enter IRC server connection details:")
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: colorText
        }
        
        // Input fields
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            columnSpacing: 10
            rowSpacing: 10
            
            // Server
            Label {
                text: qsTr("Server:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                color: colorText
            }
            
            TextField {
                id: serverField
                text: "irc.libera.chat"
                placeholderText: qsTr("IRC server address")
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
            }
            
            // Port
            Label {
                text: qsTr("Port:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                color: colorText
            }
            
            TextField {
                id: portField
                text: "6667"
                placeholderText: qsTr("Port (usually 6667)")
                Layout.fillWidth: true
                selectByMouse: true
                validator: IntValidator { bottom: 1; top: 65535 }
                
                color: colorInputText
                placeholderTextColor: colorPlaceholder
                selectionColor: colorHighlight
                
                background: Rectangle {
                    color: colorInput
                    border.color: parent.activeFocus ? colorButton : colorBorder
                    border.width: 1
                    radius: 4
                }
            }
            
            // Nickname
            Label {
                text: qsTr("Nickname:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                color: colorText
            }
            
            TextField {
                id: nicknameField
                text: "PySideUser"
                placeholderText: qsTr("Your nickname")
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
            }
            
            // Username
            Label {
                text: qsTr("Username:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                color: colorText
            }
            
            TextField {
                id: usernameField
                placeholderText: qsTr("Username (if different)")
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
            }
            
            // Real name
            Label {
                text: qsTr("Real name:")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                color: colorText
            }
            
            TextField {
                id: realnameField
                placeholderText: qsTr("Your real name or description")
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
            }
        }
        
        // Connection information
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: infoText.contentHeight + 20
            color: colorItemBg
            radius: 4
            
            Text {
                id: infoText
                anchors.fill: parent
                anchors.margins: 10
                text: qsTr("Popular IRC networks: irc.libera.chat, irc.oftc.net, irc.rizon.net, irc.undernet.org")
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                color: colorSecondaryText
            }
        }
    }
    
    // Center window
    Overlay.modal: Rectangle {
        color: "#aa000000"
    }
}