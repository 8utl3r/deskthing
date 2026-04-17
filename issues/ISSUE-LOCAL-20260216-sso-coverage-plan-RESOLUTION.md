# ISSUE LOCAL-20260216: Hybrid SSO Coverage Plan (OIDC + Trusted Headers + LDAP) for xcvr.link

## 0. Intake

- **Issue ID**: LOCAL-20260216-sso-coverage-plan
- **Title**: Hybrid SSO Coverage Plan (OIDC + Trusted Headers + LDAP) for xcvr.link
- **File**: `issues/ISSUE-LOCAL-20260216-sso-coverage-plan.md`
- **Branch**: `local/issue-LOCAL-20260216-sso-coverage-plan`

**Expected vs actual behavior**
- **Expected**: Per-service SSO: OIDC where supported (Immich, Headscale, Jellyfin), trusted headers for Navidrome, forward_auth/LDAP as fallback. Single doc defines method per service; no double-login loops.
- **Actual**: All services use forward_auth only; OIDC clients are placeholders; no per-service matrix or migration plan.

**Acceptance criteria**
1. Authelia config has OIDC clients for Immich, Headscale, Jellyfin (with documented secret handling).
2. Caddy removes forward_auth for those three once OIDC is configured (phased rollout).
3. New doc `docs/networking/SSO_SERVICE_MATRIX.md` defines auth method per service, implementation steps, and rollback.
4. Navidrome trusted headers documented (ND_EXTAUTH_TRUSTEDSOURCES).

**Constraints**
- No secrets committed; reuse existing deploy/credential patterns.
- Phased rollout to avoid breaking access.
- Local-only: do not push to remote.

---

## 1. Existing context to reuse

- **Patterns**: Authelia deploy uses `authelia-deploy-config.sh`; substitutes `REPLACE_HMAC_SECRET` and `REPLACE_ISSUER_PRIVATE_KEY`; users in `data/users_database.yml`; config example at `docs/truenas/authelia-configuration-yml-full-example.yml`.
- **Config/env**: No `.env` for Authelia; `scripts/credentials/creds.sh` for truenas-sudo; deploy script reads `USERS_FILE`, `TRUENAS_HOST`, `TRUENAS_USER`.
- **Docs**: `docs/networking/SSO_CADDY_AUTHELIA_CHECKLIST.md`, `docs/services/sso-feature-matrix.md`, `docs/services/sso-glossary.md`, `docs/truenas/sso-setup-walkthrough.md`.
- **Caddy**: `scripts/servarr-pi5/caddy/Caddyfile`; deploy via `scripts/servarr-pi5-caddy-update.sh`.
- **Tooling**: bash scripts; no formal tests; manual verification.

---

## 2. Code path (where the issue lives)

| Entry point | Files | Adjacent |
|-------------|-------|----------|
| OIDC client definitions | `docs/truenas/authelia-configuration-yml-full-example.yml` (lines 58–70) | `authelia-deploy-config.sh` (awk substitution) |
| forward_auth blocks | `scripts/servarr-pi5/caddy/Caddyfile` (lines 27–106) | `servarr-pi5-caddy-update.sh` |
| SSO docs | `docs/networking/SSO_CADDY_AUTHELIA_CHECKLIST.md`, `docs/services/sso-feature-matrix.md` | New: `docs/networking/SSO_SERVICE_MATRIX.md` |

---

## 3. Code analysis (line-by-line)

### File: `docs/truenas/authelia-configuration-yml-full-example.yml` (Lines 56–70)

```yaml
# OIDC: required in 4.38+. REPLACE_HMAC_SECRET and REPLACE_ISSUER_PRIVATE_KEY are replaced by the deploy script.
identity_providers:
  oidc:
    hmac_secret: REPLACE_HMAC_SECRET
    issuer_private_key: REPLACE_ISSUER_PRIVATE_KEY
    clients:
      - client_id: forward_auth_placeholder
        client_name: Placeholder for OIDC (required by 4.38+)
        client_secret: ""
        public: true
        authorization_policy: one_factor
        redirect_uris:
          - https://sso.xcvr.link/
```

