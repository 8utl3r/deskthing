You are building the ConversationLogger component for Atlas proxy. This logs conversations to daily JSON files.

**FIRST STEP:** Create a file `proxy/agents/conversation_logger/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Log user queries, Atlas responses, executed commands, and variable updates to daily JSON files.

**Requirements:**
- Create `proxy/components/conversation_logger.py`
- Class should be named `ConversationLogger`
- Constructor: `__init__(self, history_dir: str, retention_days: int = 30)`
- Methods:
                                - `log_conversation(self, user_query: str, atlas_response: str, commands_executed: list[dict], variables_used: list[str] = None, variables_updated: dict = None) -> bool`
                                - `get_recent_conversations(self, n: int = 10) -> list[dict]` - Get last N conversations
                                - `cleanup_old_logs(self) -> int` - Delete logs older than retention_days

**Log Format:**
Daily files: `history/YYYY-MM-DD.json`
```json
[
  {
    "timestamp": "2025-01-06T22:00:00Z",
    "user": "Add task: Review proposal",
    "atlas": "Task added: Review proposal",
    "commands": [
      {
        "type": "FILE_CREATE",
        "path": "files/notes/task.md",
        "success": true,
        "message": "File created"
      }
    ],
    "variables_used": ["x", "y"],
    "variables_updated": {"new_var": "value"}
  }
]
```

