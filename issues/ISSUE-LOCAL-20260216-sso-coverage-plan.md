**ISSUE #1: Hybrid SSO Coverage Plan (OIDC + Trusted Headers + LDAP) for xcvr.link**

**1. Issue Summary**
- **Problem**: Current setup uses `forward_auth` for all services, which gates access but does not provide true in-app SSO. OIDC clients are only placeholders, and there is no per-service configuration or migration plan.
- **Symptoms**: Users still see each app’s login screen; attempts to enable OIDC/trusted headers risk double-login loops; no single doc defines which method each service should use.
- **Impact**: Inconsistent UX, increased support burden, and higher risk of auth misconfiguration across services.

**2. Proposed Fix Summary**
- **Approach**: Establish a single SSO coverage plan that selects **OIDC** where supported, **trusted headers** where supported, and **forward_auth/LDAP** as fallback. Update Authelia OIDC clients, adjust Caddy routing to avoid double-auth, and document per-service config steps and pitfalls.
- **Changes Required**: Update `docs/truenas/authelia-configuration-yml-full-example.yml`, update `scripts/servarr-pi5/caddy/Caddyfile`, and add a new doc (e.g. `docs/networking/SSO_SERVICE_MATRIX.md`) with implementation steps and rollback guidance.

**3. Root Cause Analysis**
- **Why Not Caught Earlier**: Initial effort focused on getting Authelia stable and forward_auth working; OIDC/trusted header requirements per app were not documented.
- **Contributing Factors**: Multiple services with different auth capabilities; no centralized “auth method matrix”; placeholder OIDC client left in config and never expanded.

**4. Code Analysis**

**File**: `scripts/servarr-pi5/caddy/Caddyfile` (Lines 18-106)

```caddy
sso.xcvr.link {
	reverse_proxy 192.168.0.158:30133 {
		header_up X-Forwarded-Host {http.request.host}
		header_up X-Forwarded-Proto https
	}
}

immich.xcvr.link {
	forward_auth 192.168.0.158:30133 {
		uri /api/authz/forward-auth
		copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
	}
	reverse_proxy 192.168.0.158:30041
}

jellyfin.xcvr.link {
	forward_auth 192.168.0.158:30133 {
		uri /api/authz/forward-auth
		copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
	}
	reverse_proxy 192.168.0.136:8096
}
```

- **Current Behavior**: All service blocks use `forward_auth`, which only gates access. No conditional bypass exists for OIDC callbacks or trusted header flows.
- **Dependencies**:
  - **Affects**: All `*.xcvr.link` services; user login flow for Immich/Jellyfin/Headscale/Navidrome.
  - **Affected By**: Authelia availability, correct Remote-* headers, and proxy header handling.
- **Comments Analysis**: Comments describe forward_auth usage but do not explain when it should be removed for OIDC or how to avoid double-login loops.

**File**: `docs/truenas/authelia-configuration-yml-full-example.yml` (Lines 24-70)

```yaml
authentication_backend:
  file:
    path: /config/data/users_database.yml

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

- **Current Behavior**: OIDC is enabled but only with a placeholder client; no service-specific clients exist.
- **Dependencies**:
  - **Affects**: All OIDC integrations (Immich, Headscale, Jellyfin plugin).
  - **Affected By**: Deploy script substituting secrets; app-side OIDC configuration with exact redirect URIs.
- **Comments Analysis**: Notes that OIDC is required but does not define how to add real clients or where secrets should live.

**File**: `scripts/truenas/authelia-deploy-config.sh` (Lines 80-114)

```bash
awk -v hmac="$HMAC" -v keyfile="$OIDC_KEY_FILE" '
  /REPLACE_HMAC_SECRET/ { gsub(/REPLACE_HMAC_SECRET/, hmac); print; next }
  /REPLACE_ISSUER_PRIVATE_KEY/ {
    print "    issuer_private_key: |"
    while ((getline line < keyfile) > 0) print "      " line
    close(keyfile)
    next
  }
  { print }
