# Context Injector Workflow - Keyword-Weighted Relationship Discovery

## Core Purpose

Automatically excavate relationships in stored data by identifying files/memories that relate to the conversation topic, without requiring manual tagging or organization. The system uses keyword mention counts to weight importance and surface relevant context hierarchically.

**Note: This is a Keyword-Based Retrieval system, not True RAG**

This system uses **exact keyword matching** and **tag-based indexing**, not semantic embeddings. For comparison with true RAG (Retrieval-Augmented Generation), see `RAG_VS_KEYWORD_SYSTEM.md`.

**Key Difference:**
- **True RAG**: Uses semantic embeddings to find conceptually similar content (e.g., "authentication" finds "login", "credentials")
- **This System**: Uses keyword matching to find files with exact tag matches (e.g., "authentication" only finds files tagged `tag:authentication`)

**Advantages of This Approach:**
- Fast, lightweight (no embedding model or vector DB)
- Deterministic (same keywords always find same files)
- Explicit control via tagging
- Low resource usage

**Limitations:**
- Requires explicit tagging (`tag:keyword` patterns)
- Misses conceptually related but differently-worded content
- No synonym handling (e.g., "car" won't find "automobile" unless both tagged)

## Workflow Overview

### Phase 1: Keyword Extraction & Counting

**Implementation: Pure Script-Based (No Agent Required)**

This phase uses deterministic text processing - no AI/LLM needed. It's a simple script that:
- Uses regex for pattern matching
- Uses Python `Counter` for counting
- Uses set lookups for stop word filtering
- Uses length checks for filtering

**Practical Implementation Methods:**

1. **Text Extraction (Case-Sensitive):**
   - **Preserve original case** to distinguish concepts (e.g., "RED" movie vs "red" color)
   - Use regex pattern `\b[a-zA-Z]+\b` to extract word boundaries (whole words only)
   - This ensures "red" matches "red" but not "redirect" or "bred"
   - Captures "RED", "Red", "red" as separate keywords for disambiguation
   - Also captures acronyms like "AI", "ai", "API", etc. preserving case
   
   **Why case-sensitive?**
   - "RED" (movie) and "red" (color) are different concepts
   - "Apple" (company) and "apple" (fruit) are different concepts
   - Preserving case allows tracking these distinctions in conversation
   
   **Tag matching is case-insensitive:**
   - Tags like `tag:red` or `tag:RED` match both "RED" and "red" keywords
   - This allows flexible tagging while preserving conversation distinctions

2. **Stop Word Filtering:**
   - Filter out common English stop words (the, a, an, and, or, but, in, on, at, to, for, etc.)
   - Filter out pronouns (I, you, he, she, it, we, they)
   - Filter out question words (what, which, who, when, where, why, how)
   - Filter out auxiliary verbs (is, are, was, were, be, been, being, have, has, had, do, does, did, will, would, could, should, may, might, must, can)

3. **Length Filtering:**
   - **Only filter out single-letter words** (e.g., "a", "i")
   - **Preserve 2+ character words** including acronyms (AI, API, UI, etc.)
   - This ensures important acronyms like "AI" are not filtered out

4. **Counting Method:**
   - Use Python `Counter` class for efficient counting
   - Count across ALL messages in conversation history (both user and assistant)
   - Each occurrence increments the count (e.g., "red" mentioned 3 times = red:3)

5. **Output Format:**
   - Dictionary mapping keyword (preserving case) -> count: `{"RED": 5, "red": 68, "blue": 50, "flag": 150, "AI": 25}`
   - Case variants are tracked separately: `{"RED": 5, "red": 68}` means "RED" mentioned 5 times, "red" mentioned 68 times

**Example:**
```
Input messages:
- "I need a recipe for red velvet cake"
- "The red color is important"
- "Red is my favorite color"
- "Have you seen RED? It's a great movie"

Output: {"red": 2, "Red": 1, "RED": 1, "recipe": 1, "velvet": 1, "cake": 1, "color": 2, "important": 1, "favorite": 1}

Note: "red", "Red", and "RED" are tracked separately, allowing distinction between
the color (red/Red) and the movie (RED). Tag matching is case-insensitive, so
tag:red matches all three variants.
```

**Why:** The mention count represents how important/relevant each keyword is to the current conversation. Higher counts = more central to the topic.

**Problems Avoided with Case-Sensitive Extraction:**
- **Concept Disambiguation**: "RED" (movie) and "red" (color) are tracked separately, allowing the system to distinguish context
- **Proper Noun Preservation**: "Apple" (company) vs "apple" (fruit) are different concepts
- **Acronym Clarity**: "AI" (artificial intelligence) vs "ai" (lowercase variant) can be distinguished if needed
- **Tag Matching Flexibility**: Tags remain case-insensitive (`tag:red` matches "RED", "Red", "red"), so tagging is flexible while conversation tracking is precise

### Phase 2: Tag Index Building

**What happens:**
- Scan all files in `data/files/` for `tag:keyword` patterns
- Use regex pattern `tag:(\w+)` (case-insensitive) to find tags
- Normalize tags to lowercase for indexing: `tag:red`, `tag:RED`, `tag:Red` all map to `red`
- Build an inverted index: `tag (lowercase) -> [list of files containing that tag]`
- Cache this index (refreshes every 60 seconds)

**Case-insensitive tag matching:**
- Tags are normalized to lowercase for indexing
- `tag:red`, `tag:RED`, `tag:Red` all match conversation keywords "red", "RED", "Red"
- This allows flexible tagging while preserving case distinctions in conversation

**Example index:**
```
tag:red -> [file1.md, file3.md, file7.md]
tag:flag -> [file1.md, file2.md, file5.md]
tag:national_security -> [file2.md, file5.md]
tag:puppies -> [file8.md]
```

**Why:** This allows fast lookup of which files relate to which keywords.

### Phase 3: File Scoring & Ranking (CORRECTED)

**What happens:**
- For each file that matches at least one conversation keyword (via tags):
  1. Find which conversation keywords it matches (case-insensitive tag matching)
  2. **Count how many times each matched keyword appears IN THE FILE** (case-insensitive counting)
     - File counting is case-insensitive: "RED" and "red" in file both count toward "red" keyword
     - But original keyword case is preserved for tracking
  3. Calculate relevance score:
     - **PRIMARY**: Multi-keyword matching - `number_of_matched_keywords * 10000` (files matching more keywords rank much higher)
     - **BONUS**: File keyword frequency - For each matched keyword, multiply `conversation_count * file_count`
     - **Formula**: `score = (num_matched_keywords * 10000) + sum(conversation_count * file_count)`
  4. Rank files by score (highest first)

**Why this matters:**
If conversation has `red:1, blue:139`:
- File with `red:999, blue:1` → score includes `(1 * 999) + (139 * 1) = 1138`
- File with `red:1, blue:999` → score includes `(1 * 1) + (139 * 999) = 138,862`

The second file scores much higher because it has high counts of the highly-mentioned keyword (blue:139), making it more aligned with conversation context.

**Example scoring:**
```
Conversation keywords: red:68, blue:50, flag:150, national_security:84

File1.md: matches [red, flag] via tags
  - Count keywords in file: red appears 20 times, flag appears 5 times
  - Matched keywords: 2
  - Weighted products: (68 * 20) + (150 * 5) = 1360 + 750 = 2110
  - Score: (2 * 10000) + 2110 = 22110

File2.md: matches [flag, national_security] via tags
  - Count keywords in file: flag appears 100 times, national_security appears 50 times
  - Matched keywords: 2
  - Weighted products: (150 * 100) + (84 * 50) = 15000 + 4200 = 19200
  - Score: (2 * 10000) + 19200 = 39200

File3.md: matches [red, blue, flag, national_security] via tags
  - Count keywords in file: red appears 1 time, blue appears 1 time, flag appears 1 time, national_security appears 1 time
  - Matched keywords: 4
  - Weighted products: (68 * 1) + (50 * 1) + (150 * 1) + (84 * 1) = 352
  - Score: (4 * 10000) + 352 = 40352
```

**Ranking order:** File3.md (40352) > File2.md (39200) > File1.md (22110)

**Why:** 
- Files matching MORE keywords rank highest (File3 with 4 matches beats File2 with 2 matches)
- File keyword frequency is a tiebreaker (File2 beats File1 because both match 2 keywords, but File2 has higher frequency)
- Multi-keyword matching is PRIMARY - a file matching 3 keywords always beats a file matching 1 keyword, regardless of frequency

### Phase 4: Hierarchical Context Injection & Automatic Tagging

**Context Injection:**
- Load file content in order of relevance score (highest first)
- Inject files until `max_context_size` limit is reached
- If a file would exceed the limit, truncate it or skip it
- Format: Show which keywords triggered each file (with conversation and file counts), then the file content

**Example injection:**
```
**Relevant Context** (triggered by: flag:150, national_security:84, red:68):

**File: notes/security-analysis.md** (score: 19220, matches: 2 keywords - flag(conv:150, file:100), national_security(conv:84, file:50))
```
[file content]
```

**File: notes/flag-design.md** (score: 2130, matches: 2 keywords - red(conv:68, file:20), flag(conv:150, file:5))
```
[file content]
```
```

**Automatic Tagging Rules:**

The agent should automatically tag files in the background based on these rules:

1. **Content Analysis:**
   - After file creation or significant updates, analyze file content
   - Extract key concepts, entities, and topics mentioned in the file
   - Identify recurring themes and important terms

2. **Tagging Triggers:**
   - **On file creation**: Analyze initial content and add relevant tags
   - **On file update**: Re-analyze if content changed significantly (>20% change)
   - **On file read with high relevance**: If file scores highly in context injection, consider adding tags for conversation keywords that aren't already tagged

3. **Tag Format:**
   - Use `tag:keyword` pattern (case-insensitive, alphanumeric + underscores)
   - Tags are normalized to lowercase for matching: `tag:red`, `tag:RED`, `tag:Red` all equivalent
   - Place tags at the top of file (first 50 lines) or in a dedicated metadata section
   - Multiple tags allowed: `tag:red tag:flag tag:national_security`
   - Tags match conversation keywords case-insensitively but preserve case distinctions in conversation

4. **Tag Selection Rules:**
   - **Frequency threshold**: Only tag keywords that appear ≥3 times in file (prevents noise)
   - **Significance threshold**: Only tag keywords that represent meaningful concepts (not generic words)
   - **Conversation alignment**: If file is injected due to keyword matches, consider adding tags for those keywords if not already present
   - **Entity recognition**: Tag proper nouns (people, places, organizations) mentioned multiple times
   - **Topic extraction**: Tag main topics/themes discussed in the file

5. **Tag Maintenance:**
   - **Deduplication**: Don't add duplicate tags
   - **Cleanup**: Periodically review and remove tags for keywords that no longer appear in file
   - **Consolidation**: Merge similar tags (e.g., "security" and "national_security" → keep more specific)

6. **Memory Formation Process:**

   **Step 1: Script-Based Tag Extraction (Automatic)**
   - When a file is created or updated, if it hasn't been processed yet, run script-based tag extraction
   - Uses the same keyword extraction logic as Phase 1 (regex, frequency analysis, stop word filtering)
   - Extracts tags based on frequency threshold (≥3 mentions) and significance
   - Adds tags in format: `tag:keyword` (case-insensitive)
   - This is pure script-based processing - no agent needed
   
   **Step 2: Agent-Based Memory Processing (Core Tag Identification)**
   - After script extraction, agent processes the file to identify **core tags**
   - Agent examines file contents and extracted tags
   - Marks which tags are significant/meaningful as **core_tag** (vs normal tags)
   - Core tags represent the core concepts of the memory
   - Agent can add conceptual tags that weren't explicitly written:
     - Example: Conversation about "James Cameron's Avatar" might never mention "movie"
     - Agent adds `core_tag:movie` even if "movie" was only mentioned once or not at all
     - These conceptual tags bridge gaps in explicit content
   
   **Step 3: Core Tag Weighting**
   - Core tags are weighted **far heavier** than normal tags in scoring
   - Core tags **always beat normal tags** regardless of frequency
   - Formula adjustment: `core_tag_score = (core_tag_count * 1000) + normal_tag_score`
   - This ensures memories are ranked by conceptual relevance, not just keyword frequency
   
   **Step 4: Memory Status**
   - File becomes a "memory" only after agent processing (Step 2)
   - Untagged files or files with only script-extracted tags are not yet "memories"
   - Memories can be surfaced in future conversations via tag matching
   - Memory relationships are discovered through shared tags (especially core tags)

7. **Memory Processing Timing:**
   - **Trigger**: Memory processing happens when there is **more than 5 minutes** since the last agent response to a user prompt
   - **Interruption**: User prompts gracefully interrupt memory processing
   - **Resume**: After responding to user, restart the 5-minute timer in background
   - **Priority**: User requests always take precedence over background memory processing
   - **Batch Processing**: Process multiple files in batch during idle time (5+ minutes)

8. **Background Processing:**
   - Tag extraction (script-based) happens immediately on file create/update
   - Memory processing (agent-based) happens during idle periods (5+ minutes since last response)
   - Tagging happens asynchronously (don't block user requests)
   - Use lightweight NLP techniques for script extraction, LLM for conceptual understanding
   - Cache tag analysis results to avoid re-processing unchanged files

**Example Memory Formation:**
```
File: notes/avatar-discussion.md
Content: "James Cameron's Avatar is visually stunning. The Na'vi are fascinating. 
          Cameron's direction is masterful. The world-building is incredible."

Step 1 - Script Extraction (Automatic):
- tag:james (appears 2 times)
- tag:cameron (appears 2 times)
- tag:avatar (appears 1 time, but significant)
- tag:navi (appears 1 time, but significant)

Step 2 - Agent Processing (Core Tag Identification):
Agent analyzes content and identifies core concepts:
- core_tag:movie (conceptual - never explicitly mentioned, but clearly about a movie)
- core_tag:avatar (core concept - the main subject)
- core_tag:james_cameron (core concept - director mentioned multiple times)
- tag:cinema (conceptual - related to filmmaking)
- tag:world_building (explicit concept mentioned)

Step 3 - Memory Status:
File is now a "memory" with core tags weighted heavily.
If conversation mentions "movie" or "avatar", this memory will surface
even if those exact words weren't in the conversation, because core tags
are matched case-insensitively and weighted heavily.
```

## Key Principles

1. **Automatic Relationship Discovery**: No manual organization needed. Files that mention multiple conversation keywords are automatically identified as more relevant.

2. **Weighted Importance**: Keyword mention counts weight importance, but file keyword counts are multiplied with conversation counts for true alignment.

3. **Multi-Keyword Priority**: Files matching multiple keywords is the PRIMARY ranking factor. File keyword frequency imparts a bonus for tie-breaking.

4. **Hierarchical Injection**: Most relevant files are injected first, ensuring important context isn't cut off by token limits.

5. **Automatic Tagging**: Agent handles tagging in background, forming "memories" that surface automatically in future conversations.

## Configuration

### Keyword Extraction Settings

- **Min keyword length**: 2 characters (only single letters filtered)
  - **Range**: 1-10 characters
  - **Rationale**: 2 characters preserves acronyms (AI, API, UI) while filtering noise (single letters like "a", "i")
  - **Trade-off**: Lower values include more words but add noise; higher values miss short acronyms

- **Stop words**: Common words filtered out (the, a, and, etc.)
  - **Range**: Configurable list (default ~80 common English words)
  - **Rationale**: Filters grammatical words that don't carry semantic meaning
  - **Trade-off**: More stop words = cleaner keywords but might filter domain-specific terms

### Tag & Memory Settings

- **Tag pattern**: `tag:keyword` (case-insensitive)
  - **Format**: `tag:` prefix followed by alphanumeric + underscores
  - **Case handling**: Tags normalized to lowercase for matching, but preserve case in conversation keywords
  - **Rationale**: Flexible tagging while preserving case distinctions in conversation

- **Core tag pattern**: `core_tag:keyword` (case-insensitive)
  - **Format**: `core_tag:` prefix for agent-identified core concepts
  - **Weighting**: Core tags weighted 1000x normal tags in scoring
  - **Rationale**: Ensures conceptual relevance beats frequency-based matching

- **Tagging frequency threshold**: 3 mentions (configurable)
  - **Range**: 1-20 mentions
  - **Rationale**: 3 mentions balances noise reduction with concept capture
  - **Trade-off**: Lower values tag more words (noisier), higher values miss infrequent but important concepts
  - **Note**: Core tags can be added by agent even if below threshold (conceptual understanding)

### Context Injection Settings

- **Max context size**: **DYNAMIC by default** (configurable, can be fixed)
  - **Dynamic Mode (default)**: Automatically calculates available space based on:
    - Total context window: 32,768 tokens (from Modelfile)
    - System prompt: ~1000 tokens (estimated)
    - Conversation history: Calculated from current messages
    - Response reserve: ~2000 tokens (for model response)
    - **Available for injection**: Remaining tokens × 4 chars/token × 90% safety margin
    - **Bounds**: Minimum 5,000 chars, Maximum 50,000 chars
  - **Fixed Mode**: Set `dynamic_context=False` to use fixed `max_context_size` value
  - **Maximum theoretical size**: 
    - **Empty conversation**: ~28,000 tokens available ≈ **100,000 characters** (with 90% safety margin)
    - **Long conversation (10k tokens)**: ~20,000 tokens available ≈ **72,000 characters**
    - **Very long conversation (20k tokens)**: ~10,000 tokens available ≈ **36,000 characters**
  - **Practical maximum**: **50,000 characters** (hard limit for safety)
    - This allows referencing entire large documents or multiple full files
    - With 32k token window, you can inject substantial context even in long conversations
  - **Dynamic sizing benefits**:
    - **Short conversations**: More space available for injected context (up to 50k chars)
    - **Long conversations**: Automatically reduces to fit available space (minimum 5k chars)
    - **No manual tuning**: Adapts to conversation length automatically
    - **Prevents overflow**: Never exceeds available context window
  - **Configuration**:
    - `dynamic_context=True` (default): Automatic sizing based on available space
    - `dynamic_context=False`: Use fixed `max_context_size` value
    - `max_context_tokens=32768`: Total context window size (from Modelfile)
    - `max_context_size=2000`: Fallback when dynamic is disabled
  - **For very large documents (manuals, books)**:
    - Dynamic mode will use up to 50k chars when available
    - Consider **chunking strategy**: Split large files into sections, inject most relevant chunks
    - Or use **retrieval-augmented approach**: Store full documents, retrieve and inject relevant sections on-demand
  - **Trade-off**: 
    - **Dynamic (default)**: Adapts to conversation, maximizes available space, prevents overflow
    - **Fixed**: Predictable size, but may waste space or overflow in long conversations
  - **Note**: This is for **injected context only**, not the full conversation. Full conversation history is maintained separately in the 32k context window.

### Caching & Performance Settings

- **Tag index cache**: 60 seconds (configurable)
  - **Range**: 10-300 seconds
  - **Rationale**: 60 seconds balances freshness with performance (avoids re-scanning files on every request)
  - **Trade-off**: Shorter cache = more up-to-date but slower; longer cache = faster but may miss recent changes
  - **Note**: Cache invalidated on file create/update

- **Memory processing idle threshold**: 5 minutes (configurable)
  - **Range**: 1-30 minutes
  - **Rationale**: 5 minutes ensures user gets immediate responses, processes memories during natural breaks
  - **Trade-off**: Shorter = more responsive memory formation but may interrupt user flow; longer = less frequent processing
  - **Note**: User prompts always interrupt memory processing immediately

### Conversation History

- **What happens to old conversations?**
  - **Short-term**: Full conversation history maintained in memory for current session (32k context window)
  - **Long-term**: Conversations logged to daily JSON files in `data/history/` (see ConversationLogger)
  - **Retention**: Logs retained for 30 days by default (configurable via `ATLAS_LOG_RETENTION_DAYS`)
  - **Keyword extraction**: Only extracts from current session messages (not historical logs)
  - **Memory formation**: Old conversations don't trigger memory processing; only current file operations do
  - **Context injection**: Only uses current session keywords to find relevant memories; historical conversations not used for keyword extraction
  - **Rationale**: Keeps keyword extraction focused on current conversation context, while preserving history for reference

## Agent vs Script Requirements

- **Phase 1 (Keyword Extraction)**: **Script-based only** - No agent needed. Pure deterministic text processing.
- **Phase 2 (Tag Index Building)**: **Script-based only** - No agent needed. File scanning and regex matching.
- **Phase 3 (File Scoring)**: **Script-based only** - No agent needed. Mathematical calculations.
- **Phase 4 (Context Injection)**: **Script-based only** - No agent needed. File loading and formatting.
- **Phase 4 (Automatic Tagging)**: **Agent-based** - Requires LLM to understand content, extract concepts, and make tagging decisions.

## Example Scenario

**Conversation keywords:**
- red:1, blue:139, white:89, flag:150, national_security:84, puppies:21

**Files in database:**
- `notes/flag-design.md` (tag:red, tag:flag) - red appears 999 times, flag appears 1 time
- `notes/security-policy.md` (tag:flag, tag:national_security) - flag appears 1 time, national_security appears 999 times
- `notes/blueprints.md` (tag:blue) - blue appears 999 times

**Scoring:**
- `blueprints.md`: (1 * 10) + (139 * 999) = 138,871
- `security-policy.md`: (2 * 10) + (150 * 1) + (84 * 999) = 84,170
- `flag-design.md`: (2 * 10) + (1 * 999) + (150 * 1) = 1,169

**Result:**
1. `blueprints.md` injected first (highest score - blue:139 is highly mentioned, file has blue:999)
2. `security-policy.md` injected second (national_security:84 is highly mentioned, file has national_security:999)
3. `flag-design.md` not injected (red:1 is low, and file has red:999 which doesn't align with conversation focus on blue)

The system correctly identifies that blueprints.md is most relevant because it has high counts of the highly-mentioned keyword (blue:139), making it aligned with conversation context.
