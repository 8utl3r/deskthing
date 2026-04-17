# n8n Installation Configuration Values

## Recommended Settings for TrueNAS Scale

### Web Host
**Value:** `192.168.0.158` or `0.0.0.0`
- **`192.168.0.158`** - Your TrueNAS IP (if you want to bind to specific IP)
- **`0.0.0.0`** - Listen on all interfaces (recommended for flexibility)
- **Recommendation:** Use `0.0.0.0` - allows access from any network interface

### Database Password
**Value:** Generate a strong random password
- This is for PostgreSQL database (internal to n8n)
- **Recommendation:** Use a strong password like: `n8n-db-$(openssl rand -hex 16)`
- Or use: `n8n-postgres-2026` (change this!)
- **Important:** Save this password somewhere - you'll need it if you migrate/backup

### Redis Password
**Value:** Generate a strong random password
- This is for Redis cache (internal to n8n)
- **Recommendation:** Use a strong password like: `n8n-redis-$(openssl rand -hex 16)`
- Or use: `n8n-redis-2026` (change this!)
- **Important:** Save this password somewhere

### Encryption Key
**Value:** Generate a strong random key (32+ characters)
- Used to encrypt sensitive workflow data
- **Recommendation:** Generate secure key: `openssl rand -base64 32`
- Or use: `n8n-encryption-key-$(openssl rand -hex 32)`
- **Critical:** Save this key! If lost, encrypted workflow data cannot be recovered
- **Minimum:** 32 characters

### Runners Mode
**Value:** `internal` (current setting - keep this!)
- **`internal`** - Runs workflows on the same server (recommended for single server)
- **`external`** - For distributed execution (not needed for your setup)
- **Recommendation:** Keep `internal` - perfect for your use case

### Port
**Value:** `30109` (default - this is fine!)
- This is the Kubernetes NodePort (external access)
- Internal port is still 5678
- **Access n8n at:** `http://192.168.0.158:30109`
- **Recommendation:** Keep default `30109` unless it conflicts with something

---

## Storage Configuration

### Critical: Persistent Storage Mount

**You MUST configure storage for n8n data persistence!**

**Host Path:** `/mnt/tank/apps/n8n`  
**Container Path:** `/home/node/.n8n`

**What this stores:**
- Workflows
- Credentials (encrypted)
- Execution history
- Settings

**Without this mount:**
- All workflows will be lost on container restart!
- Data will be ephemeral

---

## Quick Configuration Summary

```
Web Host: 0.0.0.0
Database Password: [generate strong password]
Redis Password: [generate strong password]
Encryption Key: [generate 32+ char key]
Runners Mode: internal (keep as-is)
Port: 30109 (keep default)
Storage: /mnt/tank/apps/n8n → /home/node/.n8n
```

---

## Generate Secure Passwords

**If you want me to generate secure passwords:**

```bash
# Database Password
openssl rand -base64 24

# Redis Password  
openssl rand -base64 24

# Encryption Key (32+ chars)
openssl rand -base64 32
```

**Or use these (change them later!):**
- Database Password: `n8n-db-password-2026`
- Redis Password: `n8n-redis-password-2026`
- Encryption Key: `n8n-encryption-key-2026-change-this-later`

---

## Storage Configuration Steps

1. **Find "Storage" or "Volumes" section** in the wizard
2. **Add volume mount:**
   - **Host Path:** `/mnt/tank/apps/n8n`
   - **Container Path:** `/home/node/.n8n`
   - **Type:** Host Path (or Bind Mount)
3. **Ensure it's set to Read/Write** (not Read-Only)

**If storage section isn't visible:**
- Look for "Advanced" or "Storage" tab
- Or "Volumes" section
- May be in a collapsible section

---

**Let me know what you see in the Storage section and I'll help configure it!**
