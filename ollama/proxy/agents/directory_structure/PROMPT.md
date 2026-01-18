# Directory Structure Setup Prompt

You are setting up the directory structure and initial data files for Atlas proxy.

**FIRST STEP:** Create a file `proxy/agents/directory_structure/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Ensure all directories exist and initial data files are properly initialized.

**Requirements:**
1. Verify/create all directories:
                                                - `proxy/components/` and `proxy/components/tests/`
                                                - `data/files/notes/`, `data/files/docs/`, `data/files/archive/`
                                                - `data/history/`

2. Create `.gitkeep` files in empty directories to preserve them in git:
                                                - `data/files/.gitkeep`
                                                - `data/files/notes/.gitkeep`
                                                - `data/files/docs/.gitkeep`
                                                - `data/files/archive/.gitkeep`
                                                - `data/history/.gitkeep`

3. Verify `data/variables.json` exists with proper structure:
   ```json
   {
     "_metadata": {
       "created": "2025-01-06T00:00:00Z",
       "updated": "2025-01-06T00:00:00Z"
     }
   }
   ```

4. Verify `data/.gitignore` exists and excludes user files but keeps structure

**Deliverables:**
- All directories created
- All `.gitkeep` files in place
- `data/variables.json` properly initialized
- `data/.gitignore` configured correctly
- Brief note in `proxy/agents/directory_structure/COMPLETED.md`

**Success Criteria:**
- All directories exist
- Empty directories preserved with `.gitkeep`
- Variables.json has valid JSON
- Gitignore prevents committing user data




