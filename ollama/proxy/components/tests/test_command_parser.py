"""Tests for CommandParser component."""

import pytest
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))
from components.command_parser import CommandParser


class TestFileCommands:
    """Test FILE_* command parsing."""

    def test_parse_file_create(self):
        """Test FILE_CREATE command parsing."""
        parser = CommandParser()
        response = '**FILE_CREATE** path/to/file.txt "Hello, world!"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "CREATE"
        assert commands[0]["path"] == "path/to/file.txt"
        assert commands[0]["content"] == "Hello, world!"

    def test_parse_file_read(self):
        """Test FILE_READ command parsing."""
        parser = CommandParser()
        response = '**FILE_READ** path/to/file.txt'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "READ"
        assert commands[0]["path"] == "path/to/file.txt"

    def test_parse_file_update(self):
        """Test FILE_UPDATE command parsing."""
        parser = CommandParser()
        response = '**FILE_UPDATE** path/to/file.txt "Updated content"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "UPDATE"
        assert commands[0]["path"] == "path/to/file.txt"
        assert commands[0]["content"] == "Updated content"

    def test_parse_file_append(self):
        """Test FILE_APPEND command parsing."""
        parser = CommandParser()
        response = '**FILE_APPEND** path/to/file.txt "Appended text"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "APPEND"
        assert commands[0]["path"] == "path/to/file.txt"
        assert commands[0]["content"] == "Appended text"

    def test_parse_file_delete(self):
        """Test FILE_DELETE command parsing."""
        parser = CommandParser()
        response = '**FILE_DELETE** path/to/file.txt'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "DELETE"
        assert commands[0]["path"] == "path/to/file.txt"

    def test_parse_file_move(self):
        """Test FILE_MOVE command parsing."""
        parser = CommandParser()
        response = '**FILE_MOVE** old/path.txt "new/path.txt"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "MOVE"
        assert commands[0]["old_path"] == "old/path.txt"
        assert commands[0]["new_path"] == "new/path.txt"

    def test_parse_file_copy(self):
        """Test FILE_COPY command parsing."""
        parser = CommandParser()
        response = '**FILE_COPY** src/file.txt "dst/file.txt"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "COPY"
        assert commands[0]["src_path"] == "src/file.txt"
        assert commands[0]["dst_path"] == "dst/file.txt"

    def test_parse_file_search(self):
        """Test FILE_SEARCH command parsing."""
        parser = CommandParser()
        response = '**FILE_SEARCH** directory "search term"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "SEARCH"
        assert commands[0]["directory"] == "directory"
        assert commands[0]["term"] == "search term"

    def test_parse_file_list(self):
        """Test FILE_LIST command parsing."""
        parser = CommandParser()
        response = '**FILE_LIST** directory'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "LIST"
        assert commands[0]["directory"] == "directory"

    def test_parse_file_archive(self):
        """Test FILE_ARCHIVE command parsing."""
        parser = CommandParser()
        response = '**FILE_ARCHIVE** path/to/file.txt'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "ARCHIVE"
        assert commands[0]["path"] == "path/to/file.txt"

    def test_multiline_content(self):
        """Test FILE_CREATE with multi-line content."""
        parser = CommandParser()
        response = '''**FILE_CREATE** file.txt "Line 1
Line 2
Line 3"'''
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "CREATE"
        assert commands[0]["content"] == "Line 1\nLine 2\nLine 3"

    def test_escaped_quotes(self):
        """Test FILE_CREATE with escaped quotes."""
        parser = CommandParser()
        response = r'**FILE_CREATE** file.txt "He said \"Hello\""'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "CREATE"
        assert commands[0]["content"] == 'He said "Hello"'

    def test_escaped_newlines(self):
        """Test FILE_CREATE with escaped newlines."""
        parser = CommandParser()
        response = r'**FILE_CREATE** file.txt "Line 1\nLine 2"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["type"] == "CREATE"
        assert commands[0]["content"] == "Line 1\nLine 2"

    def test_multiple_commands(self):
        """Test parsing multiple FILE_* commands."""
        parser = CommandParser()
        response = '''**FILE_CREATE** file1.txt "Content 1"
**FILE_CREATE** file2.txt "Content 2"
**FILE_DELETE** file3.txt'''
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 3
        assert commands[0]["type"] == "CREATE"
        assert commands[0]["path"] == "file1.txt"
        assert commands[1]["type"] == "CREATE"
        assert commands[1]["path"] == "file2.txt"
        assert commands[2]["type"] == "DELETE"
        assert commands[2]["path"] == "file3.txt"

    def test_commands_mixed_with_text(self):
        """Test FILE_* commands mixed with regular text."""
        parser = CommandParser()
        response = '''Here is some text.
**FILE_CREATE** file.txt "Content"
More text here.
**FILE_DELETE** old.txt
End of text.'''
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 2
        assert commands[0]["type"] == "CREATE"
        assert commands[1]["type"] == "DELETE"

    def test_quoted_paths(self):
        """Test FILE_* commands with quoted paths."""
        parser = CommandParser()
        response = '**FILE_CREATE** "path with spaces/file.txt" "Content"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["path"] == "path with spaces/file.txt"
        assert commands[0]["content"] == "Content"


