import logging
import threading
from typing import Dict, List, Callable, Optional

import irc.client
from PySide6.QtCore import QObject, Signal

class IRCClient(QObject):
    """
    IRC client class for connecting to IRC servers and exchanging messages.
    Implements core IRC protocol functionality.
    """
    # UI update signals
    message_received = Signal(str, str, str, str)  # server, channel, sender, text
    server_connected = Signal(str)  # server
    server_disconnected = Signal(str)  # server
    channel_joined = Signal(str, str)  # server, channel
    channel_left = Signal(str, str)  # server, channel
    
    def __init__(self):
        super().__init__()
        self.clients: Dict[str, irc.client.SimpleIRCClient] = {}
        self.reactor = irc.client.Reactor()
        self._thread = None
        self.running = False
        self.logger = logging.getLogger("IRCClient")
        
    def start_reactor(self):
        """Starts IRC reactor in a separate thread"""
        if self._thread is not None and self._thread.is_alive():
            return
            
        self.running = True
        self._thread = threading.Thread(target=self._reactor_loop)
        self._thread.daemon = True
        self._thread.start()
        
    def _reactor_loop(self):
        """IRC event processing loop"""
        while self.running:
            self.reactor.process_once(0.1)
            
    def process_once(self, server: str):
        """
        Force process one batch of messages for specified server
        
        Args:
            server: Server address
        """
        if server not in self.clients:
            return False
            
        try:
            client = self.clients[server]
            if client.connection and client.connection.socket:
                if client.connection.socket.fileno() == -1:
                    return False
                    
                import socket
                client.connection.socket.setblocking(False)
                
                try:
                    import select
                    readable, _, _ = select.select([client.connection.socket], [], [], 0.01)
                    
                    if readable:
                        client.connection.process_data()
                    return True
                except (socket.error, OSError):
                    return False
        except Exception:
            pass
        
        return False
            
    def stop_reactor(self):
        """Stops IRC reactor"""
        self.running = False
        if self._thread is not None:
            self._thread.join(1.0)
            
    def connect_to_server(self, server: str, port: int = 6667, 
                         nickname: str = "PySideUser", 
                         username: str = "PySideUser",
                         realname: str = "PySide IRC Client"):
        """
        Connects to IRC server
        
        Args:
            server: Server address
            port: Server port
            nickname: User nickname
            username: Username
            realname: Real name
        """
        if server in self.clients:
            return False
            
        try:
            client = _IRCClientImpl(self, server)
            client.connect(server, port, nickname, username, realname)
            self.clients[server] = client
            
            if not self.running:
                self.start_reactor()
                
            return True
        except irc.client.ServerConnectionError:
            return False
            
    def disconnect_from_server(self, server: str, message: str = "Goodbye!"):
        """
        Disconnects from IRC server
        
        Args:
            server: Server address
            message: Quit message
        """
        if server not in self.clients:
            return
            
        client = self.clients[server]
        client.connection.disconnect(message)
        del self.clients[server]
        self.server_disconnected.emit(server)
        
    def join_channel(self, server: str, channel: str):
        """
        Joins channel on server
        
        Args:
            server: Server address
            channel: Channel name
        """
        if server not in self.clients:
            return False
            
        client = self.clients[server]
        client.connection.join(channel)
        return True
        
    def leave_channel(self, server: str, channel: str, message: str = "Goodbye!"):
        """
        Leaves channel on server
        
        Args:
            server: Server address
            channel: Channel name
            message: Part message
        """
        if server not in self.clients:
            return
            
        client = self.clients[server]
        client.connection.part(channel, message)
        
    def send_message(self, server: str, target: str, message: str):
        """
        Sends message to server
        
        Args:
            server: Server address
            target: Target channel or user
            message: Message text
        """
        if server not in self.clients:
            return False
            
        client = self.clients[server]
        
        if target == server:
            return False
            
        if not target.startswith('#') and not target.startswith('&'):
            self.logger.warning(f"Possibly invalid channel name: {target}")
        
        try:
            client.connection.privmsg(target, message)
            
            nickname = client.connection.get_nickname()
            self.message_received.emit(server, target, nickname, message)
            
            return True
        except Exception:
            return False
        
    def get_servers(self) -> List[str]:
        """Returns list of connected servers"""
        return list(self.clients.keys())
        
    def __del__(self):
        self.stop_reactor()


class _IRCClientImpl(irc.client.SimpleIRCClient):
    """
    Internal class for handling IRC events
    """
    def __init__(self, parent: IRCClient, server: str):
        super().__init__()
        self.parent = parent
        self.server = server
        
    def on_welcome(self, connection, event):
        """Called on successful server connection"""
        self.parent.server_connected.emit(self.server)
        
    def on_join(self, connection, event):
        """Called when joining a channel"""
        channel = event.target
        nick = event.source.nick
        
        if nick == connection.get_nickname():
            self.parent.channel_joined.emit(self.server, channel)
            
    def on_part(self, connection, event):
        """Called when leaving a channel"""
        channel = event.target
        nick = event.source.nick
        
        if nick == connection.get_nickname():
            self.parent.channel_left.emit(self.server, channel)
            
    def on_privmsg(self, connection, event):
        """Called on private message"""
        sender = event.source.nick
        target = connection.get_nickname()
        message = event.arguments[0]
        
        self.parent.message_received.emit(self.server, sender, sender, message)
        
    def on_pubmsg(self, connection, event):
        """Called on channel message"""
        sender = event.source.nick
        channel = event.target
        message = event.arguments[0]
        
        self.parent.message_received.emit(self.server, channel, sender, message) 