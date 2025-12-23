"""Variable manager for Atlas proxy.

Manages persistent variable storage with atomic writes and backup support.
"""

import json
import logging
import os
import re
import shutil
from pathlib import Path
from typing import Dict, Any

logger = logging.getLogger(__name__)


class VariableManager:
    """Manages persistent variable storage with atomic writes."""

    def __init__(self, data_dir: str):
        """Initialize VariableManager instance.
        
        Args:
            data_dir: Base data directory path where variables.json is stored.
        """
        self.data_dir = Path(data_dir)
        self.variables_file = self.data_dir / "variables.json"
        self.backup_file = self.data_dir / "variables.json.backup"

    def load_variables(self) -> Dict[str, Any]:
        """Load variables from variables.json.
        
        Returns:
            Dictionary of variables. Returns empty dict if file is missing or invalid.
        """
        if not self.variables_file.exists():
            logger.debug(f"Variables file not found: {self.variables_file}")
            return {}

        try:
            with open(self.variables_file, 'r', encoding='utf-8') as f:
                variables = json.load(f)
                if not isinstance(variables, dict):
                    logger.warning(f"Variables file contains non-dict data: {self.variables_file}")
                    return {}
                return variables
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in variables file {self.variables_file}: {e}")
            return {}
        except IOError as e:
            logger.error(f"Error reading variables file {self.variables_file}: {e}")
            return {}

    def save_variables(self, variables: Dict[str, Any]) -> bool:
        """Save variables atomically with backup.
        
        Uses atomic write pattern: write to temp file, then rename.
        Creates backup before saving.
        
        Args:
            variables: Dictionary of variables to save.
            
        Returns:
            True if save succeeded, False otherwise.
        """
        if not isinstance(variables, dict):
            logger.error("Cannot save non-dict variables")
            return False

        # Ensure data directory exists
        try:
            self.data_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            logger.error(f"Error creating data directory {self.data_dir}: {e}")
            return False

        # Create backup if file exists
        if self.variables_file.exists():
            try:
                shutil.copy2(self.variables_file, self.backup_file)
            except (IOError, OSError) as e:
                logger.warning(f"Failed to create backup: {e}")
                # Continue anyway - backup failure shouldn't block save

        # Write to temp file first (atomic write pattern)
        temp_file = self.variables_file.with_suffix('.json.tmp')
        try:
            with open(temp_file, 'w', encoding='utf-8') as f:
                json.dump(variables, f, indent=2, ensure_ascii=False)
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
            temp_file.replace(self.variables_file)
            logger.debug(f"Successfully saved variables to {self.variables_file}")
            return True
        except OSError as e:
            logger.error(f"Error renaming temp file to {self.variables_file}: {e}")
            # Clean up temp file
            if temp_file.exists():
                try:
                    temp_file.unlink()
                except OSError:
                    pass
            return False

    def format_for_prompt(self, variables: Dict[str, Any]) -> str:
        """Format variables for inclusion in prompts.
        
        Excludes _metadata key from output.
        Formats as "**Variables**: x=10, y=3"
        
        Args:
            variables: Dictionary of variables to format.
            
        Returns:
            Formatted string for prompt inclusion.
        """
        if not variables:
            return "**Variables**: (none)"

        # Filter out metadata
        filtered = {k: v for k, v in variables.items() if k != "_metadata"}
        
        if not filtered:
            return "**Variables**: (none)"

        # Format as key=value pairs
        pairs = [f"{k}={v}" for k, v in sorted(filtered.items())]
        return f"**Variables**: {', '.join(pairs)}"

    def parse_updates(self, response: str) -> Dict[str, Any]:
        """Parse variable assignments from Atlas response text.
        
        Handles various formats:
        - "x = 10" or "x equals 10"
        - "set y to 3"
        - "remember z is 5"
        - "x=10" (no spaces)
        
        Args:
            response: Text response from Atlas that may contain variable assignments.
            
        Returns:
            Dictionary of parsed variable assignments, e.g. {"x": 10, "y": 3}
        """
        updates = {}
        
        # Pattern 1: "x = 10" or "x equals 10" or "x=10" (no spaces)
        # Value pattern: numbers (including decimals), or word characters
        # Use word boundary and require value to be followed by punctuation/space/end
        # Space after operator is optional for "=" but required for "equals"/"is"
        pattern1 = r'\b(\w+)\s*(?:=\s*|equals\s+|is\s+)([0-9]+(?:\.[0-9]+)?|\w+)(?=[\s,;.]|$)'
        matches = re.finditer(pattern1, response, re.IGNORECASE)
        for match in matches:
            var_name = match.group(1)
            var_value = match.group(2)
            # Filter out false matches: if using "equals" or "is", only accept numeric values
            # or if the pattern contains "=" (more specific)
            operator = match.group(0)[len(var_name):].strip().split()[0] if ' ' in match.group(0)[len(var_name):] else '='
            if operator == '=' or var_value.replace('.', '').replace('-', '').isdigit():
                updates[var_name] = self._parse_value(var_value)

        # Pattern 2: "set x to 10" or "set x to value"
        pattern2 = r'\bset\s+(\w+)\s+to\s+([0-9]+(?:\.[0-9]+)?|\w+)(?=[\s,;.]|$)'
        matches = re.finditer(pattern2, response, re.IGNORECASE)
        for match in matches:
            var_name = match.group(1)
            var_value = match.group(2)
            updates[var_name] = self._parse_value(var_value)

        # Pattern 3: "remember x is 10" or "remember x is value"
        pattern3 = r'\bremember\s+(\w+)\s+is\s+([0-9]+(?:\.[0-9]+)?|\w+)(?=[\s,;.]|$)'
        matches = re.finditer(pattern3, response, re.IGNORECASE)
        for match in matches:
            var_name = match.group(1)
            var_value = match.group(2)
            updates[var_name] = self._parse_value(var_value)

        return updates

    def _parse_value(self, value_str: str) -> Any:
        """Parse a string value into appropriate Python type.
        
        Tries to parse as int, then float, then bool, then returns as string.
        
        Args:
            value_str: String representation of value.
            
        Returns:
            Parsed value (int, float, bool, or str).
        """
        value_str = value_str.strip()
        
        # Try integer
        try:
            return int(value_str)
        except ValueError:
            pass
        
        # Try float
        try:
            return float(value_str)
        except ValueError:
            pass
        
        # Try boolean
        lower = value_str.lower()
        if lower in ('true', 'yes', 'on', '1'):
            return True
        if lower in ('false', 'no', 'off', '0'):
            return False
        
        # Return as string
        return value_str