class TestVariableCommands:
    """Test variable assignment parsing."""

    def test_parse_equals_pattern(self):
        """Test variable assignment with equals."""
        parser = CommandParser()
        response = "x = 10"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "x"
        assert commands[0]["value"] == 10

    def test_parse_equals_no_spaces(self):
        """Test variable assignment without spaces."""
        parser = CommandParser()
        response = "x=10"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "x"
        assert commands[0]["value"] == 10

    def test_parse_equals_word(self):
        """Test variable assignment with equals and word."""
        response = "x equals 10"
        parser = CommandParser()
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "x"
        assert commands[0]["value"] == 10

    def test_parse_is_pattern(self):
        """Test variable assignment with 'is'."""
        parser = CommandParser()
        response = "x is 10"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "x"
        assert commands[0]["value"] == 10

    def test_parse_set_pattern(self):
        """Test variable assignment with 'set ... to'."""
        parser = CommandParser()
        response = "set y to 3"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "y"
        assert commands[0]["value"] == 3

    def test_parse_remember_pattern(self):
        """Test variable assignment with 'remember ... is'."""
        parser = CommandParser()
        response = "remember z is 5"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "z"
        assert commands[0]["value"] == 5

    def test_parse_float_value(self):
        """Test variable assignment with float value."""
        parser = CommandParser()
        response = "x = 3.14"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "x"
        assert commands[0]["value"] == 3.14

    def test_parse_string_value(self):
        """Test variable assignment with string value."""
        parser = CommandParser()
        response = "name = hello"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "name"
        assert commands[0]["value"] == "hello"

    def test_parse_boolean_true(self):
        """Test variable assignment with boolean true."""
        parser = CommandParser()
        response = "flag = true"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "flag"
        assert commands[0]["value"] is True

    def test_parse_boolean_false(self):
        """Test variable assignment with boolean false."""
        parser = CommandParser()
        response = "flag = false"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["name"] == "flag"
        assert commands[0]["value"] is False

    def test_multiple_variables(self):
        """Test parsing multiple variable assignments."""
        parser = CommandParser()
        response = "x = 10\ny = 20\nz = 30"
        commands = parser.parse_variable_commands(response)
        
        assert len(commands) == 3
        assert commands[0]["name"] == "x"
        assert commands[1]["name"] == "y"
        assert commands[2]["name"] == "z"

    def test_duplicate_variables(self):
        """Test that duplicate variable assignments are handled."""
        parser = CommandParser()
        response = "x = 10\nx = 20"
        commands = parser.parse_variable_commands(response)
        
        # Should keep first occurrence
        assert len(commands) == 1
        assert commands[0]["name"] == "x"
        assert commands[0]["value"] == 10


