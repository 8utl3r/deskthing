# Atlas CRUD Capabilities - Implementation Plan

## Overview

Give Atlas the ability to Create, Read, Update, and Delete:
1. **Text Files** (.txt, .md) - Simple file operations
2. **Structured Data** (tasks, notes, events, etc.) - JSON-based data management

## Core Requirements

### File Operations (Priority 1 - Simplest)
- **Create**: Create new .txt or .md files
- **Read**: Read existing files
- **Update**: Edit/append to files
- **Delete**: Remove files
- **List**: List files in directory

### Structured Data (Priority 2)
- Tasks/Todos
- Notes (can also use files)
- Calendar Events
- Reminders
- Projects
- Goals
- Contacts/People

**Operations**:
- **Create**: Add new items
- **Read**: Query and list existing items
- **Update**: Modify existing items
- **Delete**: Remove items

## Architecture Options

### Option 1: File-Based with Context Injection (Simplest)

**How It Works**:
1. Store data in JSON files: `ollama/data/tasks.json`, `notes.json`, `events.json`
2. Proxy loads relevant data files into context before each query
3. Atlas sees current data and can reference it
4. Atlas outputs structured JSON for changes
5. Proxy parses output and updates files

**Pros**:
- Simple, no database needed
- Easy to backup (just files)
- Works with any client (via proxy)
- Atlas has full context of data

**Cons**:
- Large files slow down context loading
- No concurrent access handling
- Manual parsing of Atlas output

**Example Flow**:
```
User: "Add task: Review project proposal"
  ↓
Proxy loads tasks.json into context
  ↓
Atlas sees: "Current tasks: [...]"
  ↓
Atlas outputs: "**CREATE_TASK**: {\"id\": \"...\", \"title\": \"Review project proposal\", ...}"
  ↓
Proxy parses, updates tasks.json
  ↓
Response: "Task added"
```

### Option 2: Structured Commands (More Reliable)

**How It Works**:
1. Atlas outputs structured commands in a specific format
2. Proxy has a command parser/interpreter
3. Commands are executed, files updated
4. Atlas gets confirmation

**Command Format**:
```
**ATLAS_CMD**: CREATE task {"title": "...", "priority": "high"}
**ATLAS_CMD**: UPDATE task abc123 {"status": "done"}
**ATLAS_CMD**: DELETE task abc123
**ATLAS_CMD**: LIST tasks WHERE status="pending"
```

**Pros**:
- More reliable parsing
- Clear separation of intent and execution
- Easier to debug
- Can add validation

**Cons**:
- Requires command parser
- Slightly more complex

### Option 3: Tool Calling (If Supported)

**How It Works**:
- Use Ollama's function calling (if available)
- Atlas calls functions: `create_task()`, `update_task()`, etc.
- Functions execute and return results

**Pros**:
- Native LLM capability
- Most reliable
- Type-safe

**Cons**:
- Requires Ollama function calling support
- More complex implementation

## Recommended: Option 2 (Structured Commands)

**Why**: Balances simplicity with reliability. Atlas outputs clear commands, proxy executes them.

## Implementation

### File Operations (Start Here - Simplest)

**File Storage**:
```
ollama/data/
├── files/              # User-created files
│   ├── notes/         # Notes directory
│   ├── docs/          # Documentation
│   └── ...            # Any structure Atlas creates
```

**Command Format for Files**:
```
**FILE_CREATE** path/to/file.md "content here"
**FILE_READ** path/to/file.md
**FILE_UPDATE** path/to/file.md "new content" (replace) or "append content" (append)
**FILE_DELETE** path/to/file.md
**FILE_LIST** path/to/directory
```

**Example**:
```
User: "Create a file called meeting-notes.md with today's meeting summary"
Atlas: "**FILE_CREATE** files/notes/meeting-notes.md \"# Meeting Notes - 2025-12-17\n\n...\"\n\nFile created: files/notes/meeting-notes.md"
```

### Structured Data Structure

**File Organization**:
```
ollama/data/
├── files/              # Text files (.txt, .md)
│   └── notes/         # User notes
├── tasks.json          # Task list
├── events.json         # Calendar events
├── reminders.json      # Reminders
├── projects.json       # Projects
└── contacts.json       # People/contacts
```

**Task Format** (`tasks.json`):
```json
{
  "tasks": [
    {
      "id": "task_20251217_001",
      "title": "Review project proposal",
      "status": "pending",
      "priority": "high",
      "created": "2025-12-17T10:00:00Z",
      "due": "2025-12-20T17:00:00Z",
      "tags": ["work", "urgent"]
    }
  ]
}
```

### Atlas System Prompt Addition

Add to `system_prompt.txt`:

```
**File Operations**:
- You can create, read, update, and delete text files (.txt, .md).
- Use the following command format:

**FILE_CREATE** [path] "[content]"
**FILE_READ** [path]
**FILE_UPDATE** [path] "[content]" (replaces entire file)
**FILE_APPEND** [path] "[content]" (adds to end)
**FILE_DELETE** [path]
**FILE_LIST** [directory path]

Examples:
- "**FILE_CREATE** files/notes/project-ideas.md \"# Project Ideas\n\n- Idea 1\n- Idea 2\""
- "**FILE_READ** files/notes/project-ideas.md"
- "**FILE_APPEND** files/notes/project-ideas.md \"\n- Idea 3\""
- "**FILE_DELETE** files/notes/old-note.md"

Paths are relative to ollama/data/. Use forward slashes.
Content should be properly formatted (markdown, plain text, etc.).

**Structured Data Operations**:
- You can create, read, update, and delete structured data.
- Use the following command format:

**CREATE** [type] [data]
**READ** [type] [filter/query]
**UPDATE** [type] [id] [changes]
**DELETE** [type] [id]

Examples:
- "**CREATE** task {\"title\": \"Review proposal\", \"priority\": \"high\"}"
- "**READ** tasks WHERE status=\"pending\""
- "**UPDATE** task task_123 {\"status\": \"done\"}"
- "**DELETE** task task_123"

When outputting commands, format them clearly on separate lines.
After the command, provide a brief confirmation message.
```

