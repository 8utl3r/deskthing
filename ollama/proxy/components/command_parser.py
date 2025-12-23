"""Command parser for Atlas proxy.

Parses structured FILE_* commands and variable assignments from Atlas responses.
"""

import logging
import re
from typing import Dict, List, Any

logger = logging.getLogger(__name__)


class CommandParser:
    """Parses structured commands from Atlas response text."""

    # Pattern for FILE_* commands
    # Matches: **FILE_COMMAND** path "content" or **FILE_COMMAND** path
    FILE_COMMAND_PATTERN = re.compile(
        r'\*\*FILE_(\w+)\*\*\s+([^\s"*]+|"[^"]*(?:\\.[^"]*)*")\s*(?:"([^"]*(?:\\.[^"]*)*)")?',
        re.MULTILINE | re.DOTALL
    )

    # Patterns for variable assignments
    VAR_PATTERN_EQUALS = re.compile(
        r'\b(\w+)\s*(?:=\s*|equals\s+|is\s+)([0-9]+(?:\.[0-9]+)?|\w+)(?=[\s,;.]|$)',
        re.IGNORECASE
    )
    VAR_PATTERN_SET = re.compile(
        r'\bset\s+(\w+)\s+to\s+([0-9]+(?:\.[0-9]+)?|\w+)(?=[\s,;.]|$)',
        re.IGNORECASE
    )
    VAR_PATTERN_REMEMBER = re.compile(
        r'\bremember\s+(\w+)\s+is\s+([0-9]+(?:\.[0-9]+)?|\w+)(?=[\s,;.]|$)',
        re.IGNORECASE
    )

    def parse_file_commands(self, response: str) -> List[Dict[str, Any]]:
        """Parse all FILE_* commands from response text.
        
        Args:
            response: Text response that may contain FILE_* commands.
            
        Returns:
            List of command dictionaries, each with:
            - "type": command type (CREATE, READ, etc.)
            - "path": file path
            - "content": content string (if applicable)
            - "old_path": source path (for MOVE/COPY)
            - "new_path": destination path (for MOVE/COPY)
            - "src_path": source path (for COPY)
            - "dst_path": destination path (for COPY)
            - "directory": directory path (for SEARCH/LIST)
            - "term": search term (for SEARCH)
        """
        commands = []
        
        # Find all FILE_* command markers
        pattern = r'\*\*FILE_(\w+)\*\*'
        matches = list(re.finditer(pattern, response))
        
        for match in matches:
            cmd_type = match.group(1).upper()
            start_pos = match.end()
            
            # Extract arguments after the command marker
            remaining = response[start_pos:]
            
            # Parse path and optional content/second argument
            # Handle quoted strings (including multi-line) and unquoted paths
            path_or_first = None
            content_or_second = None
            
            # Skip whitespace
            remaining = remaining.lstrip()
            if not remaining:
                continue
            
            # Parse first argument (path)
            if remaining.startswith('"'):
                # Quoted string - find closing quote (handling escaped quotes)
                path_end = self._find_closing_quote(remaining, 1)
                if path_end == -1:
                    # Unclosed quote - take rest of line or reasonable amount
                    path_end = len(remaining)
                path_or_first = remaining[1:path_end]
                remaining = remaining[path_end + 1:].lstrip()
            else:
                # Unquoted path - take until space (but not if space is before a quote)
                # Look for space, but if there's a quote before the space, stop before quote
                space_idx = remaining.find(' ')
                quote_idx = remaining.find('"')
                
                if quote_idx != -1:
                    # There's a quote - path ends before the quote
                    if space_idx == -1 or space_idx > quote_idx:
                        # Quote comes before space, path ends before quote
                        path_end = quote_idx
                    else:
                        # Space comes before quote, path ends at space
                        path_end = space_idx
                elif space_idx != -1:
                    # No quote, but there's a space
                    path_end = space_idx
                else:
                    # No space, no quote - take everything
                    path_end = len(remaining)
                
                path_or_first = remaining[:path_end].rstrip()
                remaining = remaining[path_end:].lstrip()
            
            # Parse second argument (content or destination path) if present
            if remaining.startswith('"'):
                # Quoted string - find closing quote (handling escaped quotes)
                content_end = self._find_closing_quote(remaining, 1)
                if content_end == -1:
                    # Unclosed quote - take rest
                    content_end = len(remaining)
                content_or_second = remaining[1:content_end]
                remaining = remaining[content_end + 1:]
            elif remaining and not remaining.startswith('**'):
                # Unquoted second argument
                # Take until next FILE_ command or end
                next_cmd = remaining.find('**FILE_')
                if next_cmd != -1:
                    content_or_second = remaining[:next_cmd].rstrip()
                else:
                    content_or_second = remaining.rstrip()
            
            # Handle escaped quotes and newlines
            if path_or_first:
                path_or_first = path_or_first.replace('\\"', '"').replace('\\n', '\n')
            if content_or_second:
                content_or_second = content_or_second.replace('\\"', '"').replace('\\n', '\n')
            
            command = {"type": cmd_type}
            
            # Parse based on command type
            if cmd_type in ("CREATE", "UPDATE", "APPEND"):
                command["path"] = path_or_first
                command["content"] = content_or_second or ""
            elif cmd_type == "READ":
                command["path"] = path_or_first
            elif cmd_type == "DELETE":
                command["path"] = path_or_first
            elif cmd_type == "MOVE":
                command["old_path"] = path_or_first
                command["new_path"] = content_or_second or ""
            elif cmd_type == "COPY":
                command["src_path"] = path_or_first
                command["dst_path"] = content_or_second or ""
            elif cmd_type == "SEARCH":
                command["directory"] = path_or_first
                command["term"] = content_or_second or ""
            elif cmd_type == "LIST":
                command["directory"] = path_or_first
            elif cmd_type == "ARCHIVE":
                command["path"] = path_or_first
            else:
                logger.warning(f"Unknown FILE_ command type: {cmd_type}")
                continue
            
            commands.append(command)
        
        return commands
    
    def _find_closing_quote(self, text: str, start: int) -> int:
        """Find the closing quote in a string, handling escaped quotes.
        
        Args:
            text: Text to search in.
            start: Starting position (should be after opening quote).
            
        Returns:
            Position of closing quote, or -1 if not found.
        """
        i = start
        while i < len(text):
            if text[i] == '"':
                # Check if it's escaped
                if i > 0 and text[i-1] == '\\':
                    # Escaped quote - continue
                    i += 1
                    continue
                else:
                    # Found closing quote
                    return i
            i += 1
        return -1

    def parse_variable_commands(self, response: str) -> List[Dict[str, Any]]:
        """Parse variable assignments from response text.
        
        Handles formats:
        - "x = 10" or "x equals 10" or "x is 10"
        - "set y to 3"
        - "remember z is 5"
        
        Args:
            response: Text response that may contain variable assignments.
            
        Returns:
            List of variable assignment dictionaries, each with:
            - "name": variable name
            - "value": parsed value (int, float, bool, or str)
        """
        assignments = []
        
        # Pattern 1: "x = 10" or "x equals 10" or "x is 10" or "x=10"
        matches = self.VAR_PATTERN_EQUALS.finditer(response)
        for match in matches:
            var_name = match.group(1)
            var_value = match.group(2)
            # Filter out false matches - only accept if numeric or using "="
            operator_text = response[match.start():match.end()][len(var_name):].strip()
            if '=' in operator_text or var_value.replace('.', '').replace('-', '').isdigit():
                assignments.append({
                    "name": var_name,
                    "value": self._parse_value(var_value)
                })
        
        # Pattern 2: "set x to 10"
        matches = self.VAR_PATTERN_SET.finditer(response)
        for match in matches:
            var_name = match.group(1)
            var_value = match.group(2)
            assignments.append({
                "name": var_name,
                "value": self._parse_value(var_value)
            })
        
        # Pattern 3: "remember x is 10"
        matches = self.VAR_PATTERN_REMEMBER.finditer(response)
        for match in matches:
            var_name = match.group(1)
            var_value = match.group(2)
            assignments.append({
                "name": var_name,
                "value": self._parse_value(var_value)
            })
        
        # Remove duplicates (keep first occurrence)
        seen = set()
        unique_assignments = []
        for assignment in assignments:
            key = assignment["name"]
            if key not in seen:
                seen.add(key)
                unique_assignments.append(assignment)
        
        return unique_assignments

    def extract_commands(self, response: str) -> Dict[str, Any]:
        """Extract all commands from response and return structured data.
        
        Args:
            response: Text response that may contain commands.
            
        Returns:
            Dictionary with:
            - "file_commands": list of FILE_* command dicts
            - "variable_commands": list of variable assignment dicts
            - "clean_response": response text with commands removed
        """
        file_commands = self.parse_file_commands(response)
        variable_commands = self.parse_variable_commands(response)
        
        # Remove FILE_* commands from response
        clean_response = response
        pattern = r'\*\*FILE_(\w+)\*\*'
        matches = list(re.finditer(pattern, clean_response))
        
        # Process matches in reverse order to maintain positions
        for match in reversed(matches):
            start_pos = match.start()
            end_pos = match.end()
            
            # Find where this command ends (after parsing its arguments)
            remaining = clean_response[end_pos:]
            remaining = remaining.lstrip()
            
            # Skip first argument
            if remaining.startswith('"'):
                quote_end = self._find_closing_quote(remaining, 1)
                if quote_end != -1:
                    remaining = remaining[quote_end + 1:].lstrip()
                else:
                    remaining = remaining[len(remaining):]
            else:
                space_idx = remaining.find(' ')
                quote_idx = remaining.find('"')
                if quote_idx != -1 and (space_idx == -1 or quote_idx < space_idx):
                    quote_end = self._find_closing_quote(remaining, quote_idx + 1)
                    if quote_end != -1:
                        remaining = remaining[quote_end + 1:].lstrip()
                    else:
                        remaining = remaining[len(remaining):]
                elif space_idx != -1:
                    remaining = remaining[space_idx:].lstrip()
                else:
                    remaining = ""
            
            # Skip second argument if present
            if remaining.startswith('"'):
                quote_end = self._find_closing_quote(remaining, 1)
                if quote_end != -1:
                    end_pos = len(clean_response) - len(remaining) + quote_end + 1
                else:
                    end_pos = len(clean_response)
            elif remaining:
                # Find next FILE_ command or end of text
                next_cmd = remaining.find('**FILE_')
                if next_cmd != -1:
                    end_pos = len(clean_response) - len(remaining) + next_cmd
                else:
                    end_pos = len(clean_response)
            else:
                # No second argument, command ends after first argument
                end_pos = len(clean_response) - len(remaining)
            
            # Remove the command
            clean_response = clean_response[:start_pos] + clean_response[end_pos:]
        
        # Remove variable assignments from response
        # Remove equals pattern matches
        for match in reversed(list(self.VAR_PATTERN_EQUALS.finditer(clean_response))):
            operator_text = clean_response[match.start():match.end()][len(match.group(1)):].strip()
            if '=' in operator_text or match.group(2).replace('.', '').replace('-', '').isdigit():
                clean_response = clean_response[:match.start()] + clean_response[match.end():]
        
        # Remove set pattern matches
        for match in reversed(list(self.VAR_PATTERN_SET.finditer(clean_response))):
            clean_response = clean_response[:match.start()] + clean_response[match.end():]
        
        # Remove remember pattern matches
        for match in reversed(list(self.VAR_PATTERN_REMEMBER.finditer(clean_response))):
            clean_response = clean_response[:match.start()] + clean_response[match.end():]
        
        # Clean up extra whitespace
        clean_response = re.sub(r'\n\s*\n\s*\n+', '\n\n', clean_response)
        clean_response = clean_response.strip()
        
        return {
            "file_commands": file_commands,
            "variable_commands": variable_commands,
            "clean_response": clean_response
        }

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

