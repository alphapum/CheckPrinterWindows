<#
Shared functions for checking and controlling printers on this machine.
Dot-sourced by Test-PrinterReady.ps1, Restart-PrinterSpooler.ps1, Clear-PrintQueue.ps1,
and Start-WebServer.ps1 so all of them share the exact same logic.
#>

function Get-PrinterIPAddress {
    param([string]$PortName)
    $port = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
    if ($port -and $port.PrinterHostAddress) {
        return $port.PrinterHostAddress
    }
    return $null
}

# Get-Printer's PrinterStatus is a cached value Windows does not refresh just
# because a USB cable was pulled -- it keeps reporting "Normal" indefinitely.
# The Plug & Play device list is the only place that reflects a real unplug.
# Only trust this for genuine local hardware ports (USB/LPT/COM): WSD and
# network printers can share a generic driver name (e.g. "Microsoft IPP Class
# Driver") with unrelated devices, which would make the match ambiguous.
function Test-PrinterPhysicalPresence {
    param($Printer)

    if ($Printer.PortName -notmatch '^(USB\d+|LPT\d*:?|COM\d+:?)$') {
        return $null
    }

    $device = Get-PnpDevice -Class Printer -ErrorAction SilentlyContinue |
        Where-Object { $_.FriendlyName -eq $Printer.DriverName } |
        Select-Object -First 1

    if (-not $device) { return $null }
    return [bool]$device.Present
}

function Test-OnePrinter {
    param(
        [Parameter(Mandatory = $true)] $Printer,
        [string]$OverrideIP
    )

    $name = $Printer.Name

    if ($Printer.WorkOffline) {
        return [PSCustomObject]@{ Name = $name; Ready = $false; Reason = "Set to Work Offline."; IP = $null }
    }
    if ($Printer.PrinterStatus -ne 'Normal') {
        return [PSCustomObject]@{ Name = $name; Ready = $false; Reason = "Status is '$($Printer.PrinterStatus)'."; IP = $null }
    }

    # "Offline" is deliberately excluded here: it is a per-job flag that Windows
    # can leave stuck from an earlier check, so an actively-printing job (paper
    # really coming out) can still carry it. Real offline/disconnect states are
    # already caught above (WorkOffline, PrinterStatus) and below (ping, PnP).
    $badJobs = Get-PrintJob -PrinterName $name -ErrorAction SilentlyContinue |
        Where-Object { $_.JobStatus -match 'Error|Blocked|PaperOut' }
    if ($badJobs) {
        return [PSCustomObject]@{ Name = $name; Ready = $false; Reason = "$($badJobs.Count) job(s) stuck in an error state."; IP = $null }
    }

    $ip = $OverrideIP
    if (-not $ip) { $ip = Get-PrinterIPAddress -PortName $Printer.PortName }

    if ($ip) {
        $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $ping) {
            return [PSCustomObject]@{ Name = $name; Ready = $false; Reason = "Cannot reach IP $ip."; IP = $ip }
        }
        return [PSCustomObject]@{ Name = $name; Ready = $true; Reason = "Ready (IP $ip reachable)."; IP = $ip }
    }

    $present = Test-PrinterPhysicalPresence -Printer $Printer
    if ($present -eq $false) {
        return [PSCustomObject]@{ Name = $name; Ready = $false; Reason = "Device not connected (unplugged)."; IP = $null }
    }

    return [PSCustomObject]@{ Name = $name; Ready = $true; Reason = "Ready."; IP = $null }
}

function Get-AllPrinterStatus {
    param(
        [string]$PrinterName,
        [string]$PrinterIP,
        # Optional name -> IP map, for printers whose port carries no host address
        # (USB / WSD ports) but which are still reachable over the network.
        [hashtable]$IPOverrides
    )

    $spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
    if (-not $spooler -or $spooler.Status -ne 'Running') {
        return @([PSCustomObject]@{ Name = "(Print Spooler)"; Ready = $false; Reason = "Print Spooler service is not running."; IP = $null })
    }

    if ($PrinterName) {
        $printers = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
        if (-not $printers) {
            return @([PSCustomObject]@{ Name = $PrinterName; Ready = $false; Reason = "Printer not found on this system."; IP = $null })
        }
    } else {
        $printers = Get-Printer -ErrorAction SilentlyContinue
        if (-not $printers) {
            return @([PSCustomObject]@{ Name = "(none)"; Ready = $false; Reason = "No printers found on this system."; IP = $null })
        }
    }

    $results = foreach ($p in $printers) {
        $override = $null
        if ($PrinterName -and $PrinterIP) {
            $override = $PrinterIP
        } elseif ($IPOverrides -and $IPOverrides.ContainsKey($p.Name)) {
            $override = $IPOverrides[$p.Name]
        }
        Test-OnePrinter -Printer $p -OverrideIP $override
    }
    return $results
}

function Invoke-SpoolerRestart {
    try {
        Restart-Service -Name Spooler -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        $status = (Get-Service -Name Spooler).Status
        if ($status -eq 'Running') {
            return [PSCustomObject]@{ Success = $true; Message = "Spooler restarted successfully. Queued jobs were NOT deleted." }
        }
        return [PSCustomObject]@{ Success = $false; Message = "Spooler did not return to Running state (status: $status)." }
    } catch {
        return [PSCustomObject]@{ Success = $false; Message = Get-FriendlyServiceError $_.Exception.Message }
    }
}

function Get-FriendlyServiceError {
    param([string]$RawMessage)
    if ($RawMessage -match 'Cannot open .* service' -or $RawMessage -match 'Access is denied') {
        return "ไม่มีสิทธิ์ควบคุม Print Spooler ต้องปิดโปรแกรมแล้วเปิดใหม่ แล้วกด Yes ตอนที่ Windows ถามขอสิทธิ์ Administrator"
    }
    return $RawMessage
}

function Invoke-QueueClear {
    $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
    $jobFiles = Get-ChildItem -Path $spoolPath -ErrorAction SilentlyContinue

    if (-not $jobFiles -or $jobFiles.Count -eq 0) {
        return [PSCustomObject]@{ Success = $true; Message = "No stuck print jobs found. Nothing to clear."; ClearedCount = 0 }
    }

    $count = $jobFiles.Count
    try {
        Stop-Service -Name Spooler -Force -ErrorAction Stop
        Remove-Item -Path "$spoolPath\*" -Force -ErrorAction Stop
        Start-Service -Name Spooler -ErrorAction Stop
        Start-Sleep -Seconds 2

        $status = (Get-Service -Name Spooler).Status
        if ($status -ne 'Running') {
            return [PSCustomObject]@{ Success = $false; Message = "Cleared $count file(s) but spooler did not return to Running state."; ClearedCount = $count }
        }
        return [PSCustomObject]@{ Success = $true; Message = "Cleared $count queued print job file(s)."; ClearedCount = $count }
    } catch {
        Start-Service -Name Spooler -ErrorAction SilentlyContinue
        return [PSCustomObject]@{ Success = $false; Message = (Get-FriendlyServiceError $_.Exception.Message); ClearedCount = 0 }
    }
}
