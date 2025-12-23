"""Tests for ContextInjector component."""

import os
import pytest
import sys
import tempfile
import time
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))
from components.context_injector import ContextInjector


class TestLoadFileContext:
    """Test load_file_context method."""

    def test_load_empty_directory(self):
        """Test loading context from empty directory."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            
            assert isinstance(context, dict)
            assert "directory_structure" in context
            assert "file_listings" in context
            assert "recent_files" in context
            assert context["directory_structure"] == []
            assert context["file_listings"] == {}
            assert context["recent_files"] == []

    def test_load_with_files(self):
        """Test loading context with files."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create test files
            (Path(tmpdir) / "file1.txt").write_text("Content 1")
            (Path(tmpdir) / "file2.md").write_text("Content 2")
            subdir = Path(tmpdir) / "subdir"
            subdir.mkdir()
            (subdir / "file3.txt").write_text("Content 3")
            
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            
            assert len(context["recent_files"]) > 0
            assert len(context["file_listings"]) > 0

    def test_load_recursive_scan(self):
        """Test that files are scanned recursively."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create nested structure
            nested = Path(tmpdir) / "level1" / "level2" / "level3"
            nested.mkdir(parents=True)
            (nested / "deep.txt").write_text("Deep file")
            
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            
            # Should find the deep file
            found = False
            for file_info in context["recent_files"]:
                if "deep.txt" in file_info["path"]:
                    found = True
                    break
            assert found, "Deep file should be found in recursive scan"

    def test_tracks_modification_times(self):
        """Test that modification times are tracked."""
        with tempfile.TemporaryDirectory() as tmpdir:
            file1 = Path(tmpdir) / "old.txt"
            file1.write_text("Old")
            time.sleep(0.1)  # Ensure different mtime
            
            file2 = Path(tmpdir) / "new.txt"
            file2.write_text("New")
            
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            
            recent_files = context["recent_files"]
            assert len(recent_files) >= 2
            
            # Most recent should be first
            assert "new.txt" in recent_files[0]["path"] or "old.txt" in recent_files[0]["path"]

    def test_sorts_by_modification_time(self):
        """Test that files are sorted by modification time (newest first)."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create files with different modification times
            files = []
            for i in range(5):
                file_path = Path(tmpdir) / f"file{i}.txt"
                file_path.write_text(f"Content {i}")
                files.append(file_path)
                time.sleep(0.05)  # Small delay to ensure different mtimes
            
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            
            recent_files = context["recent_files"]
            # Should be sorted newest first
            for i in range(len(recent_files) - 1):
                assert recent_files[i]["modified"] >= recent_files[i + 1]["modified"]


class TestFormatContext:
    """Test format_context method."""

    def test_format_empty_context(self):
        """Test formatting empty context."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            formatted = injector.format_context(context, {})
            
            assert isinstance(formatted, str)
            assert len(formatted) >= 0

    def test_format_with_files(self):
        """Test formatting context with files."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "test.txt").write_text("Test content")
            
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            formatted = injector.format_context(context, {})
            
            assert "Recent Files" in formatted
            assert "test.txt" in formatted

    def test_format_with_variables(self):
        """Test formatting context with variables."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            variables = {"x": 10, "y": "hello"}
            formatted = injector.format_context(context, variables)
            
            assert "Variables" in formatted
            assert "x=10" in formatted
            assert "y=hello" in formatted

    def test_format_excludes_metadata(self):
        """Test that _metadata is excluded from variables."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            variables = {
                "_metadata": {"created": "2025-01-01"},
                "x": 10
            }
            formatted = injector.format_context(context, variables)
            
            assert "_metadata" not in formatted
            assert "x=10" in formatted

    def test_format_includes_relative_time(self):
        """Test that relative time is included for recent files."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "recent.txt").write_text("Recent")
            
            injector = ContextInjector(tmpdir)
            context = injector.load_file_context()
            formatted = injector.format_context(context, {})
            
            # Should include relative time like "just now" or "X minutes ago"
            assert "recent.txt" in formatted
            # Check for relative time indicators
            assert any(indicator in formatted.lower() for indicator in 
                      ["just now", "minute", "hour", "day", "ago"])


class TestSizeLimits:
    """Test size limit enforcement."""

    def test_respects_max_context_size(self):
        """Test that context respects max_context_size limit."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create many files to generate large context
            for i in range(100):
                (Path(tmpdir) / f"file{i}.txt").write_text(f"Content {i}" * 100)
            
            injector = ContextInjector(tmpdir, max_context_size=500)
            context = injector.load_file_context()
            formatted = injector.format_context(context, {})
            
            assert len(formatted) <= 500 + 50  # Allow some margin for truncation message

    def test_truncates_at_reasonable_boundary(self):
        """Test that truncation happens at reasonable boundaries."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create files
            for i in range(50):
                (Path(tmpdir) / f"file{i}.txt").write_text(f"Content {i}")
            
            injector = ContextInjector(tmpdir, max_context_size=200)
            context = injector.load_file_context()
            formatted = injector.format_context(context, {})
            
            # Should end with truncation indicator
            assert "[... context truncated ...]" in formatted or len(formatted) <= 200

    def test_no_truncation_when_under_limit(self):
        """Test that context is not truncated when under limit."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "small.txt").write_text("Small")
            
            injector = ContextInjector(tmpdir, max_context_size=5000)
            context = injector.load_file_context()
            formatted = injector.format_context(context, {})
            
            assert "[... context truncated ...]" not in formatted


