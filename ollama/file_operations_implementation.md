# Atlas File Operations - Implementation Details

## Overview

How Atlas reads, edits, looks up, archives, deletes, moves, organizes, and manipulates files through the proxy system.

## Architecture

```
User Query → Proxy → Ollama (Atlas) → Proxy → File Operations → Response
```

**Flow**:
1. User sends query to proxy
2. Proxy forwards to Ollama with current file context
3. Atlas processes query and outputs commands
4. Proxy parses commands and executes file operations
5. Proxy returns results to user

## Command System

### Command Format

Atlas outputs commands in a structured format that the proxy parses:

```
**FILE_[OPERATION]** [path] [options] "[content]"
```

### Supported Operations

#### Basic Operations
- **FILE_CREATE** - Create new file
- **FILE_READ** - Read file content
- **FILE_UPDATE** - Replace entire file
- **FILE_APPEND** - Add to end of file
- **FILE_DELETE** - Delete file

#### Advanced Operations
- **FILE_MOVE** - Move/rename file
- **FILE_COPY** - Copy file
- **FILE_SEARCH** - Search file contents
- **FILE_LIST** - List directory contents
- **FILE_ARCHIVE** - Move to archive directory
- **FILE_ORGANIZE** - Move to organized structure

## Implementation Details

### 1. Context Injection

Before each query, proxy loads relevant file context:

```javascript
// Proxy loads file listings and recent file contents
const context = {
  files: listFiles('ollama/data/files/'),
  recent: getRecentFiles(5), // Last 5 accessed
  structure: getDirectoryStructure('ollama/data/files/')
};

// Inject into prompt
const prompt = `
**Current File Context**:
${JSON.stringify(context, null, 2)}

User: ${userQuery}
`;
```

### 2. Command Parsing

Proxy parses Atlas response for file commands:

```javascript
function parseFileCommands(response) {
  const commands = [];
  
  // Match all FILE_* commands
  const cmdRegex = /\*\*FILE_(\w+)\*\*\s+([^\s"]+)(?:\s+"([^"]*)")?/g;
  let match;
  
  while ((match = cmdRegex.exec(response)) !== null) {
    commands.push({
      operation: match[1],
      path: match[2],
      content: match[3] || null
    });
  }
  
  return commands;
}
```

### 3. Command Execution

Proxy executes commands and updates files:

```javascript
const path = require('path');
const fs = require('fs');

const DATA_DIR = path.join(process.env.HOME, 'dotfiles/ollama/data');

function executeFileCommand(cmd) {
  const fullPath = path.join(DATA_DIR, cmd.path);
  
  // Security: Ensure path is within DATA_DIR
  if (!fullPath.startsWith(DATA_DIR)) {
    throw new Error('Path outside allowed directory');
  }
  
  switch(cmd.operation) {
    case 'CREATE':
      ensureDirectory(path.dirname(fullPath));
      fs.writeFileSync(fullPath, cmd.content, 'utf8');
      return { success: true, message: `File created: ${cmd.path}` };
      
    case 'READ':
      const content = fs.readFileSync(fullPath, 'utf8');
      return { success: true, content: content };
      
    case 'UPDATE':
      fs.writeFileSync(fullPath, cmd.content, 'utf8');
      return { success: true, message: `File updated: ${cmd.path}` };
      
    case 'APPEND':
      fs.appendFileSync(fullPath, cmd.content, 'utf8');
      return { success: true, message: `Content appended: ${cmd.path}` };
      
    case 'DELETE':
      fs.unlinkSync(fullPath);
      return { success: true, message: `File deleted: ${cmd.path}` };
      
    case 'MOVE':
      const newPath = path.join(DATA_DIR, cmd.content); // content = new path
      ensureDirectory(path.dirname(newPath));
      fs.renameSync(fullPath, newPath);
      return { success: true, message: `File moved: ${cmd.path} → ${cmd.content}` };
      
    case 'COPY':
      const copyPath = path.join(DATA_DIR, cmd.content);
      ensureDirectory(path.dirname(copyPath));
      fs.copyFileSync(fullPath, copyPath);
      return { success: true, message: `File copied: ${cmd.path} → ${cmd.content}` };
      
    case 'SEARCH':
      const files = searchInFiles(DATA_DIR, cmd.content); // content = search term
      return { success: true, results: files };
      
    case 'LIST':
      const items = fs.readdirSync(fullPath, { withFileTypes: true });
      return { success: true, items: items.map(i => ({
        name: i.name,
        type: i.isDirectory() ? 'directory' : 'file'
      })) };
      
    case 'ARCHIVE':
      const archivePath = path.join(DATA_DIR, 'archive', path.basename(cmd.path));
      ensureDirectory(path.dirname(archivePath));
      fs.renameSync(fullPath, archivePath);
      return { success: true, message: `File archived: ${cmd.path}` };
      
    case 'ORGANIZE':
      // Move file to organized structure based on content/type
      const organizedPath = determineOrganizedPath(cmd.path, cmd.content);
      ensureDirectory(path.dirname(organizedPath));
      fs.renameSync(fullPath, organizedPath);
      return { success: true, message: `File organized: ${cmd.path} → ${organizedPath}` };
  }
}
```

### 4. Search Implementation

