import datetime
from typing import List, Dict, Optional
import logging

from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Signal, QDateTime
from PySide6.QtGui import QColor


class Message:
    """Chat message representation"""
    
    def __init__(self, sender: str, content: str, timestamp: datetime.datetime = None, 
                 is_system: bool = False):
        self.sender = sender
        self.content = content
        self.timestamp = timestamp or datetime.datetime.now()
        self.is_system = is_system
        
    def formatted_time(self) -> str:
        """Format message time for display"""
        return self.timestamp.strftime("%H:%M")
        
        
class ChatModel(QAbstractListModel):
    """Model for displaying chat messages in a list"""
    
    SenderRole = Qt.UserRole + 1
    ContentRole = Qt.UserRole + 2
    TimestampRole = Qt.UserRole + 3
    IsSystemRole = Qt.UserRole + 4
    FormattedTimeRole = Qt.UserRole + 5
    IsOwnMessageRole = Qt.UserRole + 6
    
    messagesChanged = Signal()
    
    def __init__(self, own_nickname: str = "", parent=None):
        super().__init__(parent)
        self._messages: List[Message] = []
        self._own_nickname = own_nickname
        self._last_update_timestamp = datetime.datetime.now()
        
    def rowCount(self, parent=QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._messages)
        
    def data(self, index: QModelIndex, role: int):
        if not index.isValid() or index.row() >= len(self._messages):
            return None
            
        message = self._messages[index.row()]
        
        if role == self.SenderRole:
            return message.sender
        elif role == self.ContentRole:
            return message.content
        elif role == self.TimestampRole:
            return QDateTime.fromSecsSinceEpoch(int(message.timestamp.timestamp()))
        elif role == self.IsSystemRole:
            return message.is_system
        elif role == self.FormattedTimeRole:
            return message.formatted_time()
        elif role == self.IsOwnMessageRole:
            return message.sender == self._own_nickname
            
        return None
        
    def roleNames(self) -> Dict:
        return {
            self.SenderRole: b"sender",
            self.ContentRole: b"content",
            self.TimestampRole: b"timestamp",
            self.IsSystemRole: b"isSystem",
            self.FormattedTimeRole: b"formattedTime",
            self.IsOwnMessageRole: b"isOwnMessage"
        }
        
    def add_message(self, sender: str, content: str, is_system: bool = False) -> int:
        """Add new message to model"""
        self.beginInsertRows(QModelIndex(), len(self._messages), len(self._messages))
        self._messages.append(Message(sender, content, is_system=is_system))
        self._last_update_timestamp = datetime.datetime.now()
        self.endInsertRows()
        
        self.messagesChanged.emit()
        
        return len(self._messages) - 1
        
    def add_system_message(self, content: str) -> int:
        """Add system message to model"""
        return self.add_message("System", content, is_system=True)
        
    def set_own_nickname(self, nickname: str):
        """Set own nickname for identifying own messages"""
        if self._own_nickname != nickname:
            self._own_nickname = nickname
            self.dataChanged.emit(
                self.index(0, 0),
                self.index(self.rowCount() - 1, 0),
                [self.IsOwnMessageRole]
            )
        
    def clear(self):
        """Clear all messages"""
        self.beginResetModel()
        self._messages.clear()
        self._last_update_timestamp = datetime.datetime.now()
        self.endResetModel()
        
        self.messagesChanged.emit()
    
    def force_data_changed(self):
        """Force update all data in model"""
        if self.rowCount() == 0:
            return
            
        try:
            start_row = max(0, self.rowCount() - 10)
            
            self.dataChanged.emit(
                self.index(start_row, 0),
                self.index(self.rowCount() - 1, 0),
                list(self.roleNames().keys())
            )
            
            self._last_update_timestamp = datetime.datetime.now()
            self.messagesChanged.emit()
        except Exception as e:
            print(f"Error updating model data: {e}")
    
    def update_messages_if_needed(self):
        """Check for new messages and update UI if needed"""
        if not self._messages:
            return False
            
        try:
            newest_message = max(self._messages, key=lambda m: m.timestamp)
            
            if newest_message.timestamp > self._last_update_timestamp:
                self._last_update_timestamp = newest_message.timestamp
                self.messagesChanged.emit()
                return True
        except Exception as e:
            print(f"Error checking new messages: {e}")
        
        return False


