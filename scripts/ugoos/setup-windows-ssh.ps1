# Setup SSH authorized_keys for pete on Windows
# Run in PowerShell as Administrator

$publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA36Qeb/q/vYpbL7Wh1d2SI+VGHt3ksUbgUcvT1qwnYh pete@local"

# Also set administrators_authorized_keys (in case config edit fails)
$adminKeys = "C:\ProgramData\ssh\administrators_authorized_keys"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($adminKeys, $publicKey, $utf8NoBom)
icacls $adminKeys /reset
icacls $adminKeys /inheritance:r
icacls $adminKeys /grant:r "NT AUTHORITY\SYSTEM:(F)"
icacls $adminKeys /grant:r "BUILTIN\Administrators:(F)"
Write-Host "Set $adminKeys"

# Disable admin-only keys so we use standard ~/.ssh/authorized_keys
$sshdConfig = "C:\ProgramData\ssh\sshd_config"
$config = Get-Content $sshdConfig -Raw
if ($config -notmatch "# Match Group administrators") {
    $config = $config -replace "Match Group administrators", "# Match Group administrators"
    $config = $config -replace "(\s+)AuthorizedKeysFile __PROGRAMDATA__[\\/]ssh[\\/]administrators_authorized_keys", "`$1# AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys"
    Set-Content -Path $sshdConfig -Value $config -NoNewline
    Write-Host "Disabled administrators_authorized_keys in sshd_config"
}

# Use standard per-user authorized_keys (pete)
$sshDir = "C:\Users\pete\.ssh"
$authKeys = "$sshDir\authorized_keys"
if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
# UTF-8 no BOM - avoid encoding issues
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($authKeys, $publicKey, $utf8NoBom)
# Use "Pete" to match Windows (icacls showed DESKTOP-*\Pete)
icacls $sshDir /inheritance:r /grant "Pete:F"
icacls $authKeys /inheritance:r /grant "Pete:F"
Write-Host "Also set $authKeys"

Restart-Service sshd
Write-Host "Restarted sshd. Try: ssh pete@192.168.0.47 from your Mac"
