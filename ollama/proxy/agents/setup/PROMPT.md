You are setting up the Atlas proxy project structure. Create all directories and skeleton files needed for the project.

**FIRST STEP:** Create a file `proxy/agents/setup/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Create complete directory structure and initialize all skeleton files so other agents can start building components.

**Requirements:**

1. **Create Directory Structure:**
   - `proxy/components/` and `proxy/components/tests/`
   - `proxy/tests/`
   - `data/files/notes/`, `data/files/docs/`, `data/files/archive/`
   - `data/history/`
   - Agent workspaces:
     - `proxy/agents/config/`
     - `proxy/agents/variable_manager/`
     - `proxy/agents/file_ops/`
     - `proxy/agents/command_parser/`
     - `proxy/agents/context_injector/`
     - `proxy/agents/conversation_logger/`
     - `proxy/agents/http_proxy/`
     - `proxy/agents/integration/`
     - `proxy/agents/setup/` (your workspace)

2. **Create Skeleton Files:**
   - `proxy/components/__init__.py` (empty file)
   - `proxy/components/tests/__init__.py` (empty file)
   - `proxy/tests/__init__.py` (empty file)
   - `proxy/requirements.txt` with:
     ```
     fastapi>=0.104.0
     uvicorn>=0.24.0
     httpx>=0.25.0
     pydantic>=2.0.0
     ```
   - `data/variables.json` with:
     ```json
     {
       "_metadata": {
         "created": "2025-01-06T00:00:00Z",
         "updated": "2025-01-06T00:00:00Z"
       }
     }
     ```
   - `data/.gitignore` with rules to exclude user files but keep structure
   - `proxy/README.md` (placeholder with component list)

3. **Create .gitkeep Files:**
   - `data/files/.gitkeep`
   - `data/files/notes/.gitkeep`
   - `data/files/docs/.gitkeep`
   - `data/files/archive/.gitkeep`
   - `data/history/.gitkeep`

**Implementation Notes:**
- Use Python's `os.makedirs()` or `pathlib.Path.mkdir()` to create directories
- Create all directories recursively
- Write skeleton files with proper content
- Use `pathlib` for cross-platform path handling
- Verify all files are created successfully
- Work from `~/dotfiles/ollama/` directory

**Testing:**
- Verify all directories exist
- Verify all skeleton files exist with correct content
- Verify .gitkeep files are in empty directories
- Verify .gitignore is configured correctly
- Verify variables.json has valid JSON

**Deliverables:**
- Complete directory structure
- All skeleton files created
- All .gitkeep files in place
- .gitignore configured
- Brief note in `proxy/agents/setup/COMPLETED.md` listing what was created

**Success Criteria:**
- All directories exist
- All skeleton files have correct content
- Empty directories preserved with .gitkeep
- .gitignore prevents committing user data
- Project structure is ready for component development




