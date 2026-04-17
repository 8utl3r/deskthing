# Issue: Deploy and docs should point to authelia-hash-password.sh for hash generation

**Status:** open  
**Labels:** documentation  
**Priority:** medium  
**Pulled from:** GitHub #4 (8utl3r/petes-m3-setup)

---

## 1. Issue Summary

- **Problem**: After deploy, the script and docs tell users to generate an Argon2 hash with a raw `docker run ... --password 'YOUR_PASSWORD'` command. The repo provides `scripts/truenas/authelia-hash-password.sh`, which hides input and avoids echoing the password in the terminal; it is not mentioned in the deploy script's "Next steps" or in the main Authelia docs.
- **Symptoms**: Users follow "Next steps" and use the manual docker command; password may be visible in process list or history; those who prefer a script don't discover the existing tool.
- **Impact**: Inconsistent UX; missed use of the safer script; password handling and discoverability are worse than they could be.

## 2. Proposed Fix Summary

- **Approach**: In the deploy script's "Done. Next steps" section and in relevant docs (e.g. `authelia-catalog-config.md`, SSO checklist), mention `./scripts/truenas/authelia-hash-password.sh` first, with the manual docker command as a fallback.
- **Changes Required**: Edit `scripts/truenas/authelia-deploy-config.sh` (echo block); optionally `docs/truenas/authelia-catalog-config.md` and `docs/networking/SSO_CADDY_AUTHELIA_CHECKLIST.md` where user/password hash generation is described.

## 3. Root Cause Analysis

- **Why Not Caught Earlier**: Deploy script was written before the hash-password script existed; docs were not updated when the script was added.
- **Contributing Factors**: Multiple places describe hash generation (deploy, catalog config, users_database example); no single "canonical" reference that points to the script.

## 4. Code Analysis

**File:** `scripts/truenas/authelia-deploy-config.sh` (Lines 69–74)

- **Current Behavior**: Prints next steps that reference only the manual docker command for hash generation.
- **Dependencies**: Affects users who have just run the deploy script and need to set a user password. Affected by existence of `scripts/truenas/authelia-hash-password.sh`; docs that describe hash generation.
- **Comments Analysis**: No reference to the repo script.

**File:** `docs/truenas/authelia-users-database-yml-example.yml` (Lines 4–6)

- **Current Behavior**: Same: only the docker command is documented.

## 5. Improvement Proposal

**Code Changes** (in `authelia-deploy-config.sh`):
- Change the "Generate hash" line to: `./scripts/truenas/authelia-hash-password.sh  (or: docker run ... )`

**Comment/Documentation Changes** (in `authelia-users-database-yml-example.yml` or catalog doc):
- Add: Or run `./scripts/truenas/authelia-hash-password.sh` (from repo root) to prompt for password and print the hash.

**Rationale:** Promotes the safer script and keeps the manual command as fallback; aligns script and docs.

**Additional Considerations:**
- **Tests Needed:** None beyond verifying the printed instructions.
- **Edge Cases:** User may run deploy from a different cwd; "from repo root" or full path in docs avoids confusion.
- **Related Issues:** Related to hash script improvements (special-character handling, #001).
