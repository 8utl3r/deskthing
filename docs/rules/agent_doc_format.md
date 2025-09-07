# Agent Documentation Format

## File Structure Standards

### Project Context Format
```markdown
# Project Context: [Project Name]

## Overview
Brief description of project purpose and scope

## Architecture Summary
High-level technical architecture and key components

## Current State
- Repository path
- Git status
- Modified files
- Key components

## Session Records
### [Date] - [Session Title]
- **Date/Time**: [timestamp]
- **Objective**: [primary goal]
- **Key Decisions**: [important choices]
- **Actions Taken**: [what was done]
- **Next 3 Specific Steps**: [concrete next actions]
- **Blockers/Concerns**: [any issues]

## Next Steps
[Immediate next actions]

## Notes
[Additional context or important information]
```

### Rule Documentation Format
```markdown
# [Rule Name]

## scope
[What this rule applies to]

## triggers (any)
[When this rule is activated]

## required actions (in order)
[Step-by-step requirements]

## examples
[Concrete examples of compliance]

## compliance
[How to verify adherence]
```

## Naming Conventions
- **Files**: lowercase with underscores (`agent_doc_rule.md`)
- **Directories**: lowercase (`docs/rules/`)
- **Sections**: Title Case with colons
- **Code**: Follow language conventions

## Content Standards
- **Clarity**: Use clear, actionable language
- **Completeness**: Include all necessary information
- **Consistency**: Follow established patterns
- **Conciseness**: Be brief but comprehensive

## Version Control
- **Single Source**: One file per concept
- **Update in Place**: Modify existing files
- **Version History**: Include at top of files
- **Cross-References**: Link between related files
