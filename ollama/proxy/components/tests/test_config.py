"""Tests for Config component."""

import os
import json
import tempfile
import pytest
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))
from components.config import Config


class TestConfigDefaults:
    """Test default configuration values."""

    def test_default_ollama_url(self):
        """Test default Ollama URL."""
        config = Config()
        assert config.ollama_url == "http://localhost:11434"

    def test_default_proxy_port(self):
        """Test default proxy port."""
        config = Config()
        assert config.proxy_port == 11435

    def test_default_data_dir(self):
        """Test default data directory expansion."""
        config = Config()
        expected = os.path.expanduser("~/dotfiles/ollama/data")
        assert config.data_dir == expected

    def test_default_files_dir(self):
        """Test default files directory."""
        config = Config()
        expected = os.path.join(config.data_dir, "files")
        assert config.files_dir == expected

    def test_default_history_dir(self):
        """Test default history directory."""
        config = Config()
        expected = os.path.join(config.data_dir, "history")
        assert config.history_dir == expected

    def test_default_allowed_extensions(self):
        """Test default allowed extensions."""
        config = Config()
        assert config.allowed_extensions == [".txt", ".md"]

    def test_default_max_file_size(self):
        """Test default max file size."""
        config = Config()
        assert config.max_file_size == 10485760  # 10MB

    def test_default_max_context_size(self):
        """Test default max context size."""
        config = Config()
        assert config.max_context_size == 2000

    def test_default_log_retention_days(self):
        """Test default log retention days."""
        config = Config()
        assert config.log_retention_days == 30


class TestConfigEnvironmentVariables:
    """Test environment variable overrides."""

    def setup_method(self):
        """Clear environment variables before each test."""
        env_vars = [
            "ATLAS_OLLAMA_URL",
            "ATLAS_PROXY_PORT",
            "ATLAS_DATA_DIR",
            "ATLAS_FILES_DIR",
            "ATLAS_HISTORY_DIR",
            "ATLAS_ALLOWED_EXTENSIONS",
            "ATLAS_MAX_FILE_SIZE",
            "ATLAS_MAX_CONTEXT_SIZE",
            "ATLAS_LOG_RETENTION_DAYS",
        ]
        for var in env_vars:
            if var in os.environ:
                del os.environ[var]

    def test_env_ollama_url(self):
        """Test environment variable override for Ollama URL."""
        os.environ["ATLAS_OLLAMA_URL"] = "http://custom:8080"
        config = Config()
        assert config.ollama_url == "http://custom:8080"

    def test_env_proxy_port(self):
        """Test environment variable override for proxy port."""
        os.environ["ATLAS_PROXY_PORT"] = "9999"
        config = Config()
        assert config.proxy_port == 9999

    def test_env_data_dir(self):
        """Test environment variable override for data directory."""
        os.environ["ATLAS_DATA_DIR"] = "~/custom/data"
        config = Config()
        expected = os.path.expanduser("~/custom/data")
        assert config.data_dir == expected

    def test_env_files_dir(self):
        """Test environment variable override for files directory."""
        os.environ["ATLAS_FILES_DIR"] = "/custom/files"
        config = Config()
        assert config.files_dir == "/custom/files"

    def test_env_history_dir(self):
        """Test environment variable override for history directory."""
        os.environ["ATLAS_HISTORY_DIR"] = "/custom/history"
        config = Config()
        assert config.history_dir == "/custom/history"

    def test_env_allowed_extensions_json(self):
        """Test environment variable override for allowed extensions (JSON)."""
        os.environ["ATLAS_ALLOWED_EXTENSIONS"] = '[".py", ".js"]'
        config = Config()
        assert config.allowed_extensions == [".py", ".js"]

    def test_env_allowed_extensions_comma(self):
        """Test environment variable override for allowed extensions (comma-separated)."""
        os.environ["ATLAS_ALLOWED_EXTENSIONS"] = ".py, .js, .ts"
        config = Config()
        assert config.allowed_extensions == [".py", ".js", ".ts"]

    def test_env_max_file_size(self):
        """Test environment variable override for max file size."""
        os.environ["ATLAS_MAX_FILE_SIZE"] = "20971520"
        config = Config()
        assert config.max_file_size == 20971520

    def test_env_max_context_size(self):
        """Test environment variable override for max context size."""
        os.environ["ATLAS_MAX_CONTEXT_SIZE"] = "5000"
        config = Config()
        assert config.max_context_size == 5000

    def test_env_log_retention_days(self):
        """Test environment variable override for log retention days."""
        os.environ["ATLAS_LOG_RETENTION_DAYS"] = "60"
        config = Config()
        assert config.log_retention_days == 60


