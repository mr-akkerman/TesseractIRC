import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQml 2.15
import "."

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1024
    height: 768
    title: qsTr("TesseractIRC")
    color: "#17212b"  // Dark background
    
    // Minimum window size
    minimumWidth: 800
    minimumHeight: 500
    
    // Link to application controller - REMOVING NULL INITIALIZATION
    // property var appController: null
    property string activeServer: ""
    property string activeChannel: ""
    
    // New connection state
    property bool isConnecting: false
    
    // Define theme colors
    readonly property color colorBackground: "#17212b"        // Main background
    readonly property color colorSecondaryBg: "#232e3c"       // Secondary background (sidebar)
    readonly property color colorHeaderBg: "#242f3d"          // Header background
    readonly property color colorPrimary: "#5288c1"           // Primary accent color
    readonly property color colorPrimaryActive: "#64a0da"     // Active accent color
    readonly property color colorText: "#ffffff"              // Main text color
    readonly property color colorSecondaryText: "#93a3bc"     // Secondary text color
    readonly property color colorBorder: "#293747"            // Border color
    readonly property color colorHighlight: "#2b5278"         // Highlight color
    readonly property color colorInputBg: "#242f3d"           // Input field background
    readonly property color colorPanelBg: "#1c2936"           // Panel background
    
    // Global property to protect against too frequent updates
    property bool chatUpdatingNow: false
    property var chatLastUpdateTime: 0
    
    // Global timer to reset update flag
    Timer {
        id: resetChatUpdateFlagTimer
        interval: 300  // Reducing delay for faster UI updates
        repeat: false
        onTriggered: mainWindow.chatUpdatingNow = false
    }
    
    // Helper function for channel activation
    function activateChannelManually(server, channel) {
        console.log("Manual channel activation: " + channel + " on server " + server);
        
        if (appController) {
            var result = appController.activate_channel(server, channel);
            console.log("Activation result: " + result);
            
            // Explicitly update interface
            activeServer = server;
            activeChannel = channel;
        }
    }
    
    // Error handling
    Connections {
        target: appController
        enabled: appController !== null && appController !== undefined
        
        function onErrorOccurred(message) {
            errorDialog.message = message
            errorDialog.open()
        }
        
        function onConnectionStatusChanged(server, status) {
            if (isConnecting && status) {
                isConnecting = false
                connectDialog.close()
            }
        }
        
        // Handle channel join event
        function onChannelJoined(server, channel) {
            console.log("channelJoined signal: server=" + server + ", channel=" + channel);
            
            // Don't set active channel and server here, it's already done in AppController
            // and passed through activeChannelChanged signal from chat list model
            
            // But update UI display if needed
            if (activeServer !== server || activeChannel !== channel) {
                console.log("Updating UI after joining channel");
                activeServer = server;
                activeChannel = channel;
            }
        }
        
        // Handle messages update signal
        function onMessagesUpdated(server, channel) {
            console.log("Received message update for " + channel + " on server " + server);
            
            // Protection against too frequent UI updates
            var currentTime = new Date().getTime();
            if (!refreshTimer.lastUpdateTime["update_" + server + "/" + channel]) {
                refreshTimer.lastUpdateTime["update_" + server + "/" + channel] = 0;
            }
            
            // Minimum interval between visual updates - 1 second
            if (currentTime - refreshTimer.lastUpdateTime["update_" + server + "/" + channel] < 1000) {
                console.log("Skipping UI update - too frequent updates");
                return;
            }
            
            // Remember last UI update time
            refreshTimer.lastUpdateTime["update_" + server + "/" + channel] = currentTime;
            
            // Update message model if this is active chat
            if (activeServer === server && activeChannel === channel) {
                // Only request data update, then scroll down
                if (messageListView.model) {
                    // Use timer with zero delay to update after
                    // ListView size recalculation
                    Qt.callLater(function() {
                        messageListView.positionViewAtEnd();
                    });
                }
            }
        }
    }
    
    // Subscribe to chat model events
    Connections {
        target: appController ? appController.chatListModel : null
        enabled: appController !== null && appController !== undefined

        // Handle active chat change signal
        function onActiveChannelChanged(server, channel) {
            console.log("activeChannelChanged signal: server=" + server + ", channel=" + channel)
            activeServer = server
            activeChannel = channel
        }
    }
    
    // Server connection dialog
    ConnectDialog {
        id: connectDialog
        
        onAccepted: {
            if (appController) {
                mainWindow.isConnecting = true
                appController.connect_to_server(serverAddress, port, nickname, username, realname)
            } else {
                console.error("appController is null")
            }
        }
    }
    
    // Channel join dialog
    JoinDialog {
        id: joinDialog
        
        onAccepted: {
            if (appController && activeServer) {
                appController.join_channel(activeServer, channelName)
                
                // Save auto-join setting
                appController.save_channel_settings(activeServer, channelName, autoJoin)
            }
        }
    }
    
    // Error dialog
    ErrorDialog {
        id: errorDialog
    }
    
    // Main interface structure
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Top panel with header
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: colorHeaderBg
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                
                Label {
                    text: activeChannel ? 
                          (activeServer + " / " + activeChannel) : 
                          (activeServer ? activeServer : "TesseractIRC")
                    font.bold: true
                    font.pixelSize: 16
                    color: colorText
                }
                
                // Debug status of active chat
                Label {
                    text: "Active chat: " + 
                          (activeServer ? activeServer : "none") + 
                          (activeChannel ? "/" + activeChannel : "")
                    font.pixelSize: 12
                    color: colorSecondaryText
                    visible: true  // Set to true for debugging, can be hidden in production
                }
                
                Item { Layout.fillWidth: true }
                
                ToolButton {
                    text: qsTr("Connect")
                    icon.name: "connect"
                    icon.color: colorText
                    display: AbstractButton.TextBesideIcon
                    onClicked: connectDialog.open()
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: colorText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: parent.down ? Qt.darker(colorHighlight, 1.2) : 
                               parent.hovered ? colorHighlight : "transparent"
                        radius: 4
                    }
                }
                
                ToolButton {
                    enabled: activeServer !== ""
                    text: qsTr("Join")
                    icon.name: "join"
                    icon.color: colorText
                    display: AbstractButton.TextBesideIcon
                    onClicked: {
                        joinDialog.serverName = activeServer
                        joinDialog.open()
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: parent.enabled ? colorText : Qt.rgba(colorText.r, colorText.g, colorText.b, 0.5)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: !parent.enabled ? "transparent" :
                               parent.down ? Qt.darker(colorHighlight, 1.2) : 
                               parent.hovered ? colorHighlight : "transparent"
                        radius: 4
                    }
                }
            }
        }
        
        // Main content - sidebar and chat
        SplitView {
            id: splitView
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal
            
            // Chat sidebar
            Rectangle {
                id: sidebarContainer
                SplitView.preferredWidth: 250
                SplitView.minimumWidth: 200
                color: colorSecondaryBg
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    // Sidebar header
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        color: colorHeaderBg
                        
                        Label {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            text: qsTr("Chats")
                            font.bold: true
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                            color: colorText
                        }
                    }
                    
                    // Chat list
                    ListView {
                        id: chatListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        model: appController ? appController.chatListModel : null
                        clip: true
                        
                        delegate: ChatListItem {
                            width: chatListView.width
                            
                            onItemClicked: {
                                // Activate chat on click
                                activeServer = server
                                
                                // If clicked on server, don't set channel
                                // This prevents sending messages to server instead of channel
                                if (name === server) {
                                    activeChannel = ""
                                } else {
                                    activeChannel = name
                                }
                                
                                if (appController) {
                                    appController.set_active_chat(server, name)
                                }
                                
                                console.log("Activated chat: server=" + activeServer + ", channel=" + activeChannel)
                            }
                            
                            highlighted: activeServer === server && activeChannel === name
                        }
                    }
                }
            }
            
            // Chat area
            Rectangle {
                id: chatContainer
                SplitView.fillWidth: true
                color: colorBackground
                
                // Show placeholder if no active chat
                Item {
                    anchors.fill: parent
                    visible: !activeChannel
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 16
                        
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Select a chat or connect to a server")
                            font.pixelSize: 16
                            color: colorSecondaryText
                        }
                        
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 16
                            
                            Button {
                                text: qsTr("Connect to server")
                                onClicked: connectDialog.open()
                                
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: colorText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                background: Rectangle {
                                    color: parent.down ? Qt.darker(colorPrimary, 1.2) :
                                           parent.hovered ? colorPrimaryActive : colorPrimary
                                    radius: 4
                                }
                            }
                            
                            Button {
                                enabled: activeServer !== ""
                                text: qsTr("Join channel")
                                onClicked: {
                                    joinDialog.serverName = activeServer
                                    joinDialog.open()
                                }
                                
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: colorText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    opacity: parent.enabled ? 1.0 : 0.5
                                }
                                
                                background: Rectangle {
                                    color: !parent.enabled ? Qt.darker(colorPrimary, 1.5) :
                                           parent.down ? Qt.darker(colorPrimary, 1.2) :
                                           parent.hovered ? colorPrimaryActive : colorPrimary
                                    radius: 4
                                    opacity: parent.enabled ? 1.0 : 0.7
                                }
                            }
                        }
                    }
                }
                
                // Chat content
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    visible: activeChannel !== ""
                    
                    // Message list
                    ListView {
                        id: messageListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 0
                        
                        // Bind message model for active chat
                        model: (appController && activeServer && activeChannel) ? 
                               appController.getChatModel(activeServer, activeChannel) : null
                        
                        clip: true
                        
                        // Update when message count changes
                        onCountChanged: {
                            if (count > 0) {
                                // Always automatically scroll to last message
                                // when new messages are added
                                Qt.callLater(function() {
                                    positionViewAtEnd();
                                });
                            }
                        }
                        
                        // Prevent auto-scroll when clicking message area
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Click doesn't cause scroll to top, interrupt event handling
                                mouse.accepted = true;
                            }
                            
                            // Allow mouse wheel scrolling
                            onWheel: function(wheelEvent) {
                                wheelEvent.accepted = false;
                            }
                            
                            // Allow click events to pass to child elements
                            propagateComposedEvents: true
                        }
                        
                        // Delegate for displaying messages
                        delegate: MessageItem {}
                        
                        // Standard order for messages (old on top, new on bottom)
                        verticalLayoutDirection: ListView.TopToBottom
                        
                        // Spacing between list items
                        spacing: 4
                    }
                    
                    // Connection to messagesChanged signal of current chat model
                    Connections {
                        // Dynamically bind to current chat model
                        target: messageListView.model
                        
                        // React to message update signal
                        function onMessagesChanged() {
                            // Protection against too frequent UI updates
                            var currentTime = new Date().getTime();
                            if (mainWindow.chatUpdatingNow || currentTime - mainWindow.chatLastUpdateTime < 200) {
                                return; // Skip too frequent updates
                            }
                            
                            try {
                                mainWindow.chatUpdatingNow = true;
                                mainWindow.chatLastUpdateTime = currentTime;
                                
                                console.log("Received message update signal from chat model");
                                
                                // Always scroll to last message
                                Qt.callLater(function() {
                                    messageListView.positionViewAtEnd();
                                });
                            } finally {
                                // Small delay before resetting flag to prevent bouncing
                                resetChatUpdateFlagTimer.restart();
                            }
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: colorBorder
                    }
                    
                    // Message input panel
                    Pane {
                        Layout.fillWidth: true
                        padding: 8
                        background: Rectangle {
                            color: colorPanelBg
                            // Add top border for visual separation
                            Rectangle {
                                width: parent.width
                                height: 1
                                anchors.top: parent.top
                                color: Qt.rgba(colorBorder.r, colorBorder.g, colorBorder.b, 0.5)
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: 8
                            
                            // Message input field
                            TextArea {
                                id: messageInput
                                Layout.fillWidth: true
                                placeholderText: qsTr("Enter message...")
                                wrapMode: TextEdit.Wrap
                                color: colorText
                                
                                // Placeholder text color
                                placeholderTextColor: Qt.rgba(colorText.r, colorText.g, colorText.b, 0.6)
                                
                                background: Rectangle {
                                    color: colorInputBg
                                    border.color: Qt.rgba(colorBorder.r, colorBorder.g, colorBorder.b, 0.2)
                                    border.width: 1
                                    radius: 6  // Increase radius for more modern look
                                }
                                
                                // Send message on Enter (without Shift)
                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Return && !event.modifiers) {
                                        if (messageInput.text.trim() !== "") {
                                            sendButton.clicked()
                                        }
                                        event.accepted = true
                                    }
                                }
                            }
                            
                            // Send button
                            Button {
                                id: sendButton
                                text: qsTr("Send")
                                // Button is active only if:
                                // 1. Text is not empty
                                // 2. Connected to server
                                // 3. Channel selected (not just server)
                                // 4. Controller is available
                                enabled: messageInput.text.trim() !== "" && 
                                         activeServer && 
                                         activeChannel && 
                                         activeChannel !== activeServer && 
                                         appController !== null
                                
                                background: Rectangle {
                                    id: sendButtonBg
                                    color: !sendButton.enabled ? Qt.rgba(colorPrimary.r, colorPrimary.g, colorPrimary.b, 0.5) :
                                           sendButton.down ? Qt.darker(colorPrimary, 1.2) :
                                           sendButton.hovered ? colorPrimaryActive : colorPrimary
                                    radius: 6  // Make radius match text field
                                    
                                    // Add gradient for better button appearance
                                    gradient: Gradient {
                                        GradientStop { 
                                            position: 0.0
                                            color: !sendButton.enabled ? 
                                                  Qt.rgba(colorPrimary.r, colorPrimary.g, colorPrimary.b, 0.5) :
                                                  sendButton.down ? 
                                                  Qt.darker(colorPrimary, 1.2) : 
                                                  sendButton.hovered ? 
                                                  Qt.lighter(colorPrimaryActive, 1.05) : 
                                                  Qt.lighter(colorPrimary, 1.05)
                                        }
                                        GradientStop { 
                                            position: 1.0
                                            color: !sendButton.enabled ? 
                                                  Qt.rgba(colorPrimary.r, colorPrimary.g, colorPrimary.b, 0.5) :
                                                  sendButton.down ? 
                                                  Qt.darker(colorPrimary, 1.2) : 
                                                  sendButton.hovered ? 
                                                  colorPrimaryActive : 
                                                  colorPrimary
                                        }
                                    }
                                }
                                
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: colorText
                                    opacity: parent.enabled ? 1.0 : 0.7
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                onClicked: {
                                    console.log("Sending message: server=" + activeServer + ", channel=" + activeChannel);
                                    if (appController && activeServer && activeChannel) {
                                        var result = appController.send_message(activeServer, activeChannel, messageInput.text);
                                        console.log("Send result: " + result);
                                        if (result) {
                                            messageInput.clear();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Timer for forced periodic active chat updates
    Timer {
        id: refreshTimer
        interval: 10000  // Increase update interval to 10 seconds to reduce "jumps"
        running: activeServer !== "" && activeChannel !== ""
        repeat: true
        
        // Variable to track last update time
        property var lastUpdateTime: ({})
        
        onTriggered: {
            if (appController && activeServer && activeChannel) {
                // Check if updates are too frequent
                var currentTime = new Date().getTime();
                var lastUpdate = lastUpdateTime[activeServer + "/" + activeChannel] || 0;
                
                // Increase minimum update interval to 5 seconds
                if (currentTime - lastUpdate > 5000) {
                    // Request explicit update of current chat
                    appController.refresh_chat(activeServer, activeChannel);
                    lastUpdateTime[activeServer + "/" + activeChannel] = currentTime;
                    console.log("Timer: requesting chat update " + activeChannel + "@" + activeServer);
                }
            }
        }
    }
    
    // Animation for smooth message list scrolling down
    // (Not used to avoid "jumps")
    NumberAnimation {
        id: messageListScrollAnimation
        target: messageListView
        property: "contentY"
        to: messageListView.contentHeight - messageListView.height
        duration: 100  // Reduce duration for faster scrolling
        easing.type: Easing.Linear  // Simple linear animation
        // No longer using this animation to prevent "jumps"
    }
    
    // Debug information
    Component.onCompleted: {
        console.log("Application window loaded. appController:", appController);
        console.log("Testing testObj:", typeof testObj, testObj ? testObj.time : "undefined");
        
        if (appController === null || appController === undefined) {
            console.error("WARNING: appController was not set! Check that controller is correctly exported to QML.");
        } else {
            console.log("appController successfully received");
            
            // Output available appController signals
            console.log("=== appController Signals ===");
            var signals = [];
            for (var prop in appController) {
                if (typeof appController[prop] === "function" && prop.startsWith("on") && prop.length > 2) {
                    signals.push(prop);
                }
            }
            console.log("Signals: " + signals.join(", "));
        }
        
        // Check appController global properties
        console.log("Is appController global:", typeof global !== "undefined" && "appController" in global);
        
        // Check globals
        console.log("global properties:");
        for (var prop in this) {
            console.log(" - " + prop + ": " + typeof this[prop]);
        }
    }
} 