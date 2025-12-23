You are building the Config component for Atlas proxy. This component manages all configuration settings.

**FIRST STEP:** Create a file `proxy/agents/config/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Build a configuration manager that reads settings from:
1. Environment variables (highest priority)
2. Optional config file (JSON format)
3. Default values (lowest priority)

**Requirements:**
- Create `proxy/components/config.py`
- Class should be named `Config`
- Must provide these settings as properties:
                                - `ollama_url` (default: "http://localhost:11434")
                                - `proxy_port` (default: 11435)
                                - `data_dir` (default: expand "~/dotfiles/ollama/data")
                                - `files_dir` (default: data_dir + "/files")
                                - `history_dir` (default: data_dir + "/history")
                                - `allowed_extensions` (default: [".txt", ".md"])
                                - `max_file_size` (default: 10485760 = 10MB)
                                - `max_context_size` (default: 2000 characters)
                                - `log_retention_days` (default: 30)

**Implementation Notes:**
- Use `os.path.expanduser()` for ~ expansion
- Environment variables should use prefix `ATLAS_` (e.g., `ATLAS_PROXY_PORT`)
- Config file is optional - don't fail if missing
- All properties should be read-only (use @property)

**Testing:**
- Create `proxy/components/tests/test_config.py`
- Test default values
- Test environment variable override
- Test config file override
- Test path expansion

**Deliverables:**
- `proxy/components/config.py` (working implementation)
- `proxy/components/tests/test_config.py` (tests that pass)
- Brief note in `proxy/agents/config/COMPLETED.md` explaining your approach

**Success Criteria:**
- All properties return correct values
- Tests pass
- Code is clean and maintainable
- Works with env vars, file, and defaults

Focus on getting it working. We can refine later.

