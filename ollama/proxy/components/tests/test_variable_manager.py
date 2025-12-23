"""Tests for VariableManager component."""

import json
import os
import pytest
import sys
import tempfile
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))
from components.variable_manager import VariableManager


class TestLoadVariables:
    """Test load_variables method."""

    def test_load_when_file_doesnt_exist(self):
        """Test load when variables.json doesn't exist."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            variables = manager.load_variables()
            assert variables == {}

    def test_load_valid_json(self):
        """Test load when file contains valid JSON."""
        with tempfile.TemporaryDirectory() as tmpdir:
            variables_file = Path(tmpdir) / "variables.json"
            test_data = {"x": 10, "y": 20, "name": "test"}
            with open(variables_file, 'w') as f:
                json.dump(test_data, f)
            
            manager = VariableManager(tmpdir)
            variables = manager.load_variables()
            assert variables == test_data

    def test_load_invalid_json(self):
        """Test load when file contains invalid JSON."""
        with tempfile.TemporaryDirectory() as tmpdir:
            variables_file = Path(tmpdir) / "variables.json"
            with open(variables_file, 'w') as f:
                f.write("invalid json content {")
            
            manager = VariableManager(tmpdir)
            variables = manager.load_variables()
            assert variables == {}

    def test_load_non_dict_json(self):
        """Test load when file contains JSON but not a dict."""
        with tempfile.TemporaryDirectory() as tmpdir:
            variables_file = Path(tmpdir) / "variables.json"
            with open(variables_file, 'w') as f:
                json.dump([1, 2, 3], f)
            
            manager = VariableManager(tmpdir)
            variables = manager.load_variables()
            assert variables == {}

    def test_load_with_metadata(self):
        """Test load preserves _metadata key."""
        with tempfile.TemporaryDirectory() as tmpdir:
            variables_file = Path(tmpdir) / "variables.json"
            test_data = {
                "x": 10,
                "y": 20,
                "_metadata": {"created": "2025-01-06", "updated": "2025-01-06"}
            }
            with open(variables_file, 'w') as f:
                json.dump(test_data, f)
            
            manager = VariableManager(tmpdir)
            variables = manager.load_variables()
            assert variables == test_data
            assert "_metadata" in variables


class TestSaveVariables:
    """Test save_variables method."""

    def test_save_creates_file(self):
        """Test save creates variables.json file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            test_vars = {"x": 10, "y": 20}
            
            result = manager.save_variables(test_vars)
            assert result is True
            
            variables_file = Path(tmpdir) / "variables.json"
            assert variables_file.exists()
            
            with open(variables_file, 'r') as f:
                loaded = json.load(f)
            assert loaded == test_vars

    def test_save_atomic_write(self):
        """Test atomic write pattern (temp file then rename)."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            test_vars = {"x": 10}
            
            manager.save_variables(test_vars)
            
            # Verify temp file doesn't exist (should have been renamed)
            temp_file = Path(tmpdir) / "variables.json.tmp"
            assert not temp_file.exists()
            
            # Verify final file exists
            variables_file = Path(tmpdir) / "variables.json"
            assert variables_file.exists()

    def test_save_creates_backup(self):
        """Test save creates backup file before overwriting."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            
            # Create initial file
            initial_vars = {"old": "value"}
            manager.save_variables(initial_vars)
            
            # Save new variables
            new_vars = {"new": "value"}
            manager.save_variables(new_vars)
            
            # Verify backup exists
            backup_file = Path(tmpdir) / "variables.json.backup"
            assert backup_file.exists()
            
            # Verify backup contains old data
            with open(backup_file, 'r') as f:
                backup_data = json.load(f)
            assert backup_data == initial_vars
            
            # Verify new file has new data
            variables_file = Path(tmpdir) / "variables.json"
            with open(variables_file, 'r') as f:
                new_data = json.load(f)
            assert new_data == new_vars

    def test_save_non_dict_fails(self):
        """Test save fails gracefully with non-dict input."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            result = manager.save_variables([1, 2, 3])
            assert result is False
            
            variables_file = Path(tmpdir) / "variables.json"
            assert not variables_file.exists()

    def test_save_creates_directory(self):
        """Test save creates data directory if it doesn't exist."""
        with tempfile.TemporaryDirectory() as tmpdir:
            data_dir = Path(tmpdir) / "subdir" / "nested"
            manager = VariableManager(str(data_dir))
            
            test_vars = {"x": 10}
            result = manager.save_variables(test_vars)
            assert result is True
            
            assert data_dir.exists()
            variables_file = data_dir / "variables.json"
            assert variables_file.exists()