class TestExtractCommands:
    """Test extract_commands method."""

    def test_extract_file_and_variable_commands(self):
        """Test extracting both file and variable commands."""
        parser = CommandParser()
        response = '''**FILE_CREATE** file.txt "Content"
x = 10
y = 20'''
        result = parser.extract_commands(response)
        
        assert len(result["file_commands"]) == 1
        assert result["file_commands"][0]["type"] == "CREATE"
        assert len(result["variable_commands"]) == 2
        assert result["variable_commands"][0]["name"] == "x"
        assert result["variable_commands"][1]["name"] == "y"

    def test_clean_response_removes_commands(self):
        """Test that clean_response removes commands."""
        parser = CommandParser()
        response = '''Here is some text.
**FILE_CREATE** file.txt "Content"
x = 10
More text here.'''
        result = parser.extract_commands(response)
        
        # Clean response should not contain commands
        assert "**FILE_CREATE**" not in result["clean_response"]
        assert "x = 10" not in result["clean_response"]
        assert "Here is some text." in result["clean_response"]
        assert "More text here." in result["clean_response"]

    def test_clean_response_preserves_text(self):
        """Test that clean_response preserves non-command text."""
        parser = CommandParser()
        response = "This is regular text without any commands."
        result = parser.extract_commands(response)
        
        assert result["clean_response"] == response
        assert len(result["file_commands"]) == 0
        assert len(result["variable_commands"]) == 0

    def test_clean_response_handles_multiline(self):
        """Test clean_response with multi-line content."""
        parser = CommandParser()
        response = '''**FILE_CREATE** file.txt "Multi
line
content"
Regular text here.'''
        result = parser.extract_commands(response)
        
        assert "**FILE_CREATE**" not in result["clean_response"]
        assert "Regular text here." in result["clean_response"]

    def test_empty_response(self):
        """Test extract_commands with empty response."""
        parser = CommandParser()
        result = parser.extract_commands("")
        
        assert len(result["file_commands"]) == 0
        assert len(result["variable_commands"]) == 0
        assert result["clean_response"] == ""

    def test_only_file_commands(self):
        """Test extract_commands with only file commands."""
        parser = CommandParser()
        response = '''**FILE_CREATE** file1.txt "Content 1"
**FILE_DELETE** file2.txt'''
        result = parser.extract_commands(response)
        
        assert len(result["file_commands"]) == 2
        assert len(result["variable_commands"]) == 0
        assert "**FILE_CREATE**" not in result["clean_response"]
        assert "**FILE_DELETE**" not in result["clean_response"]

    def test_only_variable_commands(self):
        """Test extract_commands with only variable commands."""
        parser = CommandParser()
        response = "x = 10\ny = 20"
        result = parser.extract_commands(response)
        
        assert len(result["file_commands"]) == 0
        assert len(result["variable_commands"]) == 2
        assert "x = 10" not in result["clean_response"]
        assert "y = 20" not in result["clean_response"]


class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_unknown_command_type(self):
        """Test handling of unknown FILE_ command type."""
        parser = CommandParser()
        response = "**FILE_UNKNOWN** path"
        commands = parser.parse_file_commands(response)
        
        # Should log warning but not crash
        assert len(commands) == 0

    def test_unclosed_quotes(self):
        """Test handling of unclosed quotes."""
        parser = CommandParser()
        response = '**FILE_CREATE** file.txt "Unclosed quote'
        commands = parser.parse_file_commands(response)
        
        # Should handle gracefully
        assert len(commands) == 1
        assert commands[0]["type"] == "CREATE"

    def test_empty_content(self):
        """Test FILE_CREATE with empty content."""
        parser = CommandParser()
        response = '**FILE_CREATE** file.txt ""'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["content"] == ""

    def test_no_content_parameter(self):
        """Test FILE_CREATE without content parameter."""
        parser = CommandParser()
        response = '**FILE_CREATE** file.txt'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["content"] == ""

    def test_paths_with_special_chars(self):
        """Test paths with special characters."""
        parser = CommandParser()
        response = '**FILE_CREATE** "path/with-dots.file.txt" "Content"'
        commands = parser.parse_file_commands(response)
        
        assert len(commands) == 1
        assert commands[0]["path"] == "path/with-dots.file.txt"