class TestConfigFile:
    """Test config file overrides."""

    def test_config_file_ollama_url(self):
        """Test config file override for Ollama URL."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"ollama_url": "http://file:9000"}, f)
            config_path = f.name

        try:
            config = Config(config_file=config_path)
            assert config.ollama_url == "http://file:9000"
        finally:
            os.unlink(config_path)

    def test_config_file_proxy_port(self):
        """Test config file override for proxy port."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"proxy_port": 8888}, f)
            config_path = f.name

        try:
            config = Config(config_file=config_path)
            assert config.proxy_port == 8888
        finally:
            os.unlink(config_path)

    def test_config_file_data_dir(self):
        """Test config file override for data directory."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"data_dir": "~/test/data"}, f)
            config_path = f.name

        try:
            config = Config(config_file=config_path)
            expected = os.path.expanduser("~/test/data")
            assert config.data_dir == expected
        finally:
            os.unlink(config_path)

    def test_config_file_allowed_extensions(self):
        """Test config file override for allowed extensions."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"allowed_extensions": [".py", ".js", ".ts"]}, f)
            config_path = f.name

        try:
            config = Config(config_file=config_path)
            assert config.allowed_extensions == [".py", ".js", ".ts"]
        finally:
            os.unlink(config_path)

    def test_config_file_missing(self):
        """Test that missing config file doesn't cause errors."""
        config = Config(config_file="/nonexistent/path/config.json")
        # Should fall back to defaults
        assert config.ollama_url == "http://localhost:11434"

    def test_config_file_invalid_json(self):
        """Test that invalid JSON config file doesn't cause errors."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write("invalid json content {")
            config_path = f.name

        try:
            config = Config(config_file=config_path)
            # Should fall back to defaults
            assert config.ollama_url == "http://localhost:11434"
        finally:
            os.unlink(config_path)


class TestConfigPriority:
    """Test priority order: env vars > config file > defaults."""

    def setup_method(self):
        """Clear environment variables before each test."""
        if "ATLAS_OLLAMA_URL" in os.environ:
            del os.environ["ATLAS_OLLAMA_URL"]

    def test_env_overrides_file(self):
        """Test that environment variables override config file."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"ollama_url": "http://file:9000"}, f)
            config_path = f.name

        try:
            os.environ["ATLAS_OLLAMA_URL"] = "http://env:8080"
            config = Config(config_file=config_path)
            # Env var should win
            assert config.ollama_url == "http://env:8080"
        finally:
            os.unlink(config_path)
            if "ATLAS_OLLAMA_URL" in os.environ:
                del os.environ["ATLAS_OLLAMA_URL"]

    def test_file_overrides_default(self):
        """Test that config file overrides defaults."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"proxy_port": 7777}, f)
            config_path = f.name

        try:
            config = Config(config_file=config_path)
            # Config file should win over default
            assert config.proxy_port == 7777
        finally:
            os.unlink(config_path)


class TestPathExpansion:
    """Test path expansion functionality."""

    def test_tilde_expansion_data_dir(self):
        """Test that ~ is expanded in data_dir."""
        config = Config()
        assert "~" not in config.data_dir
        assert config.data_dir.startswith("/") or config.data_dir.startswith(os.path.expanduser("~"))

    def test_tilde_expansion_files_dir(self):
        """Test that ~ is expanded in files_dir when set."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"files_dir": "~/custom/files"}, f)
            config_path = f.name

        try:
            config = Config(config_file=config_path)
            assert "~" not in config.files_dir
            assert config.files_dir == os.path.expanduser("~/custom/files")
        finally:
            os.unlink(config_path)

    def test_tilde_expansion_history_dir(self):
        """Test that ~ is expanded in history_dir when set."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"history_dir": "~/custom/history"}, f)
            config_path = f.name

        try:
            config = Config(config_file=config_path)
            assert "~" not in config.history_dir
            assert config.history_dir == os.path.expanduser("~/custom/history")
        finally:
            os.unlink(config_path)

