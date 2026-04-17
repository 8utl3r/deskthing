# SSH diagnostic - run on Windows, outputs to desktop
$out = "C:\Users\pete\Desktop\ssh-diag.txt"
@"
=== SSH Diagnostic ===
"@ | Out-File $out

"--- User folders ---" | Out-File $out -Append
Get-ChildItem C:\Users -Directory | Select-Object Name | Out-File $out -Append

"--- sshd_config (Match block) ---" | Out-File $out -Append
Select-String -Path "C:\ProgramData\ssh\sshd_config" -Pattern "Match|AuthorizedKeysFile" -Context 0,1 | Out-File $out -Append

"--- administrators_authorized_keys ---" | Out-File $out -Append
Get-Content "C:\ProgramData\ssh\administrators_authorized_keys" -ErrorAction SilentlyContinue | Out-File $out -Append

"--- C:\Users\pete\.ssh\authorized_keys ---" | Out-File $out -Append
Get-Content "C:\Users\pete\.ssh\authorized_keys" -ErrorAction SilentlyContinue | Out-File $out -Append

"--- C:\Users\Pete\.ssh\authorized_keys ---" | Out-File $out -Append
Get-Content "C:\Users\Pete\.ssh\authorized_keys" -ErrorAction SilentlyContinue | Out-File $out -Append

"--- icacls on authorized_keys ---" | Out-File $out -Append
icacls "C:\Users\pete\.ssh\authorized_keys" 2>&1 | Out-File $out -Append

"--- authorized_keys first bytes (hex, check BOM) ---" | Out-File $out -Append
$bytes = [System.IO.File]::ReadAllBytes("C:\Users\pete\.ssh\authorized_keys")
"First 20 bytes (hex): $([BitConverter]::ToString($bytes[0..19]))" | Out-File $out -Append
"UTF-8 BOM = EF-BB-BF; UTF-16 LE BOM = FF-FE; OK = 73-73-68 (ssh)" | Out-File $out -Append

"--- sshd service ---" | Out-File $out -Append
Get-Service sshd | Out-File $out -Append

Write-Host "Output saved to $out"
