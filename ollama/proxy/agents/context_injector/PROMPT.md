# Context Injector Setup Prompt

You are building the ContextInjector component for Atlas proxy. This loads file context and injects it into prompts.

**FIRST STEP:** Create a file `proxy/agents/context_injector/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Load file listings, recent files, directory structure and inject them into prompts along with variables.

**Requirements:**
- Create `proxy/components/context_injector.py`
- Class should be named `ContextInjector`
- Constructor: `__init__(self, files_dir: str, max_context_size: int = 2000)`
- Methods:
                                - `load_file_context(self) -> dict` - Load file structure and metadata
                                - `format_context(self, file_context: dict, variables: dict) -> str` - Format for prompt
                                - `inject_into_messages(self, messages: list[dict], context: str) -> list[dict]` - Inject into message list

**Context Format:**




