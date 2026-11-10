# Removes Printer Dashboard: shortcuts, Add/Remove Programs entry and install folder.
param([string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'PrinterDashboard'), [switch]$Silent)
Add-Type -AssemblyName System.Windows.Forms
$appName = 'Printer Dashboard'
$InstallDir = (Resolve-Path -LiteralPath $InstallDir -ErrorAction SilentlyContinue).Path
if (-not $InstallDir) { $InstallDir = Join-Path $env:LOCALAPPDATA 'PrinterDashboard' }

if (-not $Silent) {
    $ans = [System.Windows.Forms.MessageBox]::Show("ต้องการถอนการติดตั้ง $appName ใช่หรือไม่?", "$appName - Uninstall", 'YesNo', 'Question')
    if ($ans -ne 'Yes') { exit 0 }
}

try {
    Get-CimInstance Win32_Process -Filter "Name='mshta.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like '*PrinterDashboard.hta*' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    Remove-Item (Join-Path ([Environment]::GetFolderPath('Desktop')) "$appName.lnk") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path ([Environment]::GetFolderPath('Programs')) $appName) -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\PrinterDashboard' -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $env:TEMP '_printer_dashboard_elevate.flag'), (Join-Path $env:TEMP '_printer_dashboard_out.json') -Force -ErrorAction SilentlyContinue

    # Delete the install folder after this process exits.
    Start-Process cmd.exe -WindowStyle Hidden -ArgumentList '/c', "ping 127.0.0.1 -n 3 >nul & rmdir /s /q `"$InstallDir`" & del /f /q `"$env:TEMP\pd_uninstall.ps1`""

    if (-not $Silent) { [void][System.Windows.Forms.MessageBox]::Show("ถอนการติดตั้งเรียบร้อยแล้ว", "$appName - Uninstall") }
} catch {
    [void][System.Windows.Forms.MessageBox]::Show("ถอนการติดตั้งไม่สำเร็จ: $($_.Exception.Message)", "$appName - Uninstall", 'OK', 'Error')
    exit 1
}