' "$CONFIG_EXAMPLE" > /tmp/authelia-configuration.yml
```

- **Current Behavior**: Deploy script injects OIDC key material but does not manage per-service clients or secrets.
- **Dependencies**:
  - **Affects**: Authelia OIDC functionality and ability to add clients.
  - **Affected By**: `docs/truenas/authelia-configuration-yml-full-example.yml` content.
- **Comments Analysis**: Lacks guidance on how to safely store client secrets (avoid committing secrets).

**5. Improvement Proposal**

**Code Changes**:
```diff
@@ docs/truenas/authelia-configuration-yml-full-example.yml
 identity_providers:
   oidc:
     hmac_secret: REPLACE_HMAC_SECRET
     issuer_private_key: REPLACE_ISSUER_PRIVATE_KEY
     clients:
-      - client_id: forward_auth_placeholder
-        client_name: Placeholder for OIDC (required by 4.38+)
-        client_secret: ""
-        public: true
-        authorization_policy: one_factor
-        redirect_uris:
-          - https://sso.xcvr.link/
+      - client_id: immich
+        client_name: Immich
+        client_secret: "<IMMICH_CLIENT_SECRET>"
+        public: false
+        authorization_policy: one_factor
+        redirect_uris:
+          - https://immich.xcvr.link/auth/login
+          - https://immich.xcvr.link/user-settings
+      - client_id: headscale
+        client_name: Headscale
+        client_secret: "<HEADSCALE_CLIENT_SECRET>"
+        public: false
+        authorization_policy: one_factor
+        redirect_uris:
+          - https://headscale.xcvr.link/oidc/callback
+      - client_id: jellyfin
+        client_name: Jellyfin SSO Plugin
+        client_secret: "<JELLYFIN_CLIENT_SECRET>"
+        public: false
+        authorization_policy: one_factor
+        redirect_uris:
+          - https://jellyfin.xcvr.link/SSO/OIDC/Callback
+
@@ scripts/servarr-pi5/caddy/Caddyfile
 immich.xcvr.link {
-  forward_auth 192.168.0.158:30133 {
-    uri /api/authz/forward-auth
-    copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
-  }
   reverse_proxy 192.168.0.158:30041
 }

 headscale.xcvr.link {
-  forward_auth 192.168.0.158:30133 {
-    uri /api/authz/forward-auth
-    copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
-  }
   reverse_proxy 192.168.0.158:30210
 }

 jellyfin.xcvr.link {
-  forward_auth 192.168.0.158:30133 {
-    uri /api/authz/forward-auth
-    copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
-  }
   reverse_proxy 192.168.0.136:8096
 }

 music.xcvr.link {
   forward_auth 192.168.0.158:30133 {
     uri /api/authz/forward-auth
     copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
   }
   reverse_proxy 192.168.0.136:4533
 }
```

```diff
@@ docs/networking/SSO_SERVICE_MATRIX.md (new)
| Service | Auth Method | Notes |
|--------|-------------|------|
| Immich | OIDC | Configure OAuth settings and redirect URIs |
| Headscale | OIDC | Configure issuer + callback URL |
| Jellyfin | OIDC (SSO plugin) | Install plugin, configure client |
| Navidrome | Trusted Headers | Set ND_EXTAUTH_TRUSTEDSOURCES to Caddy IP |
| Syncthing | LDAP | Configure LDAP server in Syncthing UI |
| TrueNAS UI | LDAP | Enable Directory Services |
| n8n | OIDC/LDAP (Enterprise) | Otherwise keep forward_auth gate |
```

**Comment/Documentation Changes**:
```markdown
- Add a dedicated SSO implementation guide that includes:
  - Per-service OIDC/Trusted Header/LDAP configuration steps
  - Required redirect URIs and headers
  - Which services should *not* use forward_auth after OIDC is enabled
  - Rollback steps to re-enable forward_auth if OIDC fails
```

**Rationale**: This moves from a single forward_auth gate to a hybrid SSO plan with the best UX per app, while avoiding double-login loops and clarifying where secrets and headers must be configured.

**Additional Considerations**:
- **Tests Needed**: Manual verification checklist: login to `sso.xcvr.link`, OIDC login for each app, confirm forward_auth still gates non-OIDC apps.
- **Edge Cases**:
  - Double-auth loops if forward_auth remains enabled for OIDC apps.
  - Incorrect redirect URIs (must match app’s exact callback path).
  - Header spoofing risk if trusted headers are enabled without strict proxy trust config.
  - Immich mobile app redirect URIs (`app.immich:///oauth-callback`) if mobile is used.
- **Related Issues**: None yet (local-only).
