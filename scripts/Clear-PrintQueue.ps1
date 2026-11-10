<#
Stops the Print Spooler, PERMANENTLY deletes all queued print job files, then restarts it.
Destructive: use only when Restart-PrinterSpooler.ps1 alone did not fix a stuck queue.
Asks for confirmation unless -Force is passed.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Force,
    [string]$LogPath
)

if (-not $LogPath) {
    $LogPath = Join-Path $PSScriptRoot "clear-queue.log"
}

. (Join-Path $PSScriptRoot "PrinterLib.ps1")

function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $LogPath -Value $line
    Write-Host $line
}

$spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
$jobFiles = Get-ChildItem -Path $spoolPath -ErrorAction SilentlyContinue

if (-not $jobFiles -or $jobFiles.Count -eq 0) {
    Write-Log "No stuck print jobs found in spool folder. Nothing to clear."
    exit 0
}

Write-Log "Found $($jobFiles.Count) file(s) in print queue:"
foreach ($f in $jobFiles) { Write-Log "  - $($f.Name)" }

if (-not $Force -and -not $PSCmdlet.ShouldProcess($spoolPath, "PERMANENTLY delete $($jobFiles.Count) queued print job file(s)")) {
    Write-Log "Aborted by user. No files deleted."
    exit 0
}

$result = Invoke-QueueClear
Write-Log $result.Message

if ($result.Success) { exit 0 } else { exit 1 }