class ChatListModel(QAbstractListModel):
    """Model for displaying chat list in sidebar"""
    
    NameRole = Qt.UserRole + 1
    UnreadCountRole = Qt.UserRole + 2
    ServerRole = Qt.UserRole + 3
    IsPrivateRole = Qt.UserRole + 4
    LastMessageRole = Qt.UserRole + 5
    LastMessageTimeRole = Qt.UserRole + 6
    
    activeChannelChanged = Signal(str, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._chats: List[Dict] = []
        self._active_server: Optional[str] = None
        self._active_channel: Optional[str] = None
        self._chat_models: Dict[str, Dict[str, ChatModel]] = {}
        self.logger = logging.getLogger("ChatListModel")
        
    def rowCount(self, parent=QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._chats)
        
    def data(self, index: QModelIndex, role: int):
        if not index.isValid() or index.row() >= len(self._chats):
            return None
            
        chat = self._chats[index.row()]
        
        if role == self.NameRole:
            return chat["name"]
        elif role == self.UnreadCountRole:
            return chat.get("unread_count", 0)
        elif role == self.ServerRole:
            return chat["server"]
        elif role == self.IsPrivateRole:
            return chat.get("is_private", False)
        elif role == self.LastMessageRole:
            return chat.get("last_message", "")
        elif role == self.LastMessageTimeRole:
            return chat.get("last_message_time", "")
            
        return None
        
    def roleNames(self) -> Dict:
        return {
            self.NameRole: b"name",
            self.UnreadCountRole: b"unreadCount",
            self.ServerRole: b"server",
            self.IsPrivateRole: b"isPrivate",
            self.LastMessageRole: b"lastMessage",
            self.LastMessageTimeRole: b"lastMessageTime"
        }
        
    def add_server(self, server: str) -> bool:
        """Add server to chat list"""
        for chat in self._chats:
            if chat["server"] == server and chat["name"] == server:
                return False
                
        self.beginInsertRows(QModelIndex(), len(self._chats), len(self._chats))
        self._chats.append({
            "name": server,
            "server": server,
            "is_private": False,
            "unread_count": 0,
            "last_message": "",
            "last_message_time": ""
        })
        self.endInsertRows()
        
        if server not in self._chat_models:
            self._chat_models[server] = {}
            
        return True
        
    def add_channel(self, server: str, channel: str, is_private: bool = False) -> bool:
        """Add channel to chat list"""
        for chat in self._chats:
            if chat["server"] == server and chat["name"] == channel:
                if server not in self._chat_models:
                    self._chat_models[server] = {}
                
                if channel not in self._chat_models[server]:
                    self._chat_models[server][channel] = ChatModel()
                
                return True
                
        server_exists = False
        for chat in self._chats:
            if chat["server"] == server and chat["name"] == server:
                server_exists = True
                break
                
        if not server_exists:
            self.add_server(server)
            
        self.beginInsertRows(QModelIndex(), len(self._chats), len(self._chats))
        self._chats.append({
            "name": channel,
            "server": server,
            "is_private": is_private,
            "unread_count": 0,
            "last_message": "",
            "last_message_time": ""
        })
        self.endInsertRows()
        
        if server not in self._chat_models:
            self._chat_models[server] = {}
            
        self._chat_models[server][channel] = ChatModel()
        
        return True
        
    def remove_server(self, server: str) -> bool:
        """Remove server and all its channels"""
        indices_to_remove = []
        for i, chat in enumerate(self._chats):
            if chat["server"] == server:
                indices_to_remove.append(i)
                
        if not indices_to_remove:
            return False
            
        for i in reversed(indices_to_remove):
            self.beginRemoveRows(QModelIndex(), i, i)
            del self._chats[i]
            self.endRemoveRows()
            
        if server in self._chat_models:
            del self._chat_models[server]
            
        if self._active_server == server:
            self._active_server = None
            self._active_channel = None
            self.activeChannelChanged.emit("", "")
            
        return True
        
    def remove_channel(self, server: str, channel: str) -> bool:
        """Remove channel from chat list"""
        index_to_remove = -1
        for i, chat in enumerate(self._chats):
            if chat["server"] == server and chat["name"] == channel:
                index_to_remove = i
                break
                
        if index_to_remove == -1:
            return False
            
        self.beginRemoveRows(QModelIndex(), index_to_remove, index_to_remove)
        del self._chats[index_to_remove]
        self.endRemoveRows()
        
        if server in self._chat_models and channel in self._chat_models[server]:
            del self._chat_models[server][channel]
            
        if self._active_server == server and self._active_channel == channel:
            self._active_server = None
            self._active_channel = None
            self.activeChannelChanged.emit("", "")
            
        return True
        
    def get_chat_model(self, server: str, channel: str) -> Optional[ChatModel]:
        """Get chat model for server and channel"""
        if server not in self._chat_models or channel not in self._chat_models[server]:
            if server not in self._chat_models:
                self._chat_models[server] = {}
                
            self._chat_models[server][channel] = ChatModel()
            
        return self._chat_models[server][channel]
        
    def set_active_chat(self, server: str, channel: str) -> bool:
        """Set active chat"""
        chat_exists = False
        for chat in self._chats:
            if chat["server"] == server and chat["name"] == channel:
                chat_exists = True
                break
                
        if not chat_exists and channel:
            if server:
                self.add_channel(server, channel)
                chat_exists = True
            else:
                return False
                
        old_server = self._active_server
        old_channel = self._active_channel
        
        self._active_server = server
        self._active_channel = channel
        
        if server and channel:
            if server not in self._chat_models:
                self._chat_models[server] = {}
                
            if channel not in self._chat_models[server]:
                self._chat_models[server][channel] = ChatModel()
                
        if server and channel:
            for i, chat in enumerate(self._chats):
                if chat["server"] == server and chat["name"] == channel:
                    if chat["unread_count"] > 0:
                        chat["unread_count"] = 0
                        self.dataChanged.emit(
                            self.index(i, 0),
                            self.index(i, 0),
                            [self.UnreadCountRole]
                        )
                    break
                    
        if old_server != server or old_channel != channel:
            self.activeChannelChanged.emit(server, channel)
            
        return True
        
    def add_message_to_chat(self, server: str, channel: str, sender: str, content: str) -> bool:
        """Add message to chat and update last message info"""
        chat_model = self.get_chat_model(server, channel)
        if not chat_model:
            return False
            
        chat_model.add_message(sender, content)
        
        time_str = datetime.datetime.now().strftime("%H:%M")
        
        for i, chat in enumerate(self._chats):
            if chat["server"] == server and chat["name"] == channel:
                chat["last_message"] = f"{sender}: {content}"
                chat["last_message_time"] = time_str
                
                if self._active_server != server or self._active_channel != channel:
                    chat["unread_count"] += 1
                    
                self.dataChanged.emit(
                    self.index(i, 0),
                    self.index(i, 0),
                    [self.LastMessageRole, self.LastMessageTimeRole, self.UnreadCountRole]
                )
                break
                
        return True
        
    def add_system_message_to_chat(self, server: str, channel: str, content: str) -> bool:
        """Add system message to chat"""
        chat_model = self.get_chat_model(server, channel)
        if not chat_model:
            return False
            
        chat_model.add_system_message(content)
        return True
        
    def get_active_chat(self) -> tuple:
        """Get active chat (server, channel)"""
        return self._active_server, self._active_channel
        
    def update_channel_info(self, server: str, channel: str, last_message: str, 
                          sender: str = None, is_unread: bool = True) -> bool:
        """Update channel info in chat list"""
        time_str = datetime.datetime.now().strftime("%H:%M")
        
        for i, chat in enumerate(self._chats):
            if chat["server"] == server and chat["name"] == channel:
                if sender:
                    chat["last_message"] = f"{sender}: {last_message}"
                else:
                    chat["last_message"] = last_message
                    
                chat["last_message_time"] = time_str
                
                if is_unread and (self._active_server != server or self._active_channel != channel):
                    chat["unread_count"] += 1
                    
                self.dataChanged.emit(
                    self.index(i, 0),
                    self.index(i, 0),
                    [self.LastMessageRole, self.LastMessageTimeRole, self.UnreadCountRole]
                )
                return True
                
        return False 