<#
Checks the readiness of every printer installed on this machine, so a failed
printer gets caught before a check silently sits in a stuck queue.

Checks all printers by default:
    .\Test-PrinterReady.ps1
    .\Test-PrinterReady.ps1 -Loop -IntervalSeconds 5   (real-time monitor, window stays open until Ctrl+C)

Check a single printer only:
    .\Test-PrinterReady.ps1 -PrinterName "EPSON TM-U220" [-PrinterIP "192.168.1.50"]
#>
[CmdletBinding()]
param(
    [string]$PrinterName,

    [string]$PrinterIP,

    [switch]$Loop,

    [int]$IntervalSeconds = 5,

    [string]$LogPath
)

if (-not $LogPath) {
    $LogPath = Join-Path $PSScriptRoot "printer-check.log"
}

. (Join-Path $PSScriptRoot "PrinterLib.ps1")

function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $LogPath -Value $line
}

function Write-StatusLine {
    param($r)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if ($r.Ready) {
        Write-Host "[$ts] $($r.Name): ONLINE  - $($r.Reason)" -ForegroundColor Green
    } else {
        Write-Host "[$ts] $($r.Name): OFFLINE - $($r.Reason)" -ForegroundColor Red
    }
}

try {
    if ($Loop) {
        Write-Host "Monitoring all printers every $IntervalSeconds sec. Press Ctrl+C to stop." -ForegroundColor Cyan
        Write-Log "=== Real-time monitoring started (all printers) ==="

        $lastStatus = @{}
        while ($true) {
            $results = Get-AllPrinterStatus -PrinterName $PrinterName -PrinterIP $PrinterIP
            Write-Host "----- $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -----" -ForegroundColor DarkGray
            foreach ($r in $results) {
                Write-StatusLine $r
                if (-not $lastStatus.ContainsKey($r.Name) -or $lastStatus[$r.Name] -ne $r.Ready) {
                    $state = "OFFLINE"
                    if ($r.Ready) { $state = "ONLINE" }
                    Write-Log "STATUS CHANGE [$($r.Name)] -> $state`: $($r.Reason)"
                    $lastStatus[$r.Name] = $r.Ready
                }
            }
            Start-Sleep -Seconds $IntervalSeconds
        }
    } else {
        $results = Get-AllPrinterStatus -PrinterName $PrinterName -PrinterIP $PrinterIP
        foreach ($r in $results) {
            Write-StatusLine $r
            Write-Log "[$($r.Name)] Ready=$($r.Ready) Reason=$($r.Reason)"
        }
        $results

        if ($results | Where-Object { -not $_.Ready }) { exit 1 } else { exit 0 }
    }
} catch {
    $errMsg = $_.Exception.Message
    Write-Log "UNHANDLED ERROR: $errMsg"
    Write-Host ""
    Write-Host "เกิดข้อผิดพลาด: $errMsg" -ForegroundColor Red
    Write-Host "รายละเอียดถูกบันทึกไว้ที่ $LogPath" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "กด Enter เพื่อปิดหน้าต่าง"
    exit 1
}
