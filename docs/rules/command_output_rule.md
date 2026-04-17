# Command Output Rule

## Version History
- 2026-02-08: Initial rule.

## Requirement
- When providing commands or scripts for the user to run, always output results to a file the agent can read.
- Do not rely on the user pasting long terminal output into the chat.

## For Scripts
- Scripts must write detailed output to a file (e.g. `docs/hardware/`, `scripts/` output, or user-specified path).
- Use Rich dashboards for interactive feedback; write full output to file for agent analysis.
- Default output paths should be predictable.

## For One-Off Commands
- Prefer wrapping in a script that outputs to file.
- Or instruct: `command > path/to/output.txt 2>&1` so the agent can read the result.

## For Code Blocks
- No comments in shell command code blocks.
- Each command in its own code block unless they should be pasted and run together.
