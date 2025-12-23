"""File operations manager for Atlas proxy.

Handles secure file CRUD operations with path validation and security checks.
"""

import logging
import os
import shutil
from pathlib import Path
from typing import Dict, Any, List, Tuple

logger = logging.getLogger(__name__)


class FileOperationsManager:
    """Manages secure file operations with path validation and security checks."""

    def __init__(self, base_dir: str, allowed_extensions: list = None, max_size: int = 10485760):
        """Initialize FileOperationsManager instance.
        
        Args:
            base_dir: Base directory path where all file operations are restricted.
            allowed_extensions: List of allowed file extensions (default: ['.txt', '.md']).
            max_size: Maximum file size in bytes (default: 10MB).
        """
        self.base_dir = Path(base_dir).resolve()
        self.allowed_extensions = allowed_extensions or ['.txt', '.md']
        self.max_size = max_size
        
        # Ensure base directory exists
        try:
            self.base_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            logger.error(f"Error creating base directory {self.base_dir}: {e}")

    def _validate_path(self, path: str) -> Tuple[bool, str]:
        """Validate path is safe and within base_dir.
        
        Args:
            path: File path to validate.
            
        Returns:
            Tuple of (is_valid, error_message). If valid, error_message is empty.
        """
        try:
            # Check for directory traversal attempts in the raw path string
            # This catches both Unix-style (../) and Windows-style (..\) patterns
            if '..' in path:
                return False, f"Path {path} is outside base directory (directory traversal detected)"
            
            # Normalize path relative to base_dir (resolve ., etc.)
            # Join with base_dir first, then resolve to handle relative paths correctly
            normalized = (self.base_dir / path).resolve()
            
            # Ensure path is within base_dir
            try:
                normalized.relative_to(self.base_dir)
            except ValueError:
                return False, f"Path {path} is outside base directory"
            
            # Check file extension (only if path has a suffix)
            if normalized.suffix:
                if normalized.suffix.lower() not in [ext.lower() for ext in self.allowed_extensions]:
                    return False, f"File extension {normalized.suffix} not allowed. Allowed: {self.allowed_extensions}"
            
            return True, ""
        except Exception as e:
            return False, f"Invalid path: {str(e)}"

    def create_file(self, path: str, content: str) -> Dict[str, Any]:
        """Create new file with content, auto-creating parent directories.
        
        Args:
            path: Relative path from base_dir.
            content: File content to write.
            
        Returns:
            Dict with "success" (bool), "message" (str), and optionally "path" (str).
        """
        try:
            # Validate path
            is_valid, error_msg = self._validate_path(path)
            if not is_valid:
                return {"success": False, "message": error_msg}
            
            # Check content size
            content_size = len(content.encode('utf-8'))
            if content_size > self.max_size:
                return {
                    "success": False,
                    "message": f"Content size {content_size} exceeds maximum {self.max_size} bytes"
                }
            
            # Build full path
            full_path = self.base_dir / path
            
            # Create parent directories
            try:
                full_path.parent.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                return {"success": False, "message": f"Error creating parent directories: {str(e)}"}
            
            # Write file
            try:
                with open(full_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.debug(f"Created file: {full_path}")
                return {"success": True, "message": "File created successfully", "path": str(full_path)}
            except IOError as e:
                return {"success": False, "message": f"Error writing file: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error creating file {path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def read_file(self, path: str) -> Dict[str, Any]:
        """Read file content.
        
        Args:
            path: Relative path from base_dir.
            
        Returns:
            Dict with "success" (bool), "message" (str), and optionally "content" (str).
        """
        try:
            # Validate path
            is_valid, error_msg = self._validate_path(path)
            if not is_valid:
                return {"success": False, "message": error_msg}
            
            full_path = self.base_dir / path
            
            # Check if file exists
            if not full_path.exists():
                return {"success": False, "message": f"File not found: {path}"}
            
            if not full_path.is_file():
                return {"success": False, "message": f"Path is not a file: {path}"}
            
            # Check file size
            file_size = full_path.stat().st_size
            if file_size > self.max_size:
                return {
                    "success": False,
                    "message": f"File size {file_size} exceeds maximum {self.max_size} bytes"
                }
            
            # Read file
            try:
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                logger.debug(f"Read file: {full_path}")
                return {"success": True, "message": "File read successfully", "content": content}
            except IOError as e:
                return {"success": False, "message": f"Error reading file: {str(e)}"}
            except UnicodeDecodeError as e:
                return {"success": False, "message": f"Error decoding file (not UTF-8): {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error reading file {path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def update_file(self, path: str, content: str) -> Dict[str, Any]:
        """Replace entire file content.
        
        Args:
            path: Relative path from base_dir.
            content: New file content.
            
        Returns:
            Dict with "success" (bool) and "message" (str).
        """
        try:
            # Validate path
            is_valid, error_msg = self._validate_path(path)
            if not is_valid:
                return {"success": False, "message": error_msg}
            
            full_path = self.base_dir / path
            
            # Check if file exists
            if not full_path.exists():
                return {"success": False, "message": f"File not found: {path}"}
            
            # Check content size
            content_size = len(content.encode('utf-8'))
            if content_size > self.max_size:
                return {
                    "success": False,
                    "message": f"Content size {content_size} exceeds maximum {self.max_size} bytes"
                }
            
            # Write file
            try:
                with open(full_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.debug(f"Updated file: {full_path}")
                return {"success": True, "message": "File updated successfully"}
            except IOError as e:
                return {"success": False, "message": f"Error writing file: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error updating file {path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def append_file(self, path: str, content: str) -> Dict[str, Any]:
        """Append content to end of file.
        
        Args:
            path: Relative path from base_dir.
            content: Content to append.
            
        Returns:
            Dict with "success" (bool) and "message" (str).
        """
        try:
            # Validate path
            is_valid, error_msg = self._validate_path(path)
            if not is_valid:
                return {"success": False, "message": error_msg}
            
            full_path = self.base_dir / path
            
            # Check if file exists
            if not full_path.exists():
                return {"success": False, "message": f"File not found: {path}"}
            
            # Check current file size + new content
            current_size = full_path.stat().st_size
            content_size = len(content.encode('utf-8'))
            if current_size + content_size > self.max_size:
                return {
                    "success": False,
                    "message": f"File size would exceed maximum {self.max_size} bytes"
                }
            
            # Append to file
            try:
                with open(full_path, 'a', encoding='utf-8') as f:
                    f.write(content)
                logger.debug(f"Appended to file: {full_path}")
                return {"success": True, "message": "Content appended successfully"}
            except IOError as e:
                return {"success": False, "message": f"Error appending to file: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error appending to file {path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def delete_file(self, path: str) -> Dict[str, Any]:
        """Delete file.
        
        Args:
            path: Relative path from base_dir.
            
        Returns:
            Dict with "success" (bool) and "message" (str).
        """
        try:
            # Validate path
            is_valid, error_msg = self._validate_path(path)
            if not is_valid:
                return {"success": False, "message": error_msg}
            
            full_path = self.base_dir / path
            
            # Check if file exists
            if not full_path.exists():
                return {"success": False, "message": f"File not found: {path}"}
            
            if not full_path.is_file():
                return {"success": False, "message": f"Path is not a file: {path}"}
            
            # Delete file
            try:
                full_path.unlink()
                logger.debug(f"Deleted file: {full_path}")
                return {"success": True, "message": "File deleted successfully"}
            except OSError as e:
                return {"success": False, "message": f"Error deleting file: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error deleting file {path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def move_file(self, old_path: str, new_path: str) -> Dict[str, Any]:
        """Move/rename file.
        
        Args:
            old_path: Current relative path from base_dir.
            new_path: New relative path from base_dir.
            
        Returns:
            Dict with "success" (bool) and "message" (str).
        """
        try:
            # Validate both paths
            is_valid, error_msg = self._validate_path(old_path)
            if not is_valid:
                return {"success": False, "message": f"Invalid source path: {error_msg}"}
            
            is_valid, error_msg = self._validate_path(new_path)
            if not is_valid:
                return {"success": False, "message": f"Invalid destination path: {error_msg}"}
            
            old_full_path = self.base_dir / old_path
            new_full_path = self.base_dir / new_path
            
            # Check if source file exists
            if not old_full_path.exists():
                return {"success": False, "message": f"Source file not found: {old_path}"}
            
            if not old_full_path.is_file():
                return {"success": False, "message": f"Source path is not a file: {old_path}"}
            
            # Create parent directories for destination
            try:
                new_full_path.parent.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                return {"success": False, "message": f"Error creating destination directories: {str(e)}"}
            
            # Move file
            try:
                shutil.move(str(old_full_path), str(new_full_path))
                logger.debug(f"Moved file from {old_full_path} to {new_full_path}")
                return {"success": True, "message": "File moved successfully"}
            except OSError as e:
                return {"success": False, "message": f"Error moving file: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error moving file {old_path} to {new_path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def copy_file(self, src_path: str, dst_path: str) -> Dict[str, Any]:
        """Copy file.
        
        Args:
            src_path: Source relative path from base_dir.
            dst_path: Destination relative path from base_dir.
            
        Returns:
            Dict with "success" (bool) and "message" (str).
        """
        try:
            # Validate both paths
            is_valid, error_msg = self._validate_path(src_path)
            if not is_valid:
                return {"success": False, "message": f"Invalid source path: {error_msg}"}
            
            is_valid, error_msg = self._validate_path(dst_path)
            if not is_valid:
                return {"success": False, "message": f"Invalid destination path: {error_msg}"}
            
            src_full_path = self.base_dir / src_path
            dst_full_path = self.base_dir / dst_path
            
            # Check if source file exists
            if not src_full_path.exists():
                return {"success": False, "message": f"Source file not found: {src_path}"}
            
            if not src_full_path.is_file():
                return {"success": False, "message": f"Source path is not a file: {src_path}"}
            
            # Create parent directories for destination
            try:
                dst_full_path.parent.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                return {"success": False, "message": f"Error creating destination directories: {str(e)}"}
            
            # Copy file
            try:
                shutil.copy2(str(src_full_path), str(dst_full_path))
                logger.debug(f"Copied file from {src_full_path} to {dst_full_path}")
                return {"success": True, "message": "File copied successfully"}
            except OSError as e:
                return {"success": False, "message": f"Error copying file: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error copying file {src_path} to {dst_path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def search_files(self, directory: str, search_term: str) -> Dict[str, Any]:
        """Search for text in files within directory.
        
        Args:
            directory: Relative directory path from base_dir.
            search_term: Text to search for.
            
        Returns:
            Dict with "success" (bool), "message" (str), and "matches" (list of dicts).
        """
        try:
            # Validate directory path
            is_valid, error_msg = self._validate_path(directory)
            if not is_valid:
                return {"success": False, "message": f"Invalid directory path: {error_msg}"}
            
            full_dir_path = self.base_dir / directory
            
            # Check if directory exists
            if not full_dir_path.exists():
                return {"success": False, "message": f"Directory not found: {directory}"}
            
            if not full_dir_path.is_dir():
                return {"success": False, "message": f"Path is not a directory: {directory}"}
            
            matches = []
            
            # Recursively search files
            try:
                for file_path in full_dir_path.rglob('*'):
                    if file_path.is_file():
                        # Check extension
                        if file_path.suffix.lower() not in [ext.lower() for ext in self.allowed_extensions]:
                            continue
                        
                        # Check file size
                        if file_path.stat().st_size > self.max_size:
                            continue
                        
                        # Search in file
                        try:
                            with open(file_path, 'r', encoding='utf-8') as f:
                                content = f.read()
                                if search_term in content:
                                    # Get relative path
                                    rel_path = file_path.relative_to(self.base_dir)
                                    matches.append({
                                        "path": str(rel_path),
                                        "matches": content.count(search_term)
                                    })
                        except (IOError, UnicodeDecodeError):
                            # Skip files that can't be read
                            continue
                
                logger.debug(f"Search found {len(matches)} matches in {full_dir_path}")
                return {
                    "success": True,
                    "message": f"Search completed: {len(matches)} matches found",
                    "matches": matches
                }
            except OSError as e:
                return {"success": False, "message": f"Error searching directory: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error searching directory {directory}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def list_directory(self, path: str) -> Dict[str, Any]:
        """List files and directories.
        
        Args:
            path: Relative directory path from base_dir.
            
        Returns:
            Dict with "success" (bool), "message" (str), "files" (list), and "directories" (list).
        """
        try:
            # Validate path
            is_valid, error_msg = self._validate_path(path)
            if not is_valid:
                return {"success": False, "message": error_msg}
            
            full_path = self.base_dir / path
            
            # Check if path exists
            if not full_path.exists():
                return {"success": False, "message": f"Path not found: {path}"}
            
            if not full_path.is_dir():
                return {"success": False, "message": f"Path is not a directory: {path}"}
            
            # List contents
            try:
                files = []
                directories = []
                
                for item in full_path.iterdir():
                    rel_path = item.relative_to(self.base_dir)
                    if item.is_file():
                        files.append({
                            "name": item.name,
                            "path": str(rel_path),
                            "size": item.stat().st_size
                        })
                    elif item.is_dir():
                        directories.append({
                            "name": item.name,
                            "path": str(rel_path)
                        })
                
                logger.debug(f"Listed directory: {full_path}")
                return {
                    "success": True,
                    "message": "Directory listed successfully",
                    "files": sorted(files, key=lambda x: x["name"]),
                    "directories": sorted(directories, key=lambda x: x["name"])
                }
            except OSError as e:
                return {"success": False, "message": f"Error listing directory: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error listing directory {path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

    def archive_file(self, path: str) -> Dict[str, Any]:
        """Move file to archive/ subdirectory.
        
        Args:
            path: Relative path from base_dir.
            
        Returns:
            Dict with "success" (bool) and "message" (str).
        """
        try:
            # Validate path
            is_valid, error_msg = self._validate_path(path)
            if not is_valid:
                return {"success": False, "message": error_msg}
            
            full_path = self.base_dir / path
            
            # Check if file exists
            if not full_path.exists():
                return {"success": False, "message": f"File not found: {path}"}
            
            if not full_path.is_file():
                return {"success": False, "message": f"Path is not a file: {path}"}
            
            # Build archive path (preserve subdirectory structure)
            archive_dir = self.base_dir / "archive"
            rel_path = full_path.relative_to(self.base_dir)
            archive_path = archive_dir / rel_path
            
            # Create archive directory and parent directories
            try:
                archive_path.parent.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                return {"success": False, "message": f"Error creating archive directories: {str(e)}"}
            
            # Move file to archive
            try:
                shutil.move(str(full_path), str(archive_path))
                logger.debug(f"Archived file from {full_path} to {archive_path}")
                return {"success": True, "message": "File archived successfully"}
            except OSError as e:
                return {"success": False, "message": f"Error archiving file: {str(e)}"}
                
        except Exception as e:
            logger.error(f"Unexpected error archiving file {path}: {e}")
            return {"success": False, "message": f"Unexpected error: {str(e)}"}