- **Current behavior**: Single placeholder client; deploy script injects HMAC and issuer key only.
- **Dependencies**: Affects OIDC integrations; deploy script does not manage per-service clients or secrets.
- **Redirect URI corrections** (from Authelia/Jellyfin/Immich/Headscale docs):
  - **Jellyfin**: `https://jellyfin.xcvr.link/sso/OID/redirect/authelia` (not `/SSO/OIDC/Callback`; provider name in path).
  - **Immich**: `https://immich.xcvr.link/auth/login`, `https://immich.xcvr.link/user-settings`; optional mobile: `app.immich:///oauth-callback`.
  - **Headscale**: `https://headscale.xcvr.link/oidc/callback`.

### File: `scripts/servarr-pi5/caddy/Caddyfile` (Lines 36–95)

```caddy
headscale.xcvr.link {
	forward_auth 192.168.0.158:30133 { ... }
	reverse_proxy 192.168.0.158:30210
}
immich.xcvr.link {
	forward_auth 192.168.0.158:30133 { ... }
	reverse_proxy 192.168.0.158:30041
}
jellyfin.xcvr.link {
	forward_auth 192.168.0.158:30133 { ... }
	reverse_proxy 192.168.0.136:8096
}
```

- **Current behavior**: All three use forward_auth; removing it before OIDC is configured would leave them unprotected.
- **Dependencies**: Caddy restart via `servarr-pi5-caddy-update.sh`; Authelia must have valid OIDC clients.

### File: `scripts/truenas/authelia-deploy-config.sh` (Lines 78–90)

- **Current behavior**: awk substitutes `REPLACE_HMAC_SECRET` and `REPLACE_ISSUER_PRIVATE_KEY`; no OIDC client secret handling.
- **Reuse**: Same substitution pattern could extend to optional placeholders; manual edit remains the zero-dependency path.

---

## 4. Options

### Option A (default): Config + docs only; manual secret handling; phased Caddy changes

- Add OIDC clients (Immich, Headscale, Jellyfin) to config example with placeholders `REPLACE_IMMICH_CLIENT_SECRET`, etc.
- Document: generate secrets (`openssl rand -base64 32`), manually edit deployed config on NAS or pre-edit before deploy.
- Add `docs/networking/SSO_SERVICE_MATRIX.md` with per-service auth method, implementation steps, pitfalls, rollback.
- Caddy: remove forward_auth for each app only after that app’s OIDC is verified working (phased; one commit per app or one commit with clear ordering).
- **Pros**: No new env vars; reuses manual-edit pattern; smallest change.
- **Cons**: User must edit config on NAS or run a one-off sed; no automation.

### Option B: Deploy script optional env-var substitution

- Same as A, but deploy script substitutes `REPLACE_IMMICH_CLIENT_SECRET` etc. from `AUTHELIA_OIDC_IMMICH_SECRET` when set.
- If unset, leave placeholder and warn.
- **Pros**: Enables automation; backward compatible.
- **Cons**: New env vars; requires `.env.example` or doc update.

### Option C: Credentials store integration

- Store OIDC secrets in `scripts/credentials/` (e.g. `creds_get authelia-oidc-immich`).
- **Pros**: Centralized secrets.
- **Cons**: New pattern; credential store may not support multiple values; more complexity.

**Recommendation**: Option A. Manual secret handling is sufficient for homelab; Option B can be added later if automation is needed.

---

## 5. Chosen approach and smallest safe diff

**Approach**: Option A.

**Plan**:
1. **Authelia config** (`docs/truenas/authelia-configuration-yml-full-example.yml`): Replace placeholder with Immich, Headscale, Jellyfin OIDC clients. Use placeholders `REPLACE_IMMICH_CLIENT_SECRET`, `REPLACE_HEADSCALE_CLIENT_SECRET`, `REPLACE_JELLYFIN_CLIENT_SECRET`. Document that user must replace before/after deploy.
2. **SSO matrix** (`docs/networking/SSO_SERVICE_MATRIX.md`): New doc with table, per-service config steps, redirect URIs, pitfalls (double-auth, wrong URIs, header spoofing, Immich mobile), rollback steps.
3. **Caddy** (`scripts/servarr-pi5/caddy/Caddyfile`): Remove forward_auth for immich, headscale, jellyfin **only after** OIDC is verified. Implementation order: add config + docs first; Caddy changes in a follow-up commit once OIDC is tested.
4. **Checklist** (`docs/networking/SSO_CADDY_AUTHELIA_CHECKLIST.md`): Add pointer to `SSO_SERVICE_MATRIX.md` for OIDC/trusted-header setup.

