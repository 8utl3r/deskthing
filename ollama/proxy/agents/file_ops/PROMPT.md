# File Operations Manager Prompt

You are building the FileOperationsManager component for Atlas proxy. This handles all file CRUD operations.

**FIRST STEP:** Create a file `proxy/agents/file_ops/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Build a secure file operations manager that can create, read, update, delete, move, copy, search, list, and archive text files.

**Requirements:**
- Create `proxy/components/file_ops.py`
- Class should be named `FileOperationsManager`
- Constructor: `__init__(self, base_dir: str, allowed_extensions: list = None, max_size: int = 10485760)`
- Methods (all return dict with "success", "message", and other fields):
                                - `create_file(self, path: str, content: str) -> dict` - Create new file, auto-create parent dirs
                                - `read_file(self, path: str) -> dict` - Read file content
                                - `update_file(self, path: str, content: str) -> dict` - Replace entire file
                                - `append_file(self, path: str, content: str) -> dict` - Append to end of file
                                - `delete_file(self, path: str) -> dict` - Delete file
                                - `move_file(self, old_path: str, new_path: str) -> dict` - Move/rename file
                                - `copy_file(self, src_path: str, dst_path: str) -> dict` - Copy file
                                - `search_files(self, directory: str, search_term: str) -> dict` - Search for text in files
                                - `list_directory(self, path: str) -> dict` - List files/directories
                                - `archive_file(self, path: str) -> dict` - Move to archive/ subdirectory
                                - `_validate_path(self, path: str) -> tuple[bool, str]` - Validate path is safe

**Security Requirements:**
- Prevent directory traversal (ensure path stays within base_dir)
- Only allow `.txt` and `.md` extensions by default
- Enforce maximum file size
- Normalize paths (resolve `..`, `.`, etc.)

**Error Handling:**
- Return dict with "success": False and helpful "message" for errors
- Handle: file not found, permission errors, invalid paths, file too large, invalid extension

**Testing:**
- Create `proxy/components/tests/test_file_ops.py`
- Test all operations with valid paths
- Test security (directory traversal attempts)
- Test file size limits
- Test extension restrictions
- Test error handling

**Deliverables:**
- `proxy/components/file_ops.py` (working implementation)
- `proxy/components/tests/test_file_ops.py` (tests that pass)
- Brief note in `proxy/agents/file_ops/COMPLETED.md`

**Success Criteria:**
- All file operations work correctly
- Security prevents directory traversal
- Error handling is comprehensive
- Tests pass
- Get it working first, perfect later

