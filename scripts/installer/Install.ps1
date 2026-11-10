# Installs Printer Dashboard to %LOCALAPPDATA%\PrinterDashboard and creates
# Desktop + Start Menu shortcuts that always run as Administrator.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

$appName = 'Printer Dashboard'
$dest    = Join-Path $env:LOCALAPPDATA 'PrinterDashboard'
$files   = 'PrinterDashboard.hta', 'Dashboard-Runner.ps1', 'PrinterLib.ps1', 'PrinterCheck.ico', 'Uninstall.cmd', 'Uninstall.ps1'

function New-AdminShortcut($path) {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($path)
    $lnk.TargetPath       = Join-Path $env:WINDIR 'System32\mshta.exe'
    $lnk.Arguments        = '"' + (Join-Path $dest 'PrinterDashboard.hta') + '" /elevated'
    $lnk.WorkingDirectory = $dest
    $lnk.IconLocation     = (Join-Path $dest 'PrinterCheck.ico') + ',0'
    $lnk.Description      = $appName
    $lnk.Save()
    # Set the "Run as administrator" flag on the .lnk
    $bytes = [IO.File]::ReadAllBytes($path)
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [IO.File]::WriteAllBytes($path, $bytes)
}

try {
    Get-Process mshta -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.MainWindowTitle -like 'Printer Status*' } | Stop-Process -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    foreach ($f in $files) { Copy-Item (Join-Path $PSScriptRoot $f) $dest -Force }

    $desktop  = [Environment]::GetFolderPath('Desktop')
    $startDir = Join-Path ([Environment]::GetFolderPath('Programs')) $appName
    New-Item -ItemType Directory -Path $startDir -Force | Out-Null
    New-AdminShortcut (Join-Path $desktop  "$appName.lnk")
    New-AdminShortcut (Join-Path $startDir "$appName.lnk")

    # Register in Settings > Apps (per-user, no admin needed)
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\PrinterDashboard'
    New-Item -Path $key -Force | Out-Null
    $props = @{
        DisplayName     = $appName
        DisplayVersion  = '1.1.0'
        Publisher       = 'eatppv'
        DisplayIcon     = (Join-Path $dest 'PrinterCheck.ico')
        InstallLocation = $dest
        UninstallString = '"' + (Join-Path $dest 'Uninstall.cmd') + '"'
        NoModify        = 1
        NoRepair        = 1
    }
    foreach ($k in $props.Keys) { New-ItemProperty -Path $key -Name $k -Value $props[$k] -Force | Out-Null }

    [void][System.Windows.Forms.MessageBox]::Show(
        "ติดตั้งเรียบร้อยแล้ว`nเปิดโปรแกรมจากไอคอน '$appName' บน Desktop`n`nติดตั้งที่: $dest`nถอนการติดตั้ง: Settings > Apps > $appName",
        "$appName - Setup")
} catch {
    [void][System.Windows.Forms.MessageBox]::Show("ติดตั้งไม่สำเร็จ: $($_.Exception.Message)", "$appName - Setup", 'OK', 'Error')
    exit 1
}