```javascript
function searchInFiles(rootDir, searchTerm) {
  const results = [];
  
  function searchDirectory(dir) {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const item of items) {
      const fullPath = path.join(dir, item.name);
      
      if (item.isDirectory()) {
        searchDirectory(fullPath);
      } else if (item.isFile() && (item.name.endsWith('.txt') || item.name.endsWith('.md'))) {
        const content = fs.readFileSync(fullPath, 'utf8');
        if (content.includes(searchTerm)) {
          results.push({
            path: path.relative(DATA_DIR, fullPath),
            matches: content.split(searchTerm).length - 1,
            preview: extractPreview(content, searchTerm)
          });
        }
      }
    }
  }
  
  searchDirectory(rootDir);
  return results;
}
```

### 5. Response Handling

Proxy processes Atlas response and executes commands:

```javascript
async function handleAtlasQuery(userQuery) {
  // 1. Load context
  const context = loadFileContext();
  
  // 2. Forward to Ollama
  const atlasResponse = await queryOllama(userQuery, context);
  
  // 3. Parse commands
  const commands = parseFileCommands(atlasResponse);
  
  // 4. Execute commands
  const results = [];
  for (const cmd of commands) {
    try {
      const result = executeFileCommand(cmd);
      results.push(result);
    } catch (error) {
      results.push({ success: false, error: error.message });
    }
  }
  
  // 5. Format response
  const response = formatResponse(atlasResponse, results);
  
  return response;
}
```

## Example Workflows

### Reading a File

**User**: "What's in meeting-notes.md?"

**Flow**:
1. Proxy loads file listing context
2. Atlas sees file exists
3. Atlas outputs: `**FILE_READ** files/notes/meeting-notes.md`
4. Proxy reads file
5. Proxy includes content in response or Atlas references it

**Atlas Response**:
```
**FILE_READ** files/notes/meeting-notes.md

[File content displayed]
```

### Editing a File

**User**: "Add 'Follow up on budget' to meeting-notes.md"

**Flow**:
1. Proxy loads file context
2. Atlas outputs: `**FILE_APPEND** files/notes/meeting-notes.md "\n- Follow up on budget"`
3. Proxy appends to file
4. Atlas confirms

**Atlas Response**:
```
**FILE_APPEND** files/notes/meeting-notes.md "\n- Follow up on budget"

Added to meeting-notes.md
```

### Searching Files

**User**: "Find all files mentioning 'budget'"

**Flow**:
1. Atlas outputs: `**FILE_SEARCH** files/ "budget"`
2. Proxy searches all files
3. Proxy returns results
4. Atlas formats results

**Atlas Response**:
```
**FILE_SEARCH** files/ "budget"

Found in:
- files/notes/meeting-notes.md (3 matches)
- files/docs/project-plan.md (1 match)
```

### Organizing Files

**User**: "Move all old notes to archive"

**Flow**:
1. Atlas identifies old files from context
2. For each file: `**FILE_ARCHIVE** files/notes/old-note.md`
3. Proxy moves files to archive/
4. Atlas confirms

**Atlas Response**:
```
**FILE_ARCHIVE** files/notes/old-note-1.md
**FILE_ARCHIVE** files/notes/old-note-2.md

Archived 2 files.
```

### Moving/Renaming

**User**: "Rename project-ideas.md to ideas-2025.md"

**Flow**:
1. Atlas outputs: `**FILE_MOVE** files/notes/project-ideas.md "files/notes/ideas-2025.md"`
2. Proxy renames file
3. Atlas confirms

**Atlas Response**:
```
**FILE_MOVE** files/notes/project-ideas.md "files/notes/ideas-2025.md"

File renamed.
```

## System Prompt Integration

Atlas needs to understand file operations. Add to `system_prompt.txt`:

```
**File Operations**:
You can manipulate files (.txt, .md) using these commands:

**FILE_CREATE** [path] "[content]" - Create new file
**FILE_READ** [path] - Read file content
**FILE_UPDATE** [path] "[content]" - Replace entire file
**FILE_APPEND** [path] "[content]" - Add to end of file
**FILE_DELETE** [path] - Delete file
**FILE_MOVE** [path] "[new_path]" - Move/rename file
**FILE_COPY** [path] "[new_path]" - Copy file
**FILE_SEARCH** [directory] "[term]" - Search for text in files
**FILE_LIST** [directory] - List files/directories
**FILE_ARCHIVE** [path] - Move to archive/
**FILE_ORGANIZE** [path] "[category]" - Organize into structure

Paths are relative to ollama/data/. Use forward slashes.
Always output commands on separate lines, then provide confirmation.
```

## Security Considerations

1. **Path Validation**: Ensure all paths stay within `ollama/data/`
2. **File Type Restrictions**: Only allow .txt, .md files (configurable)
3. **Size Limits**: Limit file sizes to prevent memory issues
4. **Backup**: Auto-backup before destructive operations (DELETE, MOVE)

## Error Handling

```javascript
function executeFileCommand(cmd) {
  try {
    // Validate path
    if (!isValidPath(cmd.path)) {
      throw new Error('Invalid path');
    }
    
    // Check file exists (for operations that require it)
    if (['READ', 'UPDATE', 'DELETE', 'MOVE', 'COPY'].includes(cmd.operation)) {
      if (!fs.existsSync(fullPath)) {
        throw new Error('File not found');
      }
    }
    
    // Execute operation
    return executeOperation(cmd);
    
  } catch (error) {
    return {
      success: false,
      error: error.message,
      operation: cmd.operation,
      path: cmd.path
    };
  }
}
```

## Next Steps

1. Implement proxy with command parser
2. Add file operation functions
3. Update system prompt with file commands
4. Test each operation
5. Add error handling and validation
6. Implement backup system

