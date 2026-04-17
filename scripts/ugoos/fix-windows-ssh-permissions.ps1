# Fix Windows OpenSSH public key auth - run as Administrator
# Root cause: authorized_keys must be owned by the user AND have correct ACLs.
# When created by Admin, file may be owned by Administrator. sshd rejects with "Bad owner".

$publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA36Qeb/q/vYpbL7Wh1d2SI+VGHt3ksUbgUcvT1qwnYh pete@local"
$authKeys = "C:\Users\pete\.ssh\authorized_keys"
$sshDir = "C:\Users\pete\.ssh"

# 1. Try official FixHostFilePermissions first (if OpenSSH was installed with scripts)
$fixScripts = @(
    "C:\Program Files\OpenSSH\FixHostFilePermissions.ps1",
    "C:\Program Files\OpenSSH-Win64\FixHostFilePermissions.ps1"
)
foreach ($script in $fixScripts) {
    if (Test-Path $script) {
        Write-Host "Running official $script..."
        & $script -Confirm:$false
        Restart-Service sshd
        Write-Host "Done. Try: ssh pete@192.168.0.47"
        exit 0
    }
}

# 2. Manual fix: ensure key exists, set owner to Pete, set ACLs per Win32-OpenSSH wiki
Write-Host "Using manual fix (FixHostFilePermissions not found)..."

if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($authKeys, $publicKey, $utf8NoBom)

# CRITICAL: File must be owned by Pete per Security-protection wiki
# "authorized_keys should not be owned by, nor provide access to any other user"
icacls $authKeys /setowner "Pete"
icacls $authKeys /inheritance:r
icacls $authKeys /grant:r "Pete:(F)"

# .ssh directory: owner Pete, restrict to Pete only
icacls $sshDir /setowner "Pete"
icacls $sshDir /inheritance:r
icacls $sshDir /grant:r "Pete:(F)"

Restart-Service sshd
Write-Host "Done. Try: ssh pete@192.168.0.47"
