"""Tests for FileOperationsManager component."""

import os
import pytest
import sys
import tempfile
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))
from components.file_ops import FileOperationsManager


class TestCreateFile:
    """Test create_file method."""

    def test_create_file_success(self):
        """Test creating a file successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.create_file("test.txt", "Hello, world!")
            
            assert result["success"] is True
            assert "created successfully" in result["message"].lower()
            
            file_path = Path(tmpdir) / "test.txt"
            assert file_path.exists()
            assert file_path.read_text() == "Hello, world!"

    def test_create_file_creates_parent_dirs(self):
        """Test creating file creates parent directories."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.create_file("subdir/nested/test.txt", "Content")
            
            assert result["success"] is True
            file_path = Path(tmpdir) / "subdir" / "nested" / "test.txt"
            assert file_path.exists()

    def test_create_file_invalid_extension(self):
        """Test creating file with invalid extension fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.create_file("test.py", "Code")
            
            assert result["success"] is False
            assert "extension" in result["message"].lower()

    def test_create_file_too_large(self):
        """Test creating file that exceeds size limit fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir, max_size=10)
            large_content = "x" * 100
            result = manager.create_file("test.txt", large_content)
            
            assert result["success"] is False
            assert "size" in result["message"].lower() or "exceed" in result["message"].lower()

    def test_create_file_directory_traversal(self):
        """Test directory traversal attack is prevented."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.create_file("../../etc/passwd", "malicious")
            
            assert result["success"] is False
            assert "outside" in result["message"].lower() or "base" in result["message"].lower()


class TestReadFile:
    """Test read_file method."""

    def test_read_file_success(self):
        """Test reading a file successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            test_file = Path(tmpdir) / "test.txt"
            test_file.write_text("File content")
            
            result = manager.read_file("test.txt")
            
            assert result["success"] is True
            assert result["content"] == "File content"

    def test_read_file_not_found(self):
        """Test reading non-existent file fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.read_file("nonexistent.txt")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()

    def test_read_file_directory_traversal(self):
        """Test directory traversal attack is prevented."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.read_file("../../etc/passwd")
            
            assert result["success"] is False
            assert "outside" in result["message"].lower() or "base" in result["message"].lower()


class TestUpdateFile:
    """Test update_file method."""

    def test_update_file_success(self):
        """Test updating a file successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            test_file = Path(tmpdir) / "test.txt"
            test_file.write_text("Old content")
            
            result = manager.update_file("test.txt", "New content")
            
            assert result["success"] is True
            assert test_file.read_text() == "New content"

    def test_update_file_not_found(self):
        """Test updating non-existent file fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.update_file("nonexistent.txt", "Content")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()