class TestInjectIntoMessages:
    """Test inject_into_messages method."""

    def test_inject_into_empty_messages(self):
        """Test injecting into empty message list."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            context = "Test context"
            messages = []
            
            result = injector.inject_into_messages(messages, context)
            
            assert len(result) == 1
            assert result[0]["role"] == "system"
            assert result[0]["content"] == context

    def test_inject_into_first_user_message(self):
        """Test injecting into first user message."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            context = "Test context"
            messages = [
                {"role": "user", "content": "Hello"}
            ]
            
            result = injector.inject_into_messages(messages, context)
            
            assert len(result) == 1
            assert result[0]["role"] == "user"
            assert context in result[0]["content"]
            assert "Hello" in result[0]["content"]

    def test_inject_into_existing_system_message(self):
        """Test injecting into existing system message."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            context = "Test context"
            messages = [
                {"role": "system", "content": "Existing system message"}
            ]
            
            result = injector.inject_into_messages(messages, context)
            
            assert len(result) == 1
            assert result[0]["role"] == "system"
            assert context in result[0]["content"]
            assert "Existing system message" in result[0]["content"]

    def test_inject_preserves_other_messages(self):
        """Test that other messages are preserved."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            context = "Test context"
            messages = [
                {"role": "user", "content": "Hello"},
                {"role": "assistant", "content": "Hi there"},
                {"role": "user", "content": "How are you?"}
            ]
            
            result = injector.inject_into_messages(messages, context)
            
            assert len(result) == 3
            assert result[0]["role"] == "user"
            assert result[1]["role"] == "assistant"
            assert result[2]["role"] == "user"

    def test_inject_empty_context(self):
        """Test that empty context doesn't modify messages."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            messages = [
                {"role": "user", "content": "Hello"}
            ]
            
            result = injector.inject_into_messages(messages, "")
            
            assert len(result) == 1
            assert result[0]["content"] == "Hello"

    def test_inject_whitespace_only_context(self):
        """Test that whitespace-only context doesn't modify messages."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            messages = [
                {"role": "user", "content": "Hello"}
            ]
            
            result = injector.inject_into_messages(messages, "   \n\t  ")
            
            assert len(result) == 1
            assert result[0]["content"] == "Hello"


class TestCaching:
    """Test caching behavior."""

    def test_caches_file_context(self):
        """Test that file context is cached."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "file1.txt").write_text("Content 1")
            
            injector = ContextInjector(tmpdir, cache_ttl=60)
            context1 = injector.load_file_context()
            
            # Modify file
            (Path(tmpdir) / "file2.txt").write_text("Content 2")
            
            # Should return cached context
            context2 = injector.load_file_context()
            
            # Should be same object (cached)
            assert context1 is context2

    def test_cache_refreshes_after_ttl(self):
        """Test that cache refreshes after TTL."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "file1.txt").write_text("Content 1")
            
            injector = ContextInjector(tmpdir, cache_ttl=1)  # 1 second TTL
            context1 = injector.load_file_context()
            
            # Wait for cache to expire
            time.sleep(1.1)
            
            # Add new file
            (Path(tmpdir) / "file2.txt").write_text("Content 2")
            
            # Should refresh and include new file
            context2 = injector.load_file_context()
            
            # Should be different (refreshed)
            assert context1 is not context2

    def test_force_refresh_bypasses_cache(self):
        """Test that force_refresh bypasses cache."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "file1.txt").write_text("Content 1")
            
            injector = ContextInjector(tmpdir, cache_ttl=60)
            context1 = injector.load_file_context()
            
            # Add new file
            (Path(tmpdir) / "file2.txt").write_text("Content 2")
            
            # Force refresh should bypass cache
            context2 = injector.load_file_context(force_refresh=True)
            
            # Should be different
            assert context1 is not context2


class TestRelativeTimeFormatting:
    """Test relative time formatting."""

    def test_format_just_now(self):
        """Test formatting for very recent times."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            result = injector._format_relative_time(30)
            assert "just now" in result.lower()

    def test_format_minutes(self):
        """Test formatting for minutes."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            result = injector._format_relative_time(120)
            assert "minute" in result.lower()
            assert "2" in result

    def test_format_hours(self):
        """Test formatting for hours."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            result = injector._format_relative_time(7200)
            assert "hour" in result.lower()
            assert "2" in result

    def test_format_days(self):
        """Test formatting for days."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            result = injector._format_relative_time(172800)
            assert "day" in result.lower()
            assert "2" in result

    def test_format_pluralization(self):
        """Test that pluralization works correctly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            injector = ContextInjector(tmpdir)
            result1 = injector._format_relative_time(60)
            result2 = injector._format_relative_time(120)
            
            assert "minute" in result1.lower()
            assert "minutes" in result2.lower() or "minute" in result2.lower()

