# ISSUE LOCAL-20260217: Authelia deploy script overwrites valid users_database.yml after setup

**1. Issue Summary**
- **Problem**: The Authelia config deploy script (`authelia-deploy-config.sh`) overwrites the existing `data/users_database.yml` on the NAS with the example file (placeholder `your_username` and invalid Argon2 hash) when the user runs deploy without `USERS_FILE` set—e.g. via `authelia-set-oidc-secrets.sh` or a direct config-only deploy. This happens even when a valid users file was previously deployed (e.g. by `authelia-setup-with-docker.sh`), causing Authelia to fail at startup with "argon2 decode error" for 'your_username'.
- **Symptoms**: After running setup-with-docker (or manually fixing users_database.yml), any subsequent run of deploy-config or set-oidc-secrets replaces the good users file with the example; Authelia logs show "error decoding the authentication database: ... password hash for 'your_username': argon2 decode error: provided encoded hash has an invalid format" and the app crashes in a loop.
- **Impact**: Users who deploy config multiple times (e.g. to refresh OIDC secrets) lose their working Authelia user database and must re-run setup or manually fix the file each time. Severity: high for anyone using the deploy script after initial setup.

**2. Proposed Fix Summary**
- **Approach**: Base the "keep or replace users file" decision on the **exit code of the SSH/test command**, not the exit code of the pipeline that includes `_filter_ssh`. When the pipeline is `ssh ... 2>&1 | _filter_ssh >/dev/null`, the shell uses the last command's exit code; when SSH or sudo prints "[sudo] password for" or "bleep blorp", `grep -v` exits 1 and the overall pipeline fails even though the file exists on the NAS. Use `PIPESTATUS[0]` (or equivalent) to check the SSH exit code so we only set `DEPLOY_USERS=no` when the remote `test -f` actually succeeds.
- **Changes Required**: One conditional change in `scripts/truenas/authelia-deploy-config.sh` (lines 74–81): run the same SSH check but decide using the first element of the pipeline's exit status. Optionally add a brief comment explaining why we use PIPESTATUS.

**3. Root Cause Analysis**
- **Why Not Caught Earlier**: The "keep existing users" logic was tested when the SSH/sudo output did not contain the filtered strings, or when output was fully suppressed. In environments where sudo prints "[sudo] password for" to stderr (or credential helper prints "bleep blorp"), that output is merged with stdout (2>&1), piped to `_filter_ssh`. The last command in the pipeline is `grep -v "\[sudo\] password for"` (or the redirect). For `grep -v`, exit code 1 means "at least one line matched" (i.e. a line was filtered out). So the pipeline returns 1 even when the remote `test -f` succeeded (exit 0). The script then keeps `DEPLOY_USERS=yes` and overwrites the users file.
- **Contributing Factors**: Use of a pipeline to both suppress noise and drive a conditional without checking the first command's exit code; `_filter_ssh` being required for UX elsewhere in the script, so removing the filter from this check would reintroduce noisy output.

**4. Code Analysis**

**File**: `scripts/truenas/authelia-deploy-config.sh` (Lines 73–82)

```bash
DEPLOY_USERS="yes"
if [[ -z "${USERS_FILE:-}" ]]; then
  echo "Checking for existing users_database.yml on NAS..."
  if ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
    "echo -n '$PASS' | sudo -S test -f '$CONF_DIR/data/users_database.yml'" 2>&1 | _filter_ssh >/dev/null; then
    DEPLOY_USERS="no"
    echo "Keeping existing users_database.yml on NAS (set USERS_FILE to replace)."
  fi
fi
echo "Users file decision done."
```

- **Current Behavior**: The inner `if` uses the **exit code of the pipeline** (`ssh ... | _filter_ssh >/dev/null`). The pipeline's exit code is that of the last command. When ssh/sudo produces output that _filter_ssh filters (e.g. "[sudo] password for"), the last grep in _filter_ssh exits 1, so the pipeline fails and the script does not set `DEPLOY_USERS=no`, and later deploys the example users file over the existing one.
- **Dependencies**:
  - **Affects**: Subsequent steps that copy (or skip copying) `users_database.yml` to the NAS (SCP, remote `cp`), and thus the contents of `$CONF_DIR/data/users_database.yml` on the NAS.
  - **Affected By**: `_filter_ssh` (line 50), `USERS_FILE` env var (set by `authelia-setup-with-docker.sh` when replacing users; unset when running `authelia-deploy-config.sh` directly or via `authelia-set-oidc-secrets.sh`).
- **Comments Analysis**: No comment explains that the conditional must reflect the **remote test** result; the use of a pipeline for output filtering is not documented, so the exit-code pitfall is easy to miss.

**File**: `scripts/truenas/authelia-deploy-config.sh` (Lines 128–135, 137–144, 150–157)

- **Current Behavior**: When `DEPLOY_USERS=yes`, the script prepares `/tmp/authelia-users_database.yml` from `USERS_EXAMPLE` (when `USERS_FILE` is unset), SCPs it to the NAS, and in the remote block runs `cp /tmp/authelia-users_database.yml "$CONF_DIR/data/users_database.yml"`. So any time the "existing users" check is wrong (pipeline fails), the example file overwrites the valid one.
- **Dependencies**: Same as above; these blocks are the ones that perform the overwrite when DEPLOY_USERS is yes.

**5. Improvement Proposal**

**Code Changes**:

```bash
# scripts/truenas/authelia-deploy-config.sh: use SSH exit code, not pipeline exit code,
# so filtered output (e.g. "[sudo] password for") does not cause us to overwrite existing users_database.yml.

DEPLOY_USERS="yes"
if [[ -z "${USERS_FILE:-}" ]]; then
  echo "Checking for existing users_database.yml on NAS..."
  ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
    "echo -n '$PASS' | sudo -S test -f '$CONF_DIR/data/users_database.yml'" 2>&1 | _filter_ssh >/dev/null
  if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    DEPLOY_USERS="no"
    echo "Keeping existing users_database.yml on NAS (set USERS_FILE to replace)."
  fi
fi
echo "Users file decision done."
```

**Comment/Documentation Changes**:

```bash
# Immediately after the "Checking for existing users_database.yml on NAS..." block, add a short comment:
# Use PIPESTATUS[0]: the pipeline's exit code is from _filter_ssh (grep -v); when sudo/creds
# print filtered lines, grep -v exits 1 and would wrongly keep DEPLOY_USERS=yes and overwrite the file.
```

**Rationale**: Relying on `PIPESTATUS[0]` makes the "keep existing users" decision reflect only whether the remote `test -f` succeeded, so valid users_database.yml is preserved when the user runs deploy-config or set-oidc-secrets after initial setup. The comment helps future readers avoid reintroducing the bug when touching the pipeline.

**Additional Considerations**:
- **Tests Needed**: Manual test: run authelia-setup-with-docker.sh to deploy a valid users file, then run authelia-set-oidc-secrets.sh (or authelia-deploy-config.sh) and confirm data/users_database.yml on the NAS still contains the setup user and valid hash; confirm Authelia starts. Optional: add a small script or CI step that mocks the SSH output and verifies DEPLOY_USERS is set from the first command's exit code.
- **Edge Cases**: If SSH fails (e.g. timeout, auth), PIPESTATUS[0] will be non-zero and we will leave DEPLOY_USERS=yes and deploy the example file; that is acceptable (no existing file to preserve if we can't reach the NAS). If the remote test fails (file missing), PIPESTATUS[0] is non-zero and we deploy the example, which is correct.
- **Related Issues**: None.
