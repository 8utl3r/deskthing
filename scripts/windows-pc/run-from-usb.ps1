#Requires -Version 5.1
<#
.SYNOPSIS
  Find SK1Transfer USB, run inventory, save TOC.md. For use via SSH from Mac.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File run-from-usb.ps1
#>
$ErrorActionPreference = "Stop"

$vol = Get-Volume | Where-Object { $_.FileSystemLabel -eq "SK1Transfer" } | Select-Object -First 1
if (-not $vol) {
    Write-Error "USB drive 'SK1Transfer' not found. Plug in the USB and try again."
    exit 1
}

$driveLetter = $vol.DriveLetter
if (-not $driveLetter) {
    Write-Error "Volume SK1Transfer has no drive letter."
    exit 1
}

$usbRoot = "${driveLetter}:\"
$pyScript = Join-Path $usbRoot "inventory-rich.py"
$ps1Script = Join-Path $usbRoot "windows-system-inventory.ps1"
$outputPath = Join-Path $usbRoot "TOC.md"

if (Test-Path $pyScript) {
    $python = $null
    foreach ($cmd in @("python", "python3", "py")) {
        try {
            $null = Get-Command $cmd -ErrorAction Stop
            $python = $cmd
            break
        } catch {}
    }
    if ($python) {
        & $python $pyScript $outputPath
    } else {
        Write-Host "Python not found. Falling back to PowerShell." -ForegroundColor Yellow
        & $ps1Script | Out-File -FilePath $outputPath
    }
} else {
    & $ps1Script | Out-File -FilePath $outputPath
}

# Output TOC to stdout so SSH caller can capture it
Get-Content $outputPath
