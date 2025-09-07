# Agent Documentation Rule

## Purpose
Establish consistent documentation standards for AI agent interactions and project management.

## Scope
Applies to all project documentation, session records, and rule compliance tracking.

## Documentation Requirements

### Project Context File
- **Location**: `project_context.md` in project root
- **Content**: Overview, architecture, current state, session records
- **Updates**: Required at session start/end and after significant changes

### Session Records Format
- **Date/Time**: When session occurred
- **Objective**: Primary goal for the session
- **Key Decisions**: Important choices made
- **Actions Taken**: What was accomplished
- **Next 3 Specific Steps**: Concrete next actions
- **Blockers/Concerns**: Any issues or dependencies

### Rule Documentation
- **Location**: `docs/rules/` directory
- **Files**: Individual rule files with clear triggers and requirements
- **Compliance**: Mandatory adherence to all documented rules

## Standards
- Keep files ≤200 lines (split if exceeded)
- Use lowercase filenames with underscores
- Maintain single source of truth principle
- Update in place rather than creating duplicates

## Compliance
- All documentation must be created before making changes
- Session records must be updated after each significant action
- Rule violations must be documented immediately
- Documentation must be committed with appropriate messages
