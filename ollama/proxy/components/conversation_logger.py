"""Conversation logger for Atlas proxy.

Logs user queries, Atlas responses, executed commands, and variable updates
to daily JSON files with automatic cleanup of old logs.
"""

import json
import logging
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any

logger = logging.getLogger(__name__)


class ConversationLogger:
    """Logs conversations to daily JSON files with retention management."""

    def __init__(self, history_dir: str, retention_days: int = 30):
        """Initialize ConversationLogger instance.
        
        Args:
            history_dir: Directory path where daily log files are stored.
            retention_days: Number of days to retain logs before cleanup.
        """
        self.history_dir = Path(history_dir)
        self.retention_days = retention_days
        
        # Ensure history directory exists
        try:
            self.history_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            logger.error(f"Error creating history directory {self.history_dir}: {e}")

    def _get_daily_file(self, date: Optional[datetime] = None) -> Path:
        """Get the log file path for a given date.
        
        Args:
            date: Date to get file for. If None, uses current date.
            
        Returns:
            Path to the daily log file (YYYY-MM-DD.json format).
        """
        if date is None:
            date = datetime.utcnow()
        filename = date.strftime("%Y-%m-%d.json")
        return self.history_dir / filename

    def _load_daily_logs(self, date: Optional[datetime] = None) -> List[Dict[str, Any]]:
        """Load logs from a daily file.
        
        Args:
            date: Date to load logs for. If None, uses current date.
            
        Returns:
            List of conversation entries. Returns empty list if file doesn't exist or is invalid.
        """
        log_file = self._get_daily_file(date)
        
        if not log_file.exists():
            return []
        
        try:
            with open(log_file, 'r', encoding='utf-8') as f:
                logs = json.load(f)
                if not isinstance(logs, list):
                    logger.warning(f"Log file {log_file} contains non-list data")
                    return []
                return logs
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in log file {log_file}: {e}")
            return []
        except IOError as e:
            logger.error(f"Error reading log file {log_file}: {e}")
            return []

    def _save_daily_logs(self, logs: List[Dict[str, Any]], date: Optional[datetime] = None) -> bool:
        """Save logs to a daily file atomically.
        
        Uses atomic write pattern: write to temp file, then rename.
        
        Args:
            logs: List of conversation entries to save.
            date: Date to save logs for. If None, uses current date.
            
        Returns:
            True if save succeeded, False otherwise.
        """
        if not isinstance(logs, list):
            logger.error("Cannot save non-list logs")
            return False
        
        log_file = self._get_daily_file(date)
        
        # Ensure history directory exists
        try:
            self.history_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            logger.error(f"Error creating history directory {self.history_dir}: {e}")
            return False
        
        # Write to temp file first (atomic write pattern)
        temp_file = log_file.with_suffix('.json.tmp')
        try:
            with open(temp_file, 'w', encoding='utf-8') as f:
                json.dump(logs, f, indent=2, ensure_ascii=False)
                f.flush()
                os.fsync(f.fileno())  # Ensure data is written to disk
        except (IOError, OSError) as e:
            logger.error(f"Error writing temp file {temp_file}: {e}")
            # Clean up temp file if it exists
            if temp_file.exists():
                try:
                    temp_file.unlink()
                except OSError:
                    pass
            return False
        
        # Atomic rename: temp file -> final file
        try:
            temp_file.replace(log_file)
            logger.debug(f"Successfully saved logs to {log_file}")
            return True
        except OSError as e:
            logger.error(f"Error renaming temp file to {log_file}: {e}")
            # Clean up temp file
            if temp_file.exists():
                try:
                    temp_file.unlink()
                except OSError:
                    pass
            return False

    def log_conversation(
        self,
        user_query: str,
        atlas_response: str,
        commands_executed: List[Dict[str, Any]],
        variables_used: Optional[List[str]] = None,
        variables_updated: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Log a conversation entry to the daily log file.
        
        Args:
            user_query: The user's query/request.
            atlas_response: Atlas's response text.
            commands_executed: List of command dictionaries with type, path, success, message.
            variables_used: Optional list of variable names that were used.
            variables_updated: Optional dictionary of variable updates.
            
        Returns:
            True if logging succeeded, False otherwise.
        """
        # Create conversation entry
        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "user": user_query,
            "atlas": atlas_response,
            "commands": commands_executed or [],
            "variables_used": variables_used or [],
            "variables_updated": variables_updated or {}
        }
        
        # Load existing logs for today
        logs = self._load_daily_logs()
        
        # Append new entry
        logs.append(entry)
        
        # Save back to file
        return self._save_daily_logs(logs)

    def get_recent_conversations(self, n: int = 10) -> List[Dict[str, Any]]:
        """Get the last N conversations across all log files.
        
        Searches backwards from today through log files until N conversations are found.
        
        Args:
            n: Number of recent conversations to retrieve.
            
        Returns:
            List of conversation entries, most recent first.
        """
        all_conversations = []
        current_date = datetime.utcnow()
        
        # Search backwards through dates until we have enough conversations
        # Limit search to retention_days to avoid scanning too many files
        for days_back in range(self.retention_days):
            date = current_date - timedelta(days=days_back)
            daily_logs = self._load_daily_logs(date)
            
            # Add conversations from this day (most recent first within the day)
            all_conversations.extend(reversed(daily_logs))
            
            # Stop if we have enough
            if len(all_conversations) >= n:
                break
        
        # Return the most recent N conversations
        return all_conversations[:n]

    def cleanup_old_logs(self) -> int:
        """Delete log files older than retention_days.
        
        Returns:
            Number of files deleted.
        """
        if not self.history_dir.exists():
            return 0
        
        cutoff_date = datetime.utcnow() - timedelta(days=self.retention_days)
        deleted_count = 0
        
        try:
            # Iterate through all JSON files in history directory
            for log_file in self.history_dir.glob("*.json"):
                # Skip temp files
                if log_file.suffixes == ['.json', '.tmp']:
                    continue
                
                # Parse date from filename (YYYY-MM-DD.json)
                try:
                    file_date_str = log_file.stem  # Gets filename without .json
                    file_date = datetime.strptime(file_date_str, "%Y-%m-%d")
                    
                    # Delete if older than cutoff
                    if file_date < cutoff_date:
                        try:
                            log_file.unlink()
                            deleted_count += 1
                            logger.debug(f"Deleted old log file: {log_file}")
                        except OSError as e:
                            logger.warning(f"Error deleting log file {log_file}: {e}")
                except ValueError:
                    # Filename doesn't match expected format, skip it
                    logger.debug(f"Skipping file with unexpected format: {log_file}")
                    continue
        
        except OSError as e:
            logger.error(f"Error scanning history directory {self.history_dir}: {e}")
        
        if deleted_count > 0:
            logger.info(f"Cleaned up {deleted_count} old log file(s)")
        
        return deleted_count




