import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: root
    title: qsTr("Error")
    standardButtons: Dialog.Ok
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
    readonly property color colorButton: "#5288c1"           // Button
    readonly property color colorError: "#e26373"            // Error color
    
    // Error message
    property string message: qsTr("An unknown error occurred")
    
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
        
        // Error icon
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 48
            height: 48
            radius: 24
            color: colorError
            
            Text {
                anchors.centerIn: parent
                text: "!"
                font.bold: true
                font.pixelSize: 24
                color: colorText
            }
        }
        
        // Error text
        Label {
            text: root.message
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 14
            color: colorText
        }
    }
    
    // Center window
    Overlay.modal: Rectangle {
        color: "#aa000000"
    }
}