<#
Restarts the Print Spooler service WITHOUT deleting any queued print jobs.
Windows will attempt to resume queued jobs automatically once the service is back up.
#>
[CmdletBinding()]
param(
    [string]$LogPath
)

if (-not $LogPath) {
    $LogPath = Join-Path $PSScriptRoot "spooler-restart.log"
}

. (Join-Path $PSScriptRoot "PrinterLib.ps1")

function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $LogPath -Value $line
    Write-Host $line
}

Write-Log "Restarting Print Spooler service..."
$result = Invoke-SpoolerRestart
Write-Log $result.Message

if ($result.Success) { exit 0 } else { exit 1 }
