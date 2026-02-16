# ISSUE LOCAL-20260216: Usable Authelia logs for OAuth invalid_client debugging

**1. Issue Summary**
- **Problem**: When OAuth `invalid_client` errors occur (e.g. signing in from a private window or with a misconfigured client), Authelia logs are not usable for debugging—output repeats or lacks sufficient detail to identify which client failed and why.
- **Symptoms**: User sees "Error: invalid_client / The requested OAuth 2.0 Client does not exist" in the browser; when fetching Authelia logs (e.g. via `./scripts/truenas/authelia-logs.sh` or TrueNAS app logs), logs repeat or do not provide actionable entries (e.g. client_id, redirect_uri, or request context).
- **Impact**: Cannot diagnose OAuth client registration, redirect URI, or token-endpoint auth method issues without usable logs; slows resolution of SSO (e.g. Immich, Headscale, Jellyfin) integration.

**2. Proposed Fix Summary**
- **Approach**: Improve observability of Authelia OIDC client authentication failures so a single failed request produces identifiable, non-repeating log entries (and optionally document temporary debug log level and log capture workflow).
- **Changes Required**: (1) Config and/or tooling: ensure log level and format allow OIDC client errors to be visible and deduplicated or scoped; (2) Docs: document how to capture a one-off failure and interpret logs; (3) Optionally: script or doc to temporarily set `log.level: debug` and restore after capture.

**3. Root Cause Analysis**
- **Why Not Caught Earlier**: Default Authelia `log.level: info` may not emit enough OIDC client lookup/validation detail; log retrieval may return many identical lines (e.g. health checks or repeated errors) with no deduplication or timestamps to correlate one failure.
- **Contributing Factors**: TrueNAS app runs Authelia in Docker; log viewer may show only tail or a single container; Authelia upstream may not log `client_id` or `redirect_uri` on invalid_client in all versions.

**4. Code Analysis**

**File**: `docs/truenas/authelia-configuration-yml-full-example.yml` (Lines 20–22)

```yaml
log:
  level: info
```

- **Current Behavior**: Global log level is `info`; no format or OIDC-specific options. Authelia uses this for all logging; OIDC client auth failures may be logged at a level that is noisy or not detailed enough.
- **Dependencies**:
  - **Affects**: All Authelia log output; OIDC error diagnostics.
  - **Affected By**: Deploy script (`authelia-deploy-config.sh`) copies this file to NAS; Authelia binary log implementation.
- **Comments Analysis**: No comment explaining log level choice or how to enable debug for OAuth troubleshooting.

**File**: `scripts/truenas/authelia-logs.sh` (Lines 48–62)

```bash
# Single SSH: loop on server to get logs for all containers (avoids multiple sudo prompts)
readarray -t NAMES < <(echo "$CONTAINERS" | awk '{print $1}')
# shellcheck disable=SC2029
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S sh -c '
    for name in \"\$@\"; do
      ...
      echo \"--- \$name (\${status:-?}) ---\"
      sudo docker logs \"\$name\" --tail $TAIL 2>&1 || true
    done
  ' _ ${NAMES[*]}" 2>&1 | _filter_ssh
```

- **Current Behavior**: Fetches last N lines (default 80) of each ix-authelia-* container; no deduplication, no timestamps in script output, no filtering by log level or keyword. Repeated identical lines (e.g. same invalid_client log) fill the tail.
- **Dependencies**:
  - **Affects**: Operator view of Authelia logs for debugging.
  - **Affected By**: Docker log driver, Authelia log format, number of containers and log volume.
- **Comments Analysis**: Usage mentions `--tail N`; no guidance for OAuth debugging (e.g. repro once then run with larger tail, or follow with timestamp).

**5. Improvement Proposal**

**Code Changes**

- **Option A – Log level and docs (minimal)**  
  - In `authelia-configuration-yml-full-example.yml`: add comment that `log.level: debug` can be set temporarily for OIDC debugging and restored to `info` after.  
  - In `scripts/truenas/authelia-logs.sh`: add `--timestamps` to `docker logs` so each line has a timestamp (e.g. `docker logs "$name" --tail $TAIL --timestamps 2>&1`).  
  - In `docs/networking/SSO_SERVICE_MATRIX.md` or `docs/truenas/authelia-catalog-config.md`: add a short "Debugging OAuth invalid_client" section: (1) Reproduce the failure once (e.g. private window, wrong client). (2) Immediately run `./scripts/truenas/authelia-logs.sh --tail 200` (or TrueNAS app logs). (3) Optionally set `log.level: debug` in configuration.yml, redeploy, restart Authelia, reproduce again, capture logs, then set back to `info`.

- **Option B – Deduplication in log script**  
  - In `authelia-logs.sh`: pipe each container's log output through a deduplication step (e.g. `awk` or `uniq -c` to collapse consecutive identical lines and show count). Reduces noise when the same error is logged many times.

- **Option C – Upstream**  
  - If Authelia does not log `client_id` or `redirect_uri` on invalid_client, consider opening an upstream issue or PR to add that context at `info` or `debug`; document workaround (debug level + repro once) until then.

**Comment/Documentation Changes**

```markdown
# In authelia-configuration-yml-full-example.yml near log:
# For OAuth debugging: set log.level to debug temporarily; capture logs; set back to info.

# In SSO or authelia docs:
## Debugging OAuth invalid_client
1. Reproduce once (private window or wrong client).
2. Run: ./scripts/truenas/authelia-logs.sh --tail 200
3. Optional: set log.level: debug, redeploy, restart, repro, capture, then restore info.
```

**Rationale**: Ensures operators can get a single, interpretable view of an OAuth failure (timestamps + optional dedup + documented workflow) without changing Authelia upstream; debug level is documented as temporary to avoid log volume in production.

**Additional Considerations**
- **Tests Needed**: Manual: reproduce invalid_client, run log script, confirm at least one distinct error line with timestamp (and optional count if dedup added).
- **Edge Cases**: Multiple containers (authelia, postgres, etc.)—ensure only the Authelia workload logs are the focus in docs; log level change requires restart.
- **Related Issues**: Related to SSO coverage (e.g. LOCAL-20260216-sso-coverage-plan) and Immich OAuth (token_endpoint_auth_method fix).
