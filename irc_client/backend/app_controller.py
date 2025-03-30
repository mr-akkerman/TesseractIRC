import logging
import random
from typing import Optional, Dict, List

from PySide6.QtCore import QObject, Slot, Signal, Property, QTimer

from .irc_client import IRCClient
from .models import ChatListModel, ChatModel
from .database import DatabaseManager


class AppController(QObject):
    """
    Main application controller that connects UI and backend.
    Provides interface for QML.
    """
    # UI update signals
    errorOccurred = Signal(str)
    connectionStatusChanged = Signal(str, bool)  # server, status
    channelJoined = Signal(str, str)  # server, channel
    messagesUpdated = Signal(str, str)  # server, channel
    chatListModelChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._irc_client = IRCClient()
        self._chat_list_model = ChatListModel()
        self._nickname = f"TesseractIRC_{random.randint(100000, 999999)}"
        
        self._db_manager = DatabaseManager()
        
        self._update_timer = QTimer(self)
        self._update_timer.timeout.connect(self._check_for_new_messages)
        self._update_timer.start(5000)
        
        self._updating = False
        self._last_update_time = {}
        
        self._irc_client.message_received.connect(self._on_message_received)
        self._irc_client.server_connected.connect(self._on_server_connected)
        self._irc_client.server_disconnected.connect(self._on_server_disconnected)
        self._irc_client.channel_joined.connect(self._on_channel_joined)
        self._irc_client.channel_left.connect(self._on_channel_left)
        
        self.logger = logging.getLogger("AppController")
        
        self._load_user_profile()
        self._load_saved_data()
        
    def _load_user_profile(self):
        """Loads user profile from database"""
        try:
            profile = self._db_manager.get_user_profile()
            self._nickname = profile["nickname"]
        except Exception as e:
            self.logger.error(f"Error loading user profile: {e}")
            
    def _update_chat_models_nickname(self):
        """Updates user nickname in all chat models"""
        try:
            for server, channels in self._chat_list_model._chat_models.items():
                for channel, model in channels.items():
                    if model:
                        model.set_own_nickname(self._nickname)
        except Exception as e:
            self.logger.error(f"Error updating nickname in chat models: {e}")
            
    def _load_saved_data(self):
        """Loads saved servers and channels from database"""
        try:
            servers = self._db_manager.get_all_servers()
            
            for server_data in servers:
                server = server_data['server']
                port = server_data['port']
                nickname = server_data['nickname']
                username = server_data['username']
                realname = server_data['realname']
                
                result = self._irc_client.connect_to_server(server, port, nickname, username, realname)
                
                if result:
                    self._chat_list_model.add_server(server)
                    
                    channels = self._db_manager.get_channels_for_server(server)
                    
                    for channel_data in channels:
                        if channel_data['auto_join']:
                            channel = channel_data['name']
                            is_private = channel_data['is_private']
                            
                            self._irc_client.join_channel(server, channel)
                            self._chat_list_model.add_channel(server, channel, is_private)
                            
        except Exception as e:
            self.logger.error(f"Error loading saved data: {e}")
        
    @Property(str)
    def nickname(self) -> str:
        """Returns current user nickname"""
        return self._nickname
        
    @nickname.setter
    def nickname(self, nickname: str):
        """Sets user nickname"""
        if not nickname or nickname == self._nickname:
            return
            
        self._nickname = nickname
        self._db_manager.save_user_profile(nickname)
        self._update_chat_models_nickname()
        
    @Slot(str, int, str, str, str, result=bool)
    def connect_to_server(self, server: str, port: int = 6667, 
                          nickname: str = "", username: str = "", realname: str = "") -> bool:
        """
        Connects to IRC server
        
        Args:
            server: Server address
            port: Server port
            nickname: User nickname (if empty, uses current)
            username: Username (if empty, uses nickname)
            realname: Real name (if empty, uses nickname)
        """
        if not server:
            self.errorOccurred.emit("Server address not specified")
            return False
            
        if not nickname:
            nickname = self._nickname
        else:
            self.nickname = nickname
            
        if not username:
            username = nickname
            
        if not realname:
            realname = nickname
        
        if username != nickname or realname != nickname:
            self._db_manager.save_user_profile(nickname, username, realname)
            
        result = self._irc_client.connect_to_server(server, port, nickname, username, realname)
        
        if result:
            self._chat_list_model.add_server(server)
            self._db_manager.save_server(server, port, nickname, username, realname)
        else:
            self.errorOccurred.emit(f"Failed to connect to server {server}")
            
        return result
        
    @Slot(str, result=bool)
    def disconnect_from_server(self, server: str) -> bool:
        """
        Disconnects from IRC server
        
        Args:
            server: Server address
        """
        if not server:
            return False
            
        self._irc_client.disconnect_from_server(server)
        self._chat_list_model.remove_server(server)
        self._db_manager.delete_server(server)
        
        return True
        
    @Slot(str, str, result=bool)
    def join_channel(self, server: str, channel: str) -> bool:
        """
        Joins channel on server
        
        Args:
            server: Server address
            channel: Channel name
        """
        if not server or not channel:
            return False
            
        result = self._irc_client.join_channel(server, channel)
        
        if result:
            is_private = not channel.startswith('#') and not channel.startswith('&')
            self._db_manager.save_channel(server, channel, is_private)
        else:
            self.errorOccurred.emit(f"Failed to join channel {channel} on server {server}")
            
        return result
        
    @Slot(str, str, result=bool)
    def leave_channel(self, server: str, channel: str) -> bool:
        """
        Leaves channel on server
        
        Args:
            server: Server address
            channel: Channel name
        """
        if not server or not channel:
            return False
            
        self._irc_client.leave_channel(server, channel)
        self._chat_list_model.remove_channel(server, channel)
        self._db_manager.delete_channel(server, channel)
        
        return True
        
    @Slot(str, str, str, result=bool)
    def send_message(self, server: str, channel: str, message: str) -> bool:
        """
        Sends message to channel
        
        Args:
            server: Server address
            channel: Channel or user name
            message: Message text
        """
        if not server or not channel or not message:
            return False
            
        channel_exists = False
        for chat in self._chat_list_model._chats:
            if chat["server"] == server and chat["name"] == channel:
                channel_exists = True
                break
        
        if not channel_exists:
            self.errorOccurred.emit(f"Channel {channel} not found on server {server}. You may need to join it first.")
            return False
            
        return self._irc_client.send_message(server, channel, message)
        
    @Slot(str, str, result=bool)
    def set_active_chat(self, server: str, channel: str) -> bool:
        """
        Sets active chat
        
        Args:
            server: Server address
            channel: Channel name
        """
        return self._chat_list_model.set_active_chat(server, channel)
        
    @Slot(str, str, result=bool)
    def activate_channel(self, server: str, channel: str) -> bool:
        """
        Explicitly sets active channel and updates UI
        
        Args:
            server: Server address
            channel: Channel name
        """
        result = self._chat_list_model.set_active_chat(server, channel)
        
        if result:
            self.channelJoined.emit(server, channel)
            
        return result
        
    def get_chat_list_model(self):
        """Returns chat list model for QML"""
        return self._chat_list_model
        
    chatListModel = Property(QObject, get_chat_list_model, notify=chatListModelChanged)
        
    @Slot(str, str, result=QObject)
    def getChatModel(self, server: str, channel: str) -> Optional[ChatModel]:
        """
        Returns chat model for specified server and channel
        
        Args:
            server: Server address
            channel: Channel name
        """
        chat_model = self._chat_list_model.get_chat_model(server, channel)
        
        if chat_model:
            chat_model.set_own_nickname(self._nickname)
            
        return chat_model
        
    @Slot(result=list)
    def get_servers(self) -> List[str]:
        """Returns list of connected servers"""
        return self._irc_client.get_servers()
        
    @Slot()
    def _check_for_new_messages(self):
        """Periodically checks for new messages on server"""
        if self._updating:
            return
            
        try:
            self._updating = True
            
            servers = self._irc_client.get_servers()
            if not servers:
                return
                
            import time
            current_time = time.time()
            
            for server in servers:
                last_update = self._last_update_time.get(server, 0)
                if current_time - last_update < 2.0:
                    continue
                    
                self._last_update_time[server] = current_time
                
                update_result = self._irc_client.process_once(server)
                if not update_result:
                    continue
                    
                if server in self._chat_list_model._chat_models:
                    channels = self._chat_list_model._chat_models[server]
                    
                    active_server, active_channel = self._chat_list_model.get_active_chat()
                    
                    if server == active_server and active_channel in channels:
                        chat_model = channels[active_channel]
                        if chat_model.update_messages_if_needed():
                            self.messagesUpdated.emit(server, active_channel)
                    
                    for channel, chat_model in channels.items():
                        if channel != active_channel:
                            chat_model.update_messages_if_needed()
        except Exception as e:
            self.logger.error(f"Error checking new messages: {e}")
        finally:
            self._updating = False

    @Slot(str, str, result=bool)
    def refresh_chat(self, server: str, channel: str):
        """
        Force refreshes chat on UI request
        
        Args:
            server: Server address
            channel: Channel name
        """
        if self._updating:
            return False
            
        try:
            self._updating = True
            
            if not server or not channel or server not in self._irc_client.get_servers():
                return False
                
            update_result = self._irc_client.process_once(server)
            
            chat_model = self._chat_list_model.get_chat_model(server, channel)
            if chat_model:
                if channel == self._chat_list_model._active_channel:
                    chat_model.force_data_changed()
                else:
                    chat_model.update_messages_if_needed()
                
            if channel == self._chat_list_model._active_channel:
                self.messagesUpdated.emit(server, channel)
                
            return True
        except Exception as e:
            self.logger.error(f"Error refreshing chat {channel}@{server}: {e}")
            return False
        finally:
            self._updating = False

    def _on_message_received(self, server: str, channel: str, sender: str, message: str):
        """Message received handler"""
        chat_model = self._chat_list_model.get_chat_model(server, channel)
        if chat_model:
            chat_model.set_own_nickname(self._nickname)
            chat_model.add_message(sender, message)
            
            self._chat_list_model.update_channel_info(server, channel, message, sender)
        
        self.messagesUpdated.emit(server, channel)
        
    def _on_server_connected(self, server: str):
        """Server connection handler"""
        self._chat_list_model.add_system_message_to_chat(
            server, server, f"Connected to server {server}"
        )
        
        self.connectionStatusChanged.emit(server, True)
        
    def _on_server_disconnected(self, server: str):
        """Server disconnection handler"""
        self.connectionStatusChanged.emit(server, False)
        
    def _on_channel_joined(self, server: str, channel: str):
        """Channel join handler"""
        is_private = not channel.startswith('#') and not channel.startswith('&')
        self._chat_list_model.add_channel(server, channel, is_private)
        
        chat_model = self._chat_list_model.get_chat_model(server, channel)
        if chat_model:
            chat_model.set_own_nickname(self._nickname)
            chat_model.add_system_message(f"You joined channel {channel}")
            
        self.channelJoined.emit(server, channel)
        
    def _on_channel_left(self, server: str, channel: str):
        """Channel leave handler"""
        self._chat_list_model.add_system_message_to_chat(
            server, channel, f"You left channel {channel}"
        )
        
        QTimer.singleShot(1000, lambda: self._chat_list_model.remove_channel(server, channel))

    @Slot(str, str, bool, result=bool)
    def save_channel_settings(self, server: str, channel: str, auto_join: bool) -> bool:
        """
        Saves channel settings
        
        Args:
            server: Server address
            channel: Channel name
            auto_join: Auto-join flag
            
        Returns:
            True if settings saved successfully
        """
        if not server or not channel:
            return False
            
        is_private = not channel.startswith('#') and not channel.startswith('&')
        
        result = self._db_manager.save_channel(server, channel, is_private, auto_join)
            
        return result
        
    @Slot(str, str, result=bool)
    def get_channel_auto_join(self, server: str, channel: str) -> bool:
        """
        Returns channel auto-join flag
        
        Args:
            server: Server address
            channel: Channel name
            
        Returns:
            True if channel is set to auto-join
        """
        if not server or not channel:
            return False
            
        channels = self._db_manager.get_channels_for_server(server)
        
        for channel_data in channels:
            if channel_data['name'] == channel:
                return channel_data['auto_join']
                
        return True