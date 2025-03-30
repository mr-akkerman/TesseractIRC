"""
SQLite database module.
Provides application settings storage and loading.
"""

import os
import random
import sqlite3
import logging
from typing import List, Dict, Tuple, Optional

logger = logging.getLogger("Database")

class DatabaseManager:
    """
    SQLite database manager.
    Provides methods for saving and loading servers and channels.
    """
    
    def __init__(self, db_path: str = None):
        """
        Initialize database manager.
        
        Args:
            db_path: Path to database file. If None, default path will be used.
        """
        if db_path is None:
            user_home = os.path.expanduser("~")
            app_dir = os.path.join(user_home, ".genomo_irc")
            
            if not os.path.exists(app_dir):
                os.makedirs(app_dir)
                
            self.db_path = os.path.join(app_dir, "genomo_irc.db")
        else:
            self.db_path = db_path
            
        self._create_tables()
        
    def _create_tables(self):
        """Creates required database tables if they don't exist."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS servers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                server_name TEXT NOT NULL UNIQUE,
                port INTEGER DEFAULT 6667,
                nickname TEXT,
                username TEXT,
                realname TEXT,
                last_connected TIMESTAMP
            )
            ''')
            
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS channels (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                server_id INTEGER NOT NULL,
                channel_name TEXT NOT NULL,
                is_private BOOLEAN DEFAULT 0,
                auto_join BOOLEAN DEFAULT 1,
                FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
                UNIQUE(server_id, channel_name)
            )
            ''')
            
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT NOT NULL UNIQUE,
                value TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            ''')
            
            conn.commit()
        except sqlite3.Error as e:
            logger.error(f"Error creating tables: {e}")
        finally:
            if conn:
                conn.close()
                
    def save_server(self, server_name: str, port: int = 6667, 
                   nickname: str = "PySideUser", username: str = "PySideUser", 
                   realname: str = "PySide IRC Client") -> bool:
        """
        Save server to database.
        
        Args:
            server_name: Server name
            port: Server port
            nickname: User nickname
            username: Username
            realname: Real name
            
        Returns:
            True if successful, False otherwise
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("SELECT id FROM servers WHERE server_name = ?", (server_name,))
            result = cursor.fetchone()
            
            if result:
                server_id = result[0]
                cursor.execute('''
                UPDATE servers 
                SET port = ?, nickname = ?, username = ?, realname = ?, last_connected = CURRENT_TIMESTAMP
                WHERE id = ?
                ''', (port, nickname, username, realname, server_id))
            else:
                cursor.execute('''
                INSERT INTO servers (server_name, port, nickname, username, realname, last_connected)
                VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ''', (server_name, port, nickname, username, realname))
                
            conn.commit()
            return True
        except sqlite3.Error as e:
            logger.error(f"Error saving server {server_name}: {e}")
            return False
        finally:
            if conn:
                conn.close()
                
    def save_channel(self, server_name: str, channel_name: str, is_private: bool = False, auto_join: bool = True) -> bool:
        """
        Save channel for specified server.
        
        Args:
            server_name: Server name
            channel_name: Channel name
            is_private: Whether channel is private
            auto_join: Whether to auto-join channel on connect
            
        Returns:
            True if successful, False otherwise
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("SELECT id FROM servers WHERE server_name = ?", (server_name,))
            result = cursor.fetchone()
            
            if not result:
                return False
                
            server_id = result[0]
            
            cursor.execute("SELECT id FROM channels WHERE server_id = ? AND channel_name = ?", 
                         (server_id, channel_name))
            result = cursor.fetchone()
            
            if result:
                channel_id = result[0]
                cursor.execute('''
                UPDATE channels 
                SET is_private = ?, auto_join = ?
                WHERE id = ?
                ''', (1 if is_private else 0, 1 if auto_join else 0, channel_id))
            else:
                cursor.execute('''
                INSERT INTO channels (server_id, channel_name, is_private, auto_join)
                VALUES (?, ?, ?, ?)
                ''', (server_id, channel_name, 1 if is_private else 0, 1 if auto_join else 0))
                
            conn.commit()
            return True
        except sqlite3.Error as e:
            logger.error(f"Error saving channel {channel_name} for server {server_name}: {e}")
            return False
        finally:
            if conn:
                conn.close()
                
    def get_all_servers(self) -> List[Dict]:
        """
        Get list of all saved servers.
        
        Returns:
            List of server info dictionaries
        """
        servers = []
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute('''
            SELECT id, server_name, port, nickname, username, realname, last_connected
            FROM servers
            ORDER BY last_connected DESC
            ''')
            
            for row in cursor.fetchall():
                servers.append({
                    'id': row['id'],
                    'server': row['server_name'],
                    'port': row['port'],
                    'nickname': row['nickname'],
                    'username': row['username'],
                    'realname': row['realname'],
                    'last_connected': row['last_connected']
                })
        except sqlite3.Error as e:
            logger.error(f"Error getting servers: {e}")
        finally:
            if conn:
                conn.close()
                
        return servers
        
    def get_channels_for_server(self, server_name: str) -> List[Dict]:
        """
        Get list of channels for specified server.
        
        Args:
            server_name: Server name
            
        Returns:
            List of channel info dictionaries
        """
        channels = []
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute('''
            SELECT c.id, c.channel_name, c.is_private, c.auto_join
            FROM channels c
            JOIN servers s ON c.server_id = s.id
            WHERE s.server_name = ?
            ''', (server_name,))
            
            for row in cursor.fetchall():
                channels.append({
                    'id': row['id'],
                    'name': row['channel_name'],
                    'is_private': bool(row['is_private']),
                    'auto_join': bool(row['auto_join'])
                })
        except sqlite3.Error as e:
            logger.error(f"Error getting channels for server {server_name}: {e}")
        finally:
            if conn:
                conn.close()
                
        return channels
    
    def delete_server(self, server_name: str) -> bool:
        """
        Delete server from database.
        
        Args:
            server_name: Server name
            
        Returns:
            True if successful, False otherwise
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("DELETE FROM servers WHERE server_name = ?", (server_name,))
            conn.commit()
            
            return cursor.rowcount > 0
        except sqlite3.Error as e:
            logger.error(f"Error deleting server {server_name}: {e}")
            return False
        finally:
            if conn:
                conn.close()
                
    def delete_channel(self, server_name: str, channel_name: str) -> bool:
        """
        Delete channel for specified server.
        
        Args:
            server_name: Server name
            channel_name: Channel name
            
        Returns:
            True if successful, False otherwise
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("SELECT id FROM servers WHERE server_name = ?", (server_name,))
            result = cursor.fetchone()
            
            if not result:
                return False
                
            server_id = result[0]
            
            cursor.execute("DELETE FROM channels WHERE server_id = ? AND channel_name = ?", 
                         (server_id, channel_name))
            conn.commit()
            
            return cursor.rowcount > 0
        except sqlite3.Error as e:
            logger.error(f"Error deleting channel {channel_name} for server {server_name}: {e}")
            return False
        finally:
            if conn:
                conn.close()
                
    def save_user_setting(self, key: str, value: str) -> bool:
        """
        Save user setting to database.
        
        Args:
            key: Setting key
            value: Setting value
            
        Returns:
            True if successful, False otherwise
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("SELECT id FROM user_settings WHERE key = ?", (key,))
            result = cursor.fetchone()
            
            if result:
                cursor.execute('''
                UPDATE user_settings 
                SET value = ?, updated_at = CURRENT_TIMESTAMP
                WHERE key = ?
                ''', (value, key))
            else:
                cursor.execute('''
                INSERT INTO user_settings (key, value)
                VALUES (?, ?)
                ''', (key, value))
                
            conn.commit()
            return True
        except sqlite3.Error as e:
            logger.error(f"Error saving setting {key}: {e}")
            return False
        finally:
            if conn:
                conn.close()
                
    def get_user_setting(self, key: str, default_value: str = None) -> str:
        """
        Get user setting from database.
        
        Args:
            key: Setting key
            default_value: Default value if setting not found
            
        Returns:
            Setting value or default_value if not found
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("SELECT value FROM user_settings WHERE key = ?", (key,))
            result = cursor.fetchone()
            
            if result:
                return result[0]
            return default_value
        except sqlite3.Error as e:
            logger.error(f"Error getting setting {key}: {e}")
            return default_value
        finally:
            if conn:
                conn.close()
                
    def save_user_profile(self, nickname: str, username: str = None, realname: str = None) -> bool:
        """
        Save user profile to database.
        
        Args:
            nickname: User nickname
            username: Username (uses nickname if empty)
            realname: Real name (uses nickname if empty)
            
        Returns:
            True if successful, False otherwise
        """
        if not username:
            username = nickname
            
        if not realname:
            realname = nickname
            
        try:
            result1 = self.save_user_setting("nickname", nickname)
            result2 = self.save_user_setting("username", username)
            result3 = self.save_user_setting("realname", realname)
            
            return result1 and result2 and result3
        except Exception as e:
            logger.error(f"Error saving user profile: {e}")
            return False
            
    def get_user_profile(self) -> Dict[str, str]:
        """
        Get user profile from database.
        
        Returns:
            Dictionary with profile settings
        """
        try:
            nickname = self.get_user_setting("nickname", f"TesseractIRC_{random.randint(100000, 999999)}")
            username = self.get_user_setting("username", nickname)
            realname = self.get_user_setting("realname", nickname)
            
            return {
                "nickname": nickname,
                "username": username,
                "realname": realname
            }
        except Exception as e:
            logger.error(f"Error getting user profile: {e}")
            return {
                "nickname": f"TesseractIRC_{random.randint(100000, 999999)}",
                "username": f"TesseractIRC_{random.randint(100000, 999999)}",
                "realname": f"TesseractIRC_{random.randint(100000, 999999)}"
            }