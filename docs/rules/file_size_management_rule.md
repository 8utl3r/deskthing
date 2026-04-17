# File Size Management Rule

## Version History
- 2026-01-20: Added canonical rule file.
- 2026-02-23: Removed hard line-count limits; switched to readability-first guidance.

## policy
There is no fixed maximum line count. File length is a quality signal, not a hard gate.

Split documents when readability, maintainability, or navigation would clearly improve.

## review triggers (guidance)
Use these as prompts to evaluate a split, not mandatory thresholds:

- file is hard to scan in one pass
- unrelated concepts are mixed in one file
- edits frequently touch isolated sections that can stand alone
- internal linking/indexing would materially improve discoverability

## split process
1. analyze for semantic boundaries (sections/topics).
2. create new files with descriptive names; do not use numeric suffixes unless required for ordering.
3. update internal links and add a short index when splitting across more than one file.
4. update any parent index or `README.md` pointers.

## compliance
- verify link integrity after split.
- ensure each file is independently readable.
- prefer one concept per file when practical.

## example
- file `docs/architecture.md` has multiple distinct sections:
 - plan split into `architecture_overview.md` and `architecture_components.md`.
 - move component details; keep diagrams index in overview file.
 - update links in `README.md`.