**Invariants**:
- forward_auth remains for nas, rules, n8n, syncthing, music, listen/watch/read until explicitly changed.
- No secrets in repo; only placeholder names and env var names in docs.

**Edge cases**:
- Double-auth: Do not remove forward_auth until OIDC login works.
- Jellyfin redirect: Use `/sso/OID/redirect/authelia` (provider name = authelia).
- Immich mobile: Add `app.immich:///oauth-callback` if mobile is used.
- Navidrome: `ND_EXTAUTH_TRUSTEDSOURCES` = Caddy IP (192.168.0.136 or Pi host).

---

## 6. Git safety / rollback plan

- **Branch**: `local/issue-LOCAL-20260216-sso-coverage-plan` (already exists)
- **Checkpoint**: Tag before changes: `git tag -a checkpoint/LOCAL-20260216-start -m "Before SSO coverage plan"`
- **Commit strategy**: Small commits; `Refs LOCAL-20260216` in messages.
- **Publication**: Local-only; do not push.

```bash
# 0) Confirm clean baseline
git status
git branch

# 1) Ensure on issue branch
git switch local/issue-LOCAL-20260216-sso-coverage-plan

# 2) Checkpoint
git tag -a checkpoint/LOCAL-20260216-start -m "Checkpoint before SSO coverage plan"

# 3) Small commits (example order)
# Commit 1: Authelia config OIDC clients
git add docs/truenas/authelia-configuration-yml-full-example.yml
git commit -m "feat(authelia): add OIDC clients for Immich, Headscale, Jellyfin (Refs LOCAL-20260216)"

# Commit 2: SSO matrix doc
git add docs/networking/SSO_SERVICE_MATRIX.md
git commit -m "docs(networking): add SSO service matrix and implementation guide (Refs LOCAL-20260216)"

# Commit 3: Checklist pointer
git add docs/networking/SSO_CADDY_AUTHELIA_CHECKLIST.md
git commit -m "docs(networking): link SSO checklist to service matrix (Refs LOCAL-20260216)"

# Commit 4: Caddy - remove forward_auth for OIDC apps (only after OIDC verified)
# git add scripts/servarr-pi5/caddy/Caddyfile
# git commit -m "feat(caddy): remove forward_auth for Immich, Headscale, Jellyfin (Refs LOCAL-20260216)"

# 4) Rollback
git revert <commit-sha>   # preferred
# Or: git reset --hard checkpoint/LOCAL-20260216-start  # local-only, destructive
```

---

## 7. Verification + rollback

**Verification**:
1. Deploy Authelia config: `./scripts/truenas/authelia-deploy-config.sh` (after replacing placeholders).
2. Restart Authelia; confirm no config errors.
3. Configure Immich/Headscale/Jellyfin OIDC per `SSO_SERVICE_MATRIX.md`.
4. Test OIDC login for each app before removing forward_auth.
5. After Caddy change: `./scripts/servarr-pi5-caddy-update.sh`; verify login flow.

**Rollback trigger**: OIDC login fails; redirect loops; apps inaccessible.

**Rollback steps**: Revert Caddy commit to restore forward_auth; revert Authelia config if needed; restart services.

---

## 8. Completion criteria

- [ ] All changes committed; `git status` clean.
- [ ] `SSO_SERVICE_MATRIX.md` exists with per-service auth method and implementation steps.
- [ ] Authelia config has OIDC clients with correct redirect URIs.
- [ ] Caddy forward_auth removed for OIDC apps only after OIDC verified (or left in place if phased later).
- [ ] No secrets committed; placeholders documented.
- [ ] Local-only: no push.

---

## Open questions

None. Proceed with Option A when implementing.
