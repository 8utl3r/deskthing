# CommandParser Component Prompt

You are building the CommandParser component for Atlas proxy. This parses structured commands from Atlas responses.

**FIRST STEP:** Create a file `proxy/agents/command_parser/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Extract FILE_* commands and variable assignments from Atlas response text.

**Requirements:**
- Create `proxy/components/command_parser.py`
- Class should be named `CommandParser`
- Methods:
                                - `parse_file_commands(self, response: str) -> list[dict]` - Parse all FILE_* commands
                                - `parse_variable_commands(self, response: str) -> list[dict]` - Parse variable assignments
                                - `extract_commands(self, response: str) -> dict` - Extract all commands, return:
    ```python
    {
      "file_commands": [...],
      "variable_commands": [...],
      "clean_response": "response with commands removed"
    }
    ```

**Command Formats to Parse:**

**FILE_CREATE:** `**FILE_CREATE** path "content"`
**FILE_READ:** `**FILE_READ** path`
**FILE_UPDATE:** `**FILE_UPDATE** path "content"`
**FILE_APPEND:** `**FILE_APPEND** path "content"`
**FILE_DELETE:** `**FILE_DELETE** path`
**FILE_MOVE:** `**FILE_MOVE** old_path "new_path"`
**FILE_COPY:** `**FILE_COPY** src_path "dst_path"`
**FILE_SEARCH:** `**FILE_SEARCH** directory "term"`
**FILE_LIST:** `**FILE_LIST** directory`
**FILE_ARCHIVE:** `**FILE_ARCHIVE** path`

**Variable Formats:**
- "x = 10" or "x equals 10"
- "set y to 3"
- "remember z is 5"

**Parsing Notes:**
- Commands can be on their own line or mixed with text
- Content strings can span multiple lines if properly quoted
- Handle escaped quotes in content
- Extract command type, path, content, options
- Return structured dicts for each command

**Testing:**
- Create `proxy/components/tests/test_command_parser.py`
- Test parsing each command type
- Test multi-line content
- Test escaped quotes
- Test multiple commands in one response
- Test commands mixed with regular text
- Test variable assignment patterns

**Deliverables:**
- `proxy/components/command_parser.py` (working implementation)
- `proxy/components/tests/test_command_parser.py` (tests that pass)
- Brief note in `proxy/agents/command_parser/COMPLETED.md`

**Success Criteria:**
- Parses all command types correctly
- Handles edge cases (multi-line, escaped quotes)
- Extracts commands reliably
- Tests pass
- Works reliably - refine edge cases later