class TestFormatForPrompt:
    """Test format_for_prompt method."""

    def test_format_empty_dict(self):
        """Test format with empty dict."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            result = manager.format_for_prompt({})
            assert result == "**Variables**: (none)"

    def test_format_excludes_metadata(self):
        """Test format excludes _metadata key."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            variables = {
                "x": 10,
                "y": 20,
                "_metadata": {"created": "2025-01-06"}
            }
            result = manager.format_for_prompt(variables)
            assert "_metadata" not in result
            assert "x=10" in result
            assert "y=20" in result

    def test_format_only_metadata(self):
        """Test format when only _metadata exists."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            variables = {"_metadata": {"created": "2025-01-06"}}
            result = manager.format_for_prompt(variables)
            assert result == "**Variables**: (none)"

    def test_format_multiple_variables(self):
        """Test format with multiple variables."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            variables = {"x": 10, "y": 3, "name": "test"}
            result = manager.format_for_prompt(variables)
            assert result.startswith("**Variables**:")
            assert "x=10" in result
            assert "y=3" in result
            assert "name=test" in result

    def test_format_sorted_output(self):
        """Test format outputs variables in sorted order."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            variables = {"z": 1, "a": 2, "m": 3}
            result = manager.format_for_prompt(variables)
            # Should be sorted alphabetically
            assert result.index("a=2") < result.index("m=3")
            assert result.index("m=3") < result.index("z=1")


class TestParseUpdates:
    """Test parse_updates method."""

    def test_parse_equals_sign(self):
        """Test parsing 'x = 10' format."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "x = 10"
            updates = manager.parse_updates(response)
            assert updates == {"x": 10}

    def test_parse_no_spaces(self):
        """Test parsing 'x=10' format (no spaces)."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "x=10"
            updates = manager.parse_updates(response)
            assert updates == {"x": 10}

    def test_parse_equals_word(self):
        """Test parsing 'x equals 10' format."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "x equals 10"
            updates = manager.parse_updates(response)
            assert updates == {"x": 10}

    def test_parse_is_word(self):
        """Test parsing 'x is 10' format."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "x is 10"
            updates = manager.parse_updates(response)
            assert updates == {"x": 10}

    def test_parse_set_to(self):
        """Test parsing 'set x to 10' format."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "set x to 10"
            updates = manager.parse_updates(response)
            assert updates == {"x": 10}

    def test_parse_remember_is(self):
        """Test parsing 'remember x is 10' format."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "remember x is 10"
            updates = manager.parse_updates(response)
            assert updates == {"x": 10}

    def test_parse_multiple_assignments(self):
        """Test parsing multiple assignments in one response."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "x = 10 and y equals 20"
            updates = manager.parse_updates(response)
            assert updates == {"x": 10, "y": 20}

    def test_parse_string_values(self):
        """Test parsing string values."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "name = test"
            updates = manager.parse_updates(response)
            assert updates == {"name": "test"}

    def test_parse_float_values(self):
        """Test parsing float values."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "x = 3.14"
            updates = manager.parse_updates(response)
            assert updates == {"x": 3.14}

    def test_parse_boolean_values(self):
        """Test parsing boolean values."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "enabled = true"
            updates = manager.parse_updates(response)
            assert updates == {"enabled": True}

    def test_parse_case_insensitive(self):
        """Test parsing is case insensitive."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "SET X TO 10"
            updates = manager.parse_updates(response)
            assert updates == {"X": 10}

    def test_parse_no_matches(self):
        """Test parsing when no assignments found."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "This is just regular text with no assignments."
            updates = manager.parse_updates(response)
            assert updates == {}

    def test_parse_with_punctuation(self):
        """Test parsing handles trailing punctuation."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            response = "x = 10, y = 20."
            updates = manager.parse_updates(response)
            assert updates == {"x": 10, "y": 20}


class TestIntegration:
    """Integration tests for full workflow."""

    def test_load_save_roundtrip(self):
        """Test loading and saving variables maintains data."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            
            # Save initial variables
            initial_vars = {"x": 10, "y": 20, "name": "test"}
            assert manager.save_variables(initial_vars) is True
            
            # Load and verify
            loaded_vars = manager.load_variables()
            assert loaded_vars == initial_vars

    def test_update_variables_workflow(self):
        """Test complete workflow: load, parse updates, save."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            
            # Initial variables
            initial_vars = {"x": 10, "y": 20}
            manager.save_variables(initial_vars)
            
            # Parse updates from response
            response = "set z to 30 and remember x is 15"
            updates = manager.parse_updates(response)
            
            # Merge updates
            initial_vars.update(updates)
            
            # Save updated variables
            manager.save_variables(initial_vars)
            
            # Verify final state
            final_vars = manager.load_variables()
            assert final_vars["x"] == 15
            assert final_vars["y"] == 20
            assert final_vars["z"] == 30

    def test_format_and_parse_workflow(self):
        """Test formatting for prompt and parsing response."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = VariableManager(tmpdir)
            
            variables = {"x": 10, "y": 20, "_metadata": {"created": "2025-01-06"}}
            
            # Format for prompt
            prompt_text = manager.format_for_prompt(variables)
            assert "_metadata" not in prompt_text
            assert "x=10" in prompt_text
            
            # Parse updates from response
            response = "set z to 30"
            updates = manager.parse_updates(response)
            assert updates == {"z": 30}

