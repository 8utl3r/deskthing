# Enable password auth temporarily - run as Administrator
$sshdConfig = "C:\ProgramData\ssh\sshd_config"
$config = Get-Content $sshdConfig -Raw -ErrorAction Stop

# Uncomment or set PasswordAuthentication yes
$config = $config -replace "#(\s*)PasswordAuthentication\s+no", "`$1PasswordAuthentication yes"
$config = $config -replace "#(\s*)PasswordAuthentication\s+yes", "`$1PasswordAuthentication yes"
$config = $config -replace "(\r?\n)\s*PasswordAuthentication\s+no", "`$1PasswordAuthentication yes"

if ($config -notmatch "PasswordAuthentication\s+yes") {
    $config = $config.TrimEnd() + "`n`nPasswordAuthentication yes`n"
}

Set-Content -Path $sshdConfig -Value $config -NoNewline

Restart-Service sshd -ErrorAction Stop
Write-Host "Done. Try: ssh Pete@192.168.0.47"