class TestAppendFile:
    """Test append_file method."""

    def test_append_file_success(self):
        """Test appending to a file successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            test_file = Path(tmpdir) / "test.txt"
            test_file.write_text("Original")
            
            result = manager.append_file("test.txt", " appended")
            
            assert result["success"] is True
            assert test_file.read_text() == "Original appended"

    def test_append_file_not_found(self):
        """Test appending to non-existent file fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.append_file("nonexistent.txt", "Content")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()

    def test_append_file_size_limit(self):
        """Test appending that would exceed size limit fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir, max_size=20)
            
            # Create file with content near limit
            test_file = Path(tmpdir) / "test.txt"
            test_file.write_text("x" * 15)
            
            result = manager.append_file("test.txt", "y" * 10)
            
            assert result["success"] is False
            assert "size" in result["message"].lower() or "exceed" in result["message"].lower()


class TestDeleteFile:
    """Test delete_file method."""

    def test_delete_file_success(self):
        """Test deleting a file successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            test_file = Path(tmpdir) / "test.txt"
            test_file.write_text("Content")
            
            result = manager.delete_file("test.txt")
            
            assert result["success"] is True
            assert not test_file.exists()

    def test_delete_file_not_found(self):
        """Test deleting non-existent file fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.delete_file("nonexistent.txt")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()


class TestMoveFile:
    """Test move_file method."""

    def test_move_file_success(self):
        """Test moving a file successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            old_file = Path(tmpdir) / "old.txt"
            old_file.write_text("Content")
            
            result = manager.move_file("old.txt", "new.txt")
            
            assert result["success"] is True
            assert not old_file.exists()
            
            new_file = Path(tmpdir) / "new.txt"
            assert new_file.exists()
            assert new_file.read_text() == "Content"

    def test_move_file_creates_parent_dirs(self):
        """Test moving file creates destination parent directories."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            old_file = Path(tmpdir) / "old.txt"
            old_file.write_text("Content")
            
            result = manager.move_file("old.txt", "subdir/nested/new.txt")
            
            assert result["success"] is True
            new_file = Path(tmpdir) / "subdir" / "nested" / "new.txt"
            assert new_file.exists()

    def test_move_file_not_found(self):
        """Test moving non-existent file fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.move_file("nonexistent.txt", "new.txt")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()

    def test_move_file_directory_traversal(self):
        """Test directory traversal attack is prevented."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            test_file = Path(tmpdir) / "test.txt"
            test_file.write_text("Content")
            
            result = manager.move_file("test.txt", "../../etc/passwd")
            
            assert result["success"] is False
            assert "outside" in result["message"].lower() or "base" in result["message"].lower()


class TestCopyFile:
    """Test copy_file method."""

    def test_copy_file_success(self):
        """Test copying a file successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            src_file = Path(tmpdir) / "source.txt"
            src_file.write_text("Content")
            
            result = manager.copy_file("source.txt", "dest.txt")
            
            assert result["success"] is True
            
            src_file = Path(tmpdir) / "source.txt"
            dest_file = Path(tmpdir) / "dest.txt"
            assert src_file.exists()
            assert dest_file.exists()
            assert dest_file.read_text() == "Content"

    def test_copy_file_not_found(self):
        """Test copying non-existent file fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.copy_file("nonexistent.txt", "dest.txt")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()


class TestSearchFiles:
    """Test search_files method."""

    def test_search_files_success(self):
        """Test searching files successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create test files
            (Path(tmpdir) / "file1.txt").write_text("Hello world")
            (Path(tmpdir) / "file2.txt").write_text("Hello there")
            (Path(tmpdir) / "file3.txt").write_text("Goodbye")
            
            result = manager.search_files(".", "Hello")
            
            assert result["success"] is True
            assert len(result["matches"]) == 2
            assert any(m["path"] == "file1.txt" for m in result["matches"])
            assert any(m["path"] == "file2.txt" for m in result["matches"])

    def test_search_files_subdirectory(self):
        """Test searching files in subdirectory."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create test files
            subdir = Path(tmpdir) / "subdir"
            subdir.mkdir()
            (subdir / "file.txt").write_text("Search term")
            
            result = manager.search_files("subdir", "Search")
            
            assert result["success"] is True
            assert len(result["matches"]) == 1

    def test_search_files_not_found(self):
        """Test searching non-existent directory fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.search_files("nonexistent", "term")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()


class TestListDirectory:
    """Test list_directory method."""

    def test_list_directory_success(self):
        """Test listing directory successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create test files and directories
            (Path(tmpdir) / "file1.txt").write_text("Content")
            (Path(tmpdir) / "file2.md").write_text("Content")
            (Path(tmpdir) / "subdir").mkdir()
            
            result = manager.list_directory(".")
            
            assert result["success"] is True
            assert len(result["files"]) == 2
            assert len(result["directories"]) == 1
            assert any(f["name"] == "file1.txt" for f in result["files"])
            assert any(d["name"] == "subdir" for d in result["directories"])

    def test_list_directory_not_found(self):
        """Test listing non-existent directory fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.list_directory("nonexistent")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()


class TestArchiveFile:
    """Test archive_file method."""

    def test_archive_file_success(self):
        """Test archiving a file successfully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create file first
            test_file = Path(tmpdir) / "notes" / "test.txt"
            test_file.parent.mkdir()
            test_file.write_text("Content")
            
            result = manager.archive_file("notes/test.txt")
            
            assert result["success"] is True
            assert not test_file.exists()
            
            archive_file = Path(tmpdir) / "archive" / "notes" / "test.txt"
            assert archive_file.exists()
            assert archive_file.read_text() == "Content"

    def test_archive_file_not_found(self):
        """Test archiving non-existent file fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            result = manager.archive_file("nonexistent.txt")
            
            assert result["success"] is False
            assert "not found" in result["message"].lower()


