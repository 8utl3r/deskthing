"""Context injector for Atlas proxy.

Loads file context and injects it into prompts along with variables.
"""

import logging
import os
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional

logger = logging.getLogger(__name__)


class ContextInjector:
    """Loads file context and injects it into prompts."""

    def __init__(self, files_dir: str, max_context_size: int = 2000, cache_ttl: int = 60):
        """Initialize ContextInjector instance.
        
        Args:
            files_dir: Base directory path where files are stored.
            max_context_size: Maximum context size in characters (default: 2000).
            cache_ttl: Cache time-to-live in seconds (default: 60).
        """
        self.files_dir = Path(files_dir).resolve()
        self.max_context_size = max_context_size
        self.cache_ttl = cache_ttl
        
        # Cache for file context
        self._cached_context: Optional[Dict[str, Any]] = None
        self._cache_timestamp: float = 0
        
        # Ensure files directory exists
        try:
            self.files_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            logger.error(f"Error creating files directory {self.files_dir}: {e}")

    def load_file_context(self, force_refresh: bool = False) -> Dict[str, Any]:
        """Load file structure and metadata.
        
        Uses caching to avoid frequent filesystem scans. Cache refreshes every
        cache_ttl seconds.
        
        Collects:
        - Directory structure (tree format)
        - File listings (organized by directory)
        - Recent files (sorted by modification time)
        
        Args:
            force_refresh: If True, bypass cache and reload context.
        
        Returns:
            Dictionary with "directory_structure", "file_listings", and "recent_files" keys.
        """
        # Check cache
        current_time = time.time()
        if not force_refresh and self._cached_context is not None:
            if current_time - self._cache_timestamp < self.cache_ttl:
                logger.debug("Returning cached file context")
                return self._cached_context
        
        context = {
            "directory_structure": [],
            "file_listings": {},
            "recent_files": []
        }
        
        if not self.files_dir.exists():
            logger.debug(f"Files directory does not exist: {self.files_dir}")
            return context
        
        try:
            # Build directory structure
            context["directory_structure"] = self._build_directory_structure(self.files_dir)
            
            # Build file listings by directory
            context["file_listings"] = self._build_file_listings(self.files_dir)
            
            # Get recent files
            context["recent_files"] = self._get_recent_files(self.files_dir)
            
            # Update cache
            self._cached_context = context
            self._cache_timestamp = current_time
            
        except Exception as e:
            logger.error(f"Error loading file context: {e}")
        
        return context

    def _build_directory_structure(self, root_dir: Path, prefix: str = "", is_last: bool = True) -> List[str]:
        """Build directory structure in tree format.
        
        Args:
            root_dir: Root directory to traverse.
            prefix: Prefix for tree visualization.
            is_last: Whether this is the last item at this level.
            
        Returns:
            List of directory structure lines.
        """
        lines = []
        
        try:
            # Get directories only
            dirs = sorted([d for d in root_dir.iterdir() if d.is_dir()], key=lambda x: x.name)
            
            for i, dir_path in enumerate(dirs):
                is_last_dir = (i == len(dirs) - 1)
                connector = "└── " if is_last_dir else "├── "
                lines.append(f"{prefix}{connector}{dir_path.name}/")
                
                # Recursively build subdirectories
                extension = "    " if is_last_dir else "│   "
                sub_lines = self._build_directory_structure(
                    dir_path,
                    prefix + extension,
                    is_last_dir
                )
                lines.extend(sub_lines)
        
        except PermissionError:
            logger.debug(f"Permission denied accessing {root_dir}")
        except Exception as e:
            logger.debug(f"Error building directory structure for {root_dir}: {e}")
        
        return lines

    def _build_file_listings(self, root_dir: Path) -> Dict[str, List[Dict[str, Any]]]:
        """Build file listings organized by directory.
        
        Args:
            root_dir: Root directory to traverse.
            
        Returns:
            Dictionary mapping directory paths to lists of file info dicts.
        """
        listings = {}
        
        try:
            # Walk through all directories
            for dir_path in root_dir.rglob('*'):
                if dir_path.is_dir():
                    files = []
                    for file_path in sorted(dir_path.iterdir()):
                        if file_path.is_file():
                            try:
                                stat = file_path.stat()
                                rel_path = file_path.relative_to(self.files_dir)
                                files.append({
                                    "name": file_path.name,
                                    "path": str(rel_path),
                                    "size": stat.st_size,
                                    "modified": stat.st_mtime
                                })
                            except (OSError, ValueError) as e:
                                logger.debug(f"Error getting file info for {file_path}: {e}")
                    
                    if files:
                        rel_dir = dir_path.relative_to(self.files_dir)
                        listings[str(rel_dir)] = files
        
        except Exception as e:
            logger.error(f"Error building file listings: {e}")
        
        return listings

    def _get_recent_files(self, root_dir: Path, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent files sorted by modification time.
        
        Args:
            root_dir: Root directory to search.
            limit: Maximum number of recent files to return.
            
        Returns:
            List of file info dicts sorted by modification time (most recent first).
        """
        recent_files = []
        current_time = time.time()
        
        try:
            for file_path in root_dir.rglob('*'):
                if file_path.is_file():
                    try:
                        stat = file_path.stat()
                        rel_path = file_path.relative_to(self.files_dir)
                        mtime = stat.st_mtime
                        recent_files.append({
                            "name": file_path.name,
                            "path": str(rel_path),
                            "size": stat.st_size,
                            "modified": mtime,
                            "relative_time": self._format_relative_time(current_time - mtime)
                        })
                    except (OSError, ValueError):
                        continue
            
            # Sort by modification time (most recent first)
            recent_files.sort(key=lambda x: x["modified"], reverse=True)
            recent_files = recent_files[:limit]
            
        except Exception as e:
            logger.error(f"Error getting recent files: {e}")
        
        return recent_files

    def _format_relative_time(self, seconds: float) -> str:
        """Format time difference as relative time string.
        
        Args:
            seconds: Time difference in seconds.
            
        Returns:
            Relative time string like "2 hours ago", "5 minutes ago", etc.
        """
        if seconds < 60:
            return "just now"
        elif seconds < 3600:
            minutes = int(seconds / 60)
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        elif seconds < 86400:
            hours = int(seconds / 3600)
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        elif seconds < 604800:
            days = int(seconds / 86400)
            return f"{days} day{'s' if days != 1 else ''} ago"
        elif seconds < 2592000:
            weeks = int(seconds / 604800)
            return f"{weeks} week{'s' if weeks != 1 else ''} ago"
        elif seconds < 31536000:
            months = int(seconds / 2592000)
            return f"{months} month{'s' if months != 1 else ''} ago"
        else:
            years = int(seconds / 31536000)
            return f"{years} year{'s' if years != 1 else ''} ago"

    def format_context(self, file_context: Dict[str, Any], variables: Dict[str, Any]) -> str:
        """Format context for prompt inclusion.
        
        Combines file context and variables into a formatted string.
        Respects max_context_size limit.
        
        Args:
            file_context: Dictionary from load_file_context().
            variables: Dictionary of variables to include.
            
        Returns:
            Formatted context string for prompt inclusion.
        """
        parts = []
        
        # Format directory structure
        if file_context.get("directory_structure"):
            parts.append("**Directory Structure:**")
            parts.append("```")
            parts.extend(file_context["directory_structure"])
            parts.append("```")
        
        # Format file listings
        if file_context.get("file_listings"):
            parts.append("\n**File Listings:**")
            for dir_path, files in sorted(file_context["file_listings"].items()):
                parts.append(f"\n{dir_path}/")
                for file_info in files:
                    size_kb = file_info["size"] / 1024
                    parts.append(f"  - {file_info['name']} ({size_kb:.1f} KB)")
        
        # Format recent files
        if file_context.get("recent_files"):
            parts.append("\n**Recent Files:**")
            for file_info in file_context["recent_files"]:
                rel_path = file_info["path"]
                relative_time = file_info.get("relative_time", "")
                if relative_time:
                    parts.append(f"  - {rel_path} ({relative_time})")
                else:
                    parts.append(f"  - {rel_path}")
        
        # Format variables
        if variables:
            # Filter out metadata
            filtered = {k: v for k, v in variables.items() if k != "_metadata"}
            if filtered:
                parts.append("\n**Variables:**")
                pairs = [f"{k}={v}" for k, v in sorted(filtered.items())]
                parts.append(", ".join(pairs))
        
        context_str = "\n".join(parts)
        
        # Truncate if exceeds max_context_size
        if len(context_str) > self.max_context_size:
            context_str = context_str[:self.max_context_size]
            # Try to truncate at a reasonable boundary
            last_newline = context_str.rfind('\n')
            if last_newline > self.max_context_size * 0.8:  # If we can find a newline in the last 20%
                context_str = context_str[:last_newline]
            context_str += "\n\n[... context truncated ...]"
        
        return context_str

    def inject_into_messages(self, messages: List[Dict[str, Any]], context: str) -> List[Dict[str, Any]]:
        """Inject context into message list.
        
        Injects context into the first user message, or creates a system message
        if no user message exists. If a system message already exists, prepends
        context to it.
        
        Args:
            messages: List of message dicts with "role" and "content" keys.
            context: Formatted context string to inject.
            
        Returns:
            New list of messages with context injected.
        """
        if not context or not context.strip():
            return messages.copy()
        
        # Create new messages list
        new_messages = []
        context_injected = False
        
        # Find first user message
        for i, msg in enumerate(messages):
            if msg.get("role") == "user" and not context_injected:
                # Inject context into first user message
                existing_content = msg.get("content", "")
                new_content = f"{context}\n\n{existing_content}".strip()
                new_messages.append({
                    "role": "user",
                    "content": new_content
                })
                context_injected = True
            else:
                # Check if this is a system message and we haven't injected yet
                if msg.get("role") == "system" and not context_injected:
                    # Prepend context to existing system message
                    existing_content = msg.get("content", "")
                    new_content = f"{context}\n\n{existing_content}".strip()
                    new_messages.append({
                        "role": "system",
                        "content": new_content
                    })
                    context_injected = True
                else:
                    # Add message as-is
                    new_messages.append(msg)
        
        # If no user or system message found, create system message at start
        if not context_injected:
            new_messages.insert(0, {
                "role": "system",
                "content": context
            })
        
        return new_messages

