# Issue: configuration example leaves REPLACE_ISSUER_PRIVATE_KEY causing OIDC/startup errors

**Status:** open  
**Labels:** documentation  
**Priority:** medium  
**Pulled from:** GitHub #3 (8utl3r/petes-m3-setup)

---

## 1. Issue Summary

- **Problem**: The example `configuration.yml` sets `identity_providers.oidc.issuer_private_key: REPLACE_ISSUER_PRIVATE_KEY`. Some Authelia builds require a valid RSA private key here; the literal placeholder is invalid and can cause startup failure or persistent errors in logs.
- **Symptoms**: Authelia container fails to start or logs errors about `issuer_private_key`; user must find and replace the placeholder with a generated key.
- **Impact**: Users who deploy the example as-is may see Authelia fail or OIDC broken until they locate the placeholder and follow external OIDC docs.

## 2. Proposed Fix Summary

- **Approach**: Document the exact steps (and command) to generate and substitute a valid RSA key for `REPLACE_ISSUER_PRIVATE_KEY`, and/or provide a minimal valid PEM placeholder (e.g. a throwaway key) so the app starts when OIDC is not yet required.
- **Changes Required**: Doc/comment changes in the example and in `authelia-catalog-config.md` (or deploy next steps); optionally add a one-line command to generate the key; if supported by Authelia, document how to omit or disable OIDC for forward-auth-only setups.

## 3. Root Cause Analysis

- **Why Not Caught Earlier**: Example was built for forward_auth and minimal config; OIDC was optional in narrative but the key may be required by the schema or default config; no validation step that Authelia starts with the example as-deployed.
- **Contributing Factors**: Authelia's OIDC key requirement varies by version; placeholder was left for "see Authelia docs" without a copy-paste command.

## 4. Code Analysis

**File:** `docs/truenas/authelia-configuration-yml-full-example.yml` (Lines 56–62)

- **Current Behavior**: File is used as the source for `configuration.yml` by the deploy script; `REPLACE_HMAC_SECRET` is replaced by the script; `REPLACE_ISSUER_PRIVATE_KEY` is left as-is. Authelia may reject the invalid key value.
- **Dependencies**: Affects deploy script output (deployed config on NAS); Authelia app startup and OIDC. Affected by `scripts/truenas/authelia-deploy-config.sh` (copies this file); Authelia OIDC schema/docs.
- **Comments Analysis**: Comment says "see Authelia docs" and "you may omit" but does not give a generation command for the key; users may not know how to produce a valid PEM.

## 5. Improvement Proposal

**Comment/Documentation Changes:**
- In the example file header or above `identity_providers`, add: issuer_private_key: Generate with: `docker run --rm authelia/authelia:latest authelia crypto hash generate rsa --key-size 4096`. Paste the private key (PEM) below, or remove the oidc block if you only use forward_auth login.
- In `authelia-catalog-config.md` (or deploy next steps), add a "Replace REPLACE_ISSUER_PRIVATE_KEY" step with the same command and "or remove identity_providers.oidc if not using OIDC" if applicable.

**Rationale:** Users get a single command and clear options (generate key vs remove block), reducing failed starts and support burden.

**Additional Considerations:**
- **Tests Needed:** Deploy example and start Authelia; confirm it starts with a generated key; confirm behavior when OIDC block is removed (if supported).
- **Edge Cases:** Authelia version differences (v4 vs older); env-only OIDC config.
- **Related Issues:** None.