class TestSecurity:
    """Test security features."""

    def test_path_validation_directory_traversal(self):
        """Test various directory traversal attempts are blocked."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Test various traversal patterns
            traversal_paths = [
                "../../etc/passwd",
                "../test.txt",
                "..\\test.txt",  # Windows-style
                "subdir/../../etc/passwd",
                "subdir/../..",
            ]
            
            for path in traversal_paths:
                result = manager.create_file(path, "malicious")
                assert result["success"] is False, f"Path {path} should be blocked"
                assert "outside" in result["message"].lower() or "base" in result["message"].lower()

    def test_extension_restriction(self):
        """Test that only allowed extensions are accepted."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Test disallowed extensions
            disallowed = [".py", ".exe", ".sh", ".bat", ".js"]
            for ext in disallowed:
                result = manager.create_file(f"test{ext}", "content")
                assert result["success"] is False, f"Extension {ext} should be blocked"
                assert "extension" in result["message"].lower()
            
            # Test allowed extensions
            allowed = [".txt", ".md"]
            for ext in allowed:
                result = manager.create_file(f"test{ext}", "content")
                assert result["success"] is True, f"Extension {ext} should be allowed"

    def test_custom_allowed_extensions(self):
        """Test custom allowed extensions."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir, allowed_extensions=['.py', '.js'])
            
            result = manager.create_file("test.py", "code")
            assert result["success"] is True
            
            result = manager.create_file("test.txt", "text")
            assert result["success"] is False

    def test_file_size_limit(self):
        """Test file size limit enforcement."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir, max_size=100)
            
            # Create file within limit
            result = manager.create_file("small.txt", "x" * 50)
            assert result["success"] is True
            
            # Create file exceeding limit
            result = manager.create_file("large.txt", "x" * 150)
            assert result["success"] is False
            assert "size" in result["message"].lower() or "exceed" in result["message"].lower()


class TestIntegration:
    """Integration tests for full workflows."""

    def test_create_read_update_delete_workflow(self):
        """Test complete CRUD workflow."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create
            result = manager.create_file("test.txt", "Original")
            assert result["success"] is True
            
            # Read
            result = manager.read_file("test.txt")
            assert result["success"] is True
            assert result["content"] == "Original"
            
            # Update
            result = manager.update_file("test.txt", "Updated")
            assert result["success"] is True
            
            # Read again
            result = manager.read_file("test.txt")
            assert result["success"] is True
            assert result["content"] == "Updated"
            
            # Delete
            result = manager.delete_file("test.txt")
            assert result["success"] is True
            
            # Verify deleted
            result = manager.read_file("test.txt")
            assert result["success"] is False

    def test_move_and_copy_workflow(self):
        """Test move and copy operations."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create source file
            result = manager.create_file("source.txt", "Content")
            assert result["success"] is True
            
            # Copy
            result = manager.copy_file("source.txt", "copy.txt")
            assert result["success"] is True
            
            # Verify both exist
            result1 = manager.read_file("source.txt")
            result2 = manager.read_file("copy.txt")
            assert result1["success"] is True
            assert result2["success"] is True
            assert result1["content"] == result2["content"]
            
            # Move
            result = manager.move_file("source.txt", "moved.txt")
            assert result["success"] is True
            
            # Verify moved
            result1 = manager.read_file("source.txt")
            result2 = manager.read_file("moved.txt")
            assert result1["success"] is False
            assert result2["success"] is True

    def test_search_and_archive_workflow(self):
        """Test search and archive operations."""
        with tempfile.TemporaryDirectory() as tmpdir:
            manager = FileOperationsManager(tmpdir)
            
            # Create test files
            manager.create_file("notes/file1.txt", "Important note")
            manager.create_file("notes/file2.txt", "Another note")
            manager.create_file("docs/file3.txt", "Documentation")
            
            # Search
            result = manager.search_files("notes", "Important")
            assert result["success"] is True
            assert len(result["matches"]) == 1
            
            # Archive
            result = manager.archive_file("notes/file1.txt")
            assert result["success"] is True
            
            # Verify archived
            result = manager.read_file("notes/file1.txt")
            assert result["success"] is False
            
            result = manager.read_file("archive/notes/file1.txt")
            assert result["success"] is True

