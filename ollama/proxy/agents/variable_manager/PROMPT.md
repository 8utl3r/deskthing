# Variable Manager Component Prompt

You are building the VariableManager component for Atlas proxy. This manages persistent variable storage.

**FIRST STEP:** Create a file `proxy/agents/variable_manager/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Build a component that loads variables from JSON, saves them atomically, formats them for prompts, and parses variable assignments from Atlas responses.

**Requirements:**
- Create `proxy/components/variable_manager.py`
- Class should be named `VariableManager`
- Constructor: `__init__(self, data_dir: str)`
- Methods:
                                - `load_variables(self) -> dict` - Load from variables.json, return empty dict if missing/invalid
                                - `save_variables(self, variables: dict) -> bool` - Save atomically (write to temp, then rename)
                                - `format_for_prompt(self, variables: dict) -> str` - Format as "**Variables**: x=10, y=3" (exclude _metadata)
                                - `parse_updates(self, response: str) -> dict` - Parse variable assignments like:
                                                                - "x = 10" or "x equals 10"
                                                                - "set y to 3"
                                                                - "remember z is 5"
    Return dict like {"x": 10, "y": 3}

**Implementation Notes:**
- Use atomic writes: write to temp file, then rename (prevents corruption)
- Create backup before saving (copy to .backup file)
- Handle missing file gracefully (return empty dict)
- Handle invalid JSON gracefully (return empty dict, log error)
- Exclude `_metadata` from prompt formatting
- Use regex or string matching for parsing assignments

**Testing:**
- Create `proxy/components/tests/test_variable_manager.py`
- Test load when file doesn't exist
- Test load when file is invalid JSON
- Test save creates file correctly
- Test atomic write (verify temp file pattern)
- Test format_for_prompt excludes metadata
- Test parse_updates with various formats

**Deliverables:**
- `proxy/components/variable_manager.py` (working implementation)
- `proxy/components/tests/test_variable_manager.py` (tests that pass)
- Brief note in `proxy/agents/variable_manager/COMPLETED.md`

**Success Criteria:**
- Variables persist across sessions
- Parsing handles various formats
- Error handling is robust
- Tests pass
- Code works - perfection can come later




