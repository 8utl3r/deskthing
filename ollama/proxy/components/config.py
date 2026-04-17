"""Configuration manager for Atlas proxy.

Reads settings from:
1. Environment variables (highest priority, ATLAS_ prefix)
2. Optional config file (JSON format)
3. Default values (lowest priority)
"""

import os
import json
from pathlib import Path
from typing import List, Optional


class Config:
    """Configuration manager with environment variable, file, and default support."""

    def __init__(self, config_file: Optional[str] = None):
        """Initialize Config instance.
        
        Args:
            config_file: Optional path to JSON config file. If None, looks for
                        config.json in the proxy directory.
        """
        self._config_file = config_file
        self._file_config = self._load_config_file()
        self._data_dir = None  # Will be computed on first access

    def _load_config_file(self) -> dict:
        """Load configuration from JSON file if it exists."""
        if self._config_file is None:
            # Default to config.json in proxy directory
            proxy_dir = Path(__file__).parent.parent
            config_path = proxy_dir / "config.json"
        else:
            config_path = Path(self._config_file)

        if not config_path.exists():
            return {}

        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {}

    def _get_env(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """Get environment variable with ATLAS_ prefix."""
        env_key = f"ATLAS_{key.upper()}"
        return os.environ.get(env_key, default)

    def _get_value(self, key: str, default):
        """Get value from env vars, config file, or default (in priority order)."""
        # Check environment variable first
        env_value = self._get_env(key)
        if env_value is not None:
            # Type conversion based on default type
            if isinstance(default, int):
                try:
                    return int(env_value)
                except ValueError:
                    return default
            elif isinstance(default, list):
                # For lists, expect JSON string or comma-separated values
                try:
                    return json.loads(env_value)
                except (json.JSONDecodeError, TypeError):
                    # Fallback to comma-separated
                    return [item.strip() for item in env_value.split(',')]
            elif isinstance(default, bool):
                return env_value.lower() in ('true', '1', 'yes', 'on')
            return env_value

        # Check config file
        if key in self._file_config:
            return self._file_config[key]

        # Return default
        return default

    @property
    def ollama_url(self) -> str:
        """Ollama API URL."""
        return self._get_value("ollama_url", "http://localhost:11434")

    @property
    def proxy_port(self) -> int:
        """Proxy server port."""
        return self._get_value("proxy_port", 11435)

    @property
    def data_dir(self) -> str:
        """Base data directory path."""
        if self._data_dir is None:
            default_path = os.path.expanduser("~/dotfiles/ollama/data")
            self._data_dir = self._get_value("data_dir", default_path)
            # Expand user even if from config file
            self._data_dir = os.path.expanduser(self._data_dir)
        return self._data_dir

    @property
    def files_dir(self) -> str:
        """Files directory path."""
        files_path = self._get_value("files_dir", None)
        if files_path is None:
            return os.path.join(self.data_dir, "files")
        return os.path.expanduser(files_path)

    @property
    def history_dir(self) -> str:
        """History directory path."""
        history_path = self._get_value("history_dir", None)
        if history_path is None:
            return os.path.join(self.data_dir, "history")
        return os.path.expanduser(history_path)

    @property
    def allowed_extensions(self) -> List[str]:
        """List of allowed file extensions."""
        return self._get_value("allowed_extensions", [".txt", ".md"])

    @property
    def max_file_size(self) -> int:
        """Maximum file size in bytes."""
        return self._get_value("max_file_size", 10485760)

    @property
    def max_context_size(self) -> int:
        """Maximum context size in characters (used when dynamic_context=False).
        
        Default: 2000 (conservative, but too small for practical RAG)
        Recommended: 10000-20000 for referencing full files or substantial sections.
        Can be set via ATLAS_MAX_CONTEXT_SIZE environment variable.
        Note: Ignored if dynamic_context=True (default).
        """
        return self._get_value("max_context_size", 2000)
    
    @property
    def max_context_tokens(self) -> int:
        """Total context window size in tokens.
        
        Default: 32768 (from Modelfile)
        Can be set via ATLAS_MAX_CONTEXT_TOKENS environment variable.
        Used for dynamic context size calculation.
        """
        return self._get_value("max_context_tokens", 32768)
    
    @property
    def dynamic_context(self) -> bool:
        """Whether to use dynamic context sizing.
        
        Default: True (automatically calculates available space)
        Can be set via ATLAS_DYNAMIC_CONTEXT environment variable.
        When True, max_context_size is ignored and context size is calculated
        based on available space in the context window.
        """
        return self._get_value("dynamic_context", True)

    @property
    def log_retention_days(self) -> int:
        """Log retention period in days."""
        return self._get_value("log_retention_days", 30)

    @property
    def qdrant_url(self) -> Optional[str]:
        """Qdrant API URL (e.g., http://192.168.0.158:6333).
        
        If None, RAG features are disabled.
        """
        return self._get_value("qdrant_url", None)

    @property
    def qdrant_collection(self) -> str:
        """Qdrant collection name for storing vectors."""
        return self._get_value("qdrant_collection", "atlas_conversations")

    @property
    def embedding_model(self) -> str:
        """Ollama embedding model name."""
        return self._get_value("embedding_model", "nomic-embed-text")

    @property
    def rag_enabled(self) -> bool:
        """Whether RAG is enabled (requires qdrant_url to be set)."""
        return self.qdrant_url is not None

