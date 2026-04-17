# n8n Storage Configuration - Simple Guide

## Storage Options in n8n App

You have **2 storage options**:

### 1. Data Storage (n8n App Data)

**What it's for:**
- Stores n8n workflows, credentials, settings
- This is the main n8n data directory

**Configuration:**
- **Host Path:** `/mnt/tank/apps/n8n`
- **Mount Path:** `/home/node/.n8n` ← **This is critical!**

**Current Issue:**
- Probably set to `/data` (wrong)
- Needs to be `/home/node/.n8n` (correct)

---

### 2. Postgres Data Storage

**What it's for:**
- Stores PostgreSQL database files
- Database for workflows, executions, etc.

**Configuration:**
- **Host Path:** `/mnt/tank/apps/n8n-postgres`
- **Mount Path:** `/var/lib/postgresql/data` (or `/var/lib/postgresql`)

**Status:**
- ✅ Already configured correctly (PostgreSQL is running)

---

## What to Check

**In the n8n Edit screen:**

1. **Find "Data Storage" section**
   - Look for "Host Path" field
   - Look for "Mount Path" field (or just "Path")
   - **Check what "Mount Path" is set to**

2. **If Mount Path shows `/data`:**
   - Change it to `/home/node/.n8n`
   - Save and restart the app

3. **If Mount Path shows `/home/node/.n8n`:**
   - It's already correct!
   - The issue might be something else

---

## Quick Fix Steps

1. **Apps** → **Installed Apps** → **n8n** → **Edit**
2. **Find "Data Storage"** section
3. **Look for "Mount Path"** field
4. **Change from `/data` to `/home/node/.n8n`**
5. **Save**
6. **Restart the app** (or it may restart automatically)

---

## Why This Matters

- n8n looks for its data at `/home/node/.n8n` inside the container
- If mounted to `/data`, n8n can't find its workflows/settings
- This causes the container to exit immediately

---

**Can you check what the "Mount Path" shows for "Data Storage"?**
