<#
Bridge between PrinterDashboard.hta and PrinterLib.ps1.
The dashboard runs this hidden, then reads the JSON it writes to -OutFile.

    -Action status   -> { IsAdmin, Printers: [ { Name, Ready, Reason, IP } ] }
    -Action restart  -> { Success, Message }
    -Action clear    -> { Success, Message, ClearedCount }   (destructive)
#>
[CmdletBinding()]
param(
    [ValidateSet('status', 'restart', 'clear')]
    [string]$Action = 'status',

    [Parameter(Mandatory = $true)]
    [string]$OutFile
)

# ==== ใส่ IP ของ printer ที่ต่อผ่าน USB/WSD แต่อยากให้ ping เช็คด้วย ====
# ชื่อต้องตรงกับที่แสดงใน Windows เป๊ะๆ เว้นว่างไว้ได้ถ้าไม่ต้องการ
$IPOverrides = @{
    # "Canon MD MF660C Series" = "192.168.10.35"
}

. (Join-Path $PSScriptRoot "PrinterLib.ps1")

function Test-IsAdmin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

try {
    switch ($Action) {
        'restart' {
            $payload = Invoke-SpoolerRestart
        }
        'clear' {
            $payload = Invoke-QueueClear
        }
        default {
            $printers = @(Get-AllPrinterStatus -IPOverrides $IPOverrides)
            $payload = [PSCustomObject]@{
                IsAdmin  = (Test-IsAdmin)
                Printers = $printers
            }
        }
    }
} catch {
    $payload = [PSCustomObject]@{ Success = $false; Message = $_.Exception.Message }
}

ConvertTo-Json -InputObject $payload -Depth 6 | Out-File -FilePath $OutFile -Encoding Unicode
