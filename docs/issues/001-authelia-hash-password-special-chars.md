# Issue: authelia-hash-password.sh — password as CLI arg breaks for special chars / no output

**Status:** open  
**Labels:** bug  
**Priority:** medium

---

## 1. Issue Summary

- **Problem**: The script passes the password to the Authelia container via `--password "$PASSWORD"`. Shell expansion and quoting can alter or truncate passwords containing `$`, `"`, `\`, or newlines. The user reported pasting a password and pressing Enter with no output; previously stderr was redirected to `/dev/null`, hiding Docker/CLI errors.
- **Symptoms**: No hash printed after entering password; possible wrong hash or silent failure for passwords with special characters.
- **Impact**: Users cannot reliably generate a hash for Authelia (especially with pasted or complex passwords); blocks SSO setup.

## 2. Proposed Fix Summary

- **Approach**: Prefer passing the password in a way that avoids the shell (e.g. stdin or a temp file with restricted permissions), and ensure all Docker/CLI errors are shown when the hash is empty.
- **Changes Required**: Script changes to pass password safely (e.g. `docker run ... -i` and stdin, or temp file); docs/comments on limitations; keep or improve current Docker error surfacing.

## 3. Root Cause Analysis

- **Why Not Caught Earlier**: No tests for special-character passwords; script was tested with simple passwords; stderr was hidden so failures were silent.
- **Contributing Factors**: Authelia CLI accepts `--password` as argument; documenting only the script (not the failure mode) led to confusion when Docker failed or password was altered by the shell.

## 4. Code Analysis

**File:** `scripts/truenas/authelia-hash-password.sh` (Lines 1–39)

- **Current Behavior**: Reads password with `read -rs`, passes it to `docker run ... --password "$PASSWORD"`. Bash expands `$PASSWORD`; characters like `$`, `"`, `\` can change or truncate the value. Docker/container stderr is captured to a temp file and only shown when `HASH` is empty.
- **Dependencies**: Affects users running the script for `users_database.yml`. Affected by Authelia CLI, Docker availability, shell quoting.
- **Comments Analysis**: Header describes purpose; no comment about special-character limitations or that Docker errors are only shown on empty hash.

## 5. Improvement Proposal

- Prefer passing password via stdin (e.g. `echo -n "$PASSWORD" | docker run --rm -i ... authelia crypto hash generate argon2`) if Authelia accepts stdin; otherwise document that users with `$` `"` `\` or newlines should type the password (not paste) or use the manual docker command with proper quoting.
- Ensure cleanup of `DOCKER_ERR` in all paths (e.g. `trap 'rm -f "$DOCKER_ERR"' EXIT` when `DOCKER_ERR` is set).
- Add comment: Passwords with `$`, `"`, `\`, or newlines may be altered when passed as an argument. If the hash is wrong or you see no output, try typing the password (do not paste) or generate the hash manually.

**Rationale**: Makes the failure mode and workaround clear; safer password handling and cleanup improve reliability and security.

**Additional**: Test with password containing `$`, `"`, `\`, space, newline. Edge cases: empty password (handled); Docker not running (errors now shown when HASH empty).
