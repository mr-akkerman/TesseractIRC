import os
import sys
import importlib.util

# Load DatabaseManager directly to avoid heavy optional imports from package
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

db_path = os.path.join(PROJECT_ROOT, "irc_client", "backend", "database.py")
spec = importlib.util.spec_from_file_location("database", db_path)
database = importlib.util.module_from_spec(spec)
spec.loader.exec_module(database)  # type: ignore
DatabaseManager = database.DatabaseManager


def test_save_and_load_servers_channels(tmp_path):
    db_file = tmp_path / "test.db"
    db = DatabaseManager(str(db_file))

    # Save server and channel
    assert db.save_server("irc.example.com", 6667, "nick", "user", "Real")
    assert db.save_channel("irc.example.com", "#general")

    # Retrieve stored servers
    servers = db.get_all_servers()
    assert len(servers) == 1
    server = servers[0]
    assert server["server"] == "irc.example.com"
    assert server["port"] == 6667
    assert server["nickname"] == "nick"
    assert server["username"] == "user"
    assert server["realname"] == "Real"

    # Retrieve stored channels
    channels = db.get_channels_for_server("irc.example.com")
    assert len(channels) == 1
    channel = channels[0]
    assert channel["name"] == "#general"
    assert channel["is_private"] is False
    assert channel["auto_join"] is True


def test_user_settings_and_profile(tmp_path):
    db_file = tmp_path / "settings.db"
    db = DatabaseManager(str(db_file))

    # Save and load user setting
    assert db.save_user_setting("theme", "dark")
    assert db.get_user_setting("theme") == "dark"
    assert db.get_user_setting("nonexistent", "default") == "default"

    # Save and load user profile
    assert db.save_user_profile("Nick", "User", "Real")
    profile = db.get_user_profile()
    assert profile == {"nickname": "Nick", "username": "User", "realname": "Real"}


