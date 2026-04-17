# Windows OpenSSH Public Key Auth Fix

**Problem:** `ssh pete@192.168.0.47` returns "Permission denied (publickey,password,keyboard-interactive)" even though the key is in `authorized_keys` and sshd is running.

**Root cause:** The `authorized_keys` file was created by an Administrator process. On Windows, the file is then **owned by Administrator**, not by the user `Pete`. Win32-OpenSSH rejects keys with "Bad owner" when the file is not owned by the authenticating user.

(Our script also set ACLs to only `Pete:(F)`, removing SYSTEM. The primary fix is ownership.)

---

## Quick Fix (via KVM or RDP)

1. **Download and run the fix script** (from Windows, as Administrator):

   ```powershell
   # One-liner: download and run (adjust URL if your http.server is different)
   Invoke-WebRequest -Uri "http://192.168.0.180:8765/scripts/ugoos/fix-windows-ssh-permissions.ps1" -OutFile "$env:USERPROFILE\Desktop\fix-ssh.ps1"
   powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\fix-ssh.ps1"
   ```

2. **Or run manually** in elevated PowerShell:

   ```powershell
   icacls "C:\Users\pete\.ssh\authorized_keys" /setowner "Pete"
   icacls "C:\Users\pete\.ssh\authorized_keys" /inheritance:r /grant:r "Pete:(F)"
   icacls "C:\Users\pete\.ssh" /setowner "Pete"
   icacls "C:\Users\pete\.ssh" /inheritance:r /grant:r "Pete:(F)"
   Restart-Service sshd
   ```

3. **Test from Mac:**
   ```bash
   ssh pete@192.168.0.47
   ```

---

## Verification

Before fix, check owner (run as Admin on Windows):

```powershell
(Get-Acl "C:\Users\pete\.ssh\authorized_keys").Owner
# Likely shows: DESKTOP-XXXX\Administrator
```

After fix:

```powershell
(Get-Acl "C:\Users\pete\.ssh\authorized_keys").Owner
# Should show: DESKTOP-XXXX\Pete
```

---

## References

- [Win32-OpenSSH Security protection wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH): "authorized_keys should not be owned by, nor provide access to any other user"
- [GitHub #1542](https://github.com/PowerShell/Win32-OpenSSH/issues/1542): "Bad owner" diagnostic
- Official fix: `FixHostFilePermissions.ps1` in `C:\Program Files\OpenSSH\` (if present)