### Proxy Implementation

**Proxy Responsibilities**:
1. Load relevant data files into context (based on user query)
2. Inject data into prompt: "**Current Data**: [JSON]"
3. Forward to Ollama
4. Parse Atlas response for `**ATLAS_CMD**:` markers
5. Execute commands (update JSON files)
6. Return response to user

**Command Parser**:
```javascript
// Parse file commands:
// **FILE_CREATE** path "content"
// **FILE_READ** path
// **FILE_UPDATE** path "content"
// **FILE_APPEND** path "content"
// **FILE_DELETE** path
// **FILE_LIST** directory

// Parse structured data commands:
// **CREATE** type {...}
// **UPDATE** type id {...}
// **DELETE** type id
// **READ** type WHERE ...

function parseAtlasCommand(response) {
  // File operations
  const fileCmdRegex = /\*\*FILE_(\w+)\*\*\s+([^\s"]+)\s+"([^"]*)"/;
  
  // Structured data
  const dataCmdRegex = /\*\*(\w+)\*\*\s+(\w+)\s+(.*)/;
  
  // Extract and execute
}
```

**File Operation Implementation**:
```javascript
function executeFileCommand(cmd, path, content) {
  const basePath = path.join(process.env.HOME, 'dotfiles/ollama/data');
  const fullPath = path.join(basePath, filePath);
  
  switch(cmd) {
    case 'CREATE':
      fs.writeFileSync(fullPath, content, 'utf8');
      break;
    case 'READ':
      return fs.readFileSync(fullPath, 'utf8');
    case 'UPDATE':
      fs.writeFileSync(fullPath, content, 'utf8');
      break;
    case 'APPEND':
      fs.appendFileSync(fullPath, content, 'utf8');
      break;
    case 'DELETE':
      fs.unlinkSync(fullPath);
      break;
    case 'LIST':
      return fs.readdirSync(fullPath);
  }
}
```

## Example Interactions

### File Operations

**User**: "Create a file called meeting-notes.md with today's meeting summary"

**Atlas Response**:
```
**FILE_CREATE** files/notes/meeting-notes.md "# Meeting Notes - 2025-12-17

## Attendees
- John
- Jane

## Discussion
- Project timeline
- Budget approval

## Action Items
- [ ] Review proposal by Friday
- [ ] Schedule follow-up"

File created: files/notes/meeting-notes.md
```

**User**: "Read the meeting notes from today"

**Atlas Response**:
```
**FILE_READ** files/notes/meeting-notes.md

[Proxy reads file and includes content in response, or Atlas references it]
```

**User**: "Add a new action item to the meeting notes"

**Atlas Response**:
```
**FILE_APPEND** files/notes/meeting-notes.md "\n- [ ] Send follow-up email"

Action item added.
```

### Structured Data Operations

**User**: "Add a task to review the project proposal by Friday"

**Atlas Response**:
```
**CREATE** task {"title": "Review project proposal", "due": "2025-12-20T17:00:00Z", "priority": "high"}

Task added: Review project proposal (due Friday)
```

**User**: "What tasks are pending?"

**Atlas Response**:
```
**READ** tasks WHERE status="pending"

Pending tasks:
1. Review project proposal (due Friday) - High priority
2. Update documentation - Medium priority
```

**User**: "Mark the proposal review as done"

**Atlas Response**:
```
**UPDATE** task task_20251217_001 {"status": "done"}

Task marked complete: Review project proposal
```

## Data Types and Schemas

### Tasks
```json
{
  "id": "string (auto-generated)",
  "title": "string",
  "status": "pending|in-progress|done|cancelled",
  "priority": "low|medium|high",
  "created": "ISO 8601 timestamp",
  "due": "ISO 8601 timestamp (optional)",
  "tags": ["array of strings"],
  "notes": "string (optional)"
}
```

### Notes
```json
{
  "id": "string (auto-generated)",
  "title": "string",
  "content": "string",
  "created": "ISO 8601 timestamp",
  "updated": "ISO 8601 timestamp",
  "tags": ["array of strings"]
}
```

### Events
```json
{
  "id": "string (auto-generated)",
  "title": "string",
  "start": "ISO 8601 timestamp",
  "end": "ISO 8601 timestamp",
  "location": "string (optional)",
  "description": "string (optional)",
  "reminder": "ISO 8601 timestamp (optional)"
}
```

## Next Steps

### Phase 1: File Operations (Start Here)
1. **Update system prompt** with file operation commands
2. **Implement proxy file command parser**
3. **Create data/files/ directory structure**
4. **Test file create/read/update/delete**

### Phase 2: Structured Data (Later)
1. **Define data schemas** for all types
2. **Add structured data commands to system prompt**
3. **Implement structured data parser**
4. **Create initial JSON files** (empty structures)
5. **Test with simple operations**

## Questions

1. **File Storage**: Where should files be stored? (`ollama/data/files/` or user-specified?)
2. **File Organization**: Should Atlas create subdirectories automatically? (notes/, docs/, etc.)
3. **Path Safety**: Should proxy validate paths to prevent writing outside data directory?
4. **Data Types**: Which structured types are most important? (Tasks, Notes, Events?)
5. **Query Language**: Simple WHERE clauses, or more complex?
6. **Validation**: Should proxy validate data before saving?
7. **Backup**: Auto-backup before writes?

