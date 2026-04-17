#Requires -Version 5.1
<#
.SYNOPSIS
  Collects comprehensive Windows system inventory for troubleshooting and documentation.
.DESCRIPTION
  Gathers OS, hardware, drivers, firewall, apps, services, network, and security info.
  Outputs markdown to stdout. Run as Administrator for full driver list.
.EXAMPLE
  .\windows-system-inventory.ps1 | Out-File -FilePath TOC.md
  .\windows-system-inventory.ps1 > inventory.md
#>

$ErrorActionPreference = "SilentlyContinue"

function Write-Section { param($Title) Write-Output "`n## $Title`n" }
function Write-SubSection { param($Title) Write-Output "`n### $Title`n" }
function Write-Table { param($Data) $Data | Format-Table -AutoSize | Out-String -Stream | ForEach-Object { $_.TrimEnd() } }

$generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output "# Windows System Inventory"
Write-Output "Generated: $generated"
Write-Output "Computer: $env:COMPUTERNAME"
Write-Output "User: $env:USERNAME"

# === OS ===
Write-Section "Operating System"
try {
    $os = Get-CimInstance Win32_OperatingSystem
    @{
        "Name" = $os.Caption
        "Version" = $os.Version
        "Build" = $os.BuildNumber
        "Architecture" = $os.OSArchitecture
        "InstallDate" = $os.InstallDate
        "LastBoot" = $os.LastBootUpTime
    } | Format-List | Out-String -Stream | ForEach-Object { $_.TrimEnd() }
    Write-Output ""
} catch { Write-Output "  (Unable to query: $_)" }

# === Computer Info (Get-ComputerInfo if available) ===
Write-Section "Computer Identity"
try {
    $cs = Get-CimInstance Win32_ComputerSystem
    @{
        "Manufacturer" = $cs.Manufacturer
        "Model" = $cs.Model
        "SystemType" = $cs.SystemType
        "Domain" = $cs.Domain
        "TotalPhysicalMemory (GB)" = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    } | Format-List | Out-String -Stream | ForEach-Object { $_.TrimEnd() }
} catch { Write-Output "  (Unable to query: $_)" }

# === BIOS ===
Write-Section "BIOS"
try {
    $bios = Get-CimInstance Win32_BIOS
    @{
        "Manufacturer" = $bios.Manufacturer
        "Version" = $bios.SMBIOSBIOSVersion
        "Date" = $bios.ReleaseDate
    } | Format-List | Out-String -Stream | ForEach-Object { $_.TrimEnd() }
} catch { Write-Output "  (Unable to query: $_)" }

# === CPU ===
Write-Section "Processor"
try {
    Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Memory ===
Write-Section "Physical Memory"
try {
    $mem = Get-CimInstance Win32_PhysicalMemory
    $mem | Select-Object Manufacturer, Capacity, Speed, DeviceLocator | Format-Table -AutoSize | Out-String -Stream
    $total = ($mem | Measure-Object -Property Capacity -Sum).Sum / 1GB
    Write-Output "Total RAM: $([math]::Round($total, 2)) GB"
} catch { Write-Output "  (Unable to query: $_)" }

# === Disk Drives ===
Write-Section "Physical Disks"
try {
    Get-CimInstance Win32_DiskDrive | Select-Object Model, Size, InterfaceType, MediaType | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Logical Drives ===
Write-Section "Logical Drives"
try {
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}}, @{N='Free(GB)';E={[math]::Round($_.FreeSpace/1GB,2)}}, FileSystem | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Network Adapters ===
Write-Section "Network Adapters"
try {
    Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object Name, InterfaceDescription, MacAddress, LinkSpeed | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === IP Configuration ===
Write-Section "IP Configuration"
try {
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" } | Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Firewall Profiles ===
Write-Section "Firewall Profiles"
try {
    Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Firewall Rules (summary - enabled only) ===
Write-SubSection "Firewall Rules (Enabled, Top 50)"
try {
    Get-NetFirewallRule | Where-Object Enabled -eq True | Select-Object -First 50 DisplayName, Direction, Action, Profile | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Windows Drivers ===
Write-Section "Drivers (Third-Party)"
try {
    $drivers = Get-WindowsDriver -Online -All 2>$null | Where-Object { $_.ProviderName -notlike "Microsoft*" } | Select-Object -First 100 OriginalFileName, ClassName, ProviderName, Version
    if ($drivers) {
        $drivers | Format-Table -AutoSize | Out-String -Stream
        Write-Output "(Showing first 100 third-party drivers. Run as Administrator for full list.)"
    } else {
        Write-Output "  (Run as Administrator for driver list, or use: driverquery /v)"
    }
} catch {
    Write-Output "  (Get-WindowsDriver requires elevation. Run: driverquery /v for alternative)"
}

# === Installed Software ===
Write-Section "Installed Software"
try {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $apps = Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object DisplayName | Sort-Object DisplayName
    $apps | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Windows Features (optional) ===
Write-Section "Windows Features"
try {
    Get-WindowsOptionalFeature -Online | Where-Object State -eq Enabled | Select-Object FeatureName, State | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Services (auto-start, non-Microsoft) ===
Write-Section "Auto-Start Services (Non-Microsoft)"
try {
    Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Name -notlike ".*" } | Select-Object Name, DisplayName, Status | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Startup Programs ===
Write-Section "Startup Programs"
try {
    Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Installed Updates / Hotfixes ===
Write-Section "Recent Hotfixes (Last 30)"
try {
    Get-WmiObject Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 30 HotFixID, Description, InstalledOn | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === .NET Versions ===
Write-Section ".NET Framework Versions"
try {
    Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse -ErrorAction SilentlyContinue | Get-ItemProperty -Name Version, Release -ErrorAction SilentlyContinue | Where-Object Version | Select-Object PSChildName, Version, Release | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === PowerShell Version ===
Write-Section "PowerShell"
Write-Output "  Version: $($PSVersionTable.PSVersion)"
Write-Output "  Edition: $($PSVersionTable.PSEdition)"

# === Local Users ===
Write-Section "Local Users"
try {
    Get-LocalUser | Select-Object Name, Enabled, LastLogon | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Environment (PATH summary) ===
Write-Section "Environment (PATH entries)"
try {
    $pathEntries = $env:PATH -split ";" | Where-Object { $_.Trim() }
    $pathEntries | ForEach-Object { Write-Output "  $_" }
} catch { Write-Output "  (Unable to query: $_)" }

# === Antivirus / Security ===
Write-Section "Antivirus / Security Products"
try {
    Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct 2>$null | Select-Object displayName, productState | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === Open Ports (Listening) ===
Write-Section "Listening TCP Ports"
try {
    Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

# === USB / Amlogic Devices (for SK1 flashing) ===
Write-Section "USB / Amlogic Devices (Device Manager)"
try {
    Get-PnpDevice | Where-Object { $_.Class -match "USB|Universal" -or $_.FriendlyName -match "Amlogic|Aml_" } | Select-Object Status, Class, FriendlyName | Format-Table -AutoSize | Out-String -Stream
} catch { Write-Output "  (Unable to query: $_)" }

Write-Output "`n---`n*End of inventory*"
