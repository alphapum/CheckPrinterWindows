<#
Local-only web server for the Printer Status Dashboard (PWA).
Serves the static files in .\web and exposes:
    GET  /api/status           -> status of every printer (JSON array)
    POST /api/restart-spooler  -> restarts the Print Spooler (JSON)
    POST /api/clear-queue      -> permanently clears the print queue (JSON)

Bound to localhost only -- not reachable from other machines on the network.
#>
[CmdletBinding()]
param(
    [int]$Port = 8787
)

. (Join-Path $PSScriptRoot "PrinterLib.ps1")

$webRoot = Join-Path $PSScriptRoot "web"
$webRootFull = (Resolve-Path $webRoot).Path
$prefix = "http://localhost:$Port/"

$mimeTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.svg'  = 'image/svg+xml'
    '.css'  = 'text/css; charset=utf-8'
}

function Send-Json {
    param($Response, $Object, [int]$StatusCode = 200)
    $json = $Object | ConvertTo-Json -Depth 6
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $Response.StatusCode = $StatusCode
    $Response.ContentType = 'application/json; charset=utf-8'
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.OutputStream.Close()
}

function Send-StaticFile {
    param($Response, [string]$RequestPath)

    $relative = $RequestPath.TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }

    $candidate = [System.IO.Path]::GetFullPath((Join-Path $webRootFull $relative))

    # Prevent path traversal outside of the web root.
    if (-not $candidate.StartsWith($webRootFull, [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path $candidate -PathType Leaf)) {
        $Response.StatusCode = 404
        $Response.OutputStream.Close()
        return
    }

    $ext = [System.IO.Path]::GetExtension($candidate)
    $contentType = $mimeTypes[$ext]
    if (-not $contentType) { $contentType = 'application/octet-stream' }

    $bytes = [System.IO.File]::ReadAllBytes($candidate)
    $Response.StatusCode = 200
    $Response.ContentType = $contentType
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.OutputStream.Close()
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "ไม่สามารถเปิด server ที่ $prefix ได้: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "กด Enter เพื่อปิดหน้าต่าง"
    exit 1
}

Write-Host "Printer Status Dashboard: $prefix" -ForegroundColor Cyan
Write-Host "เปิดเบราว์เซอร์ไปที่ลิงก์ด้านบน แล้วกด Ctrl+C ที่นี่เพื่อหยุด server" -ForegroundColor Cyan

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.AbsolutePath
        $method = $request.HttpMethod

        try {
            if ($method -eq 'GET' -and $path -eq '/api/status') {
                Send-Json -Response $response -Object (Get-AllPrinterStatus)
            }
            elseif ($method -eq 'POST' -and $path -eq '/api/restart-spooler') {
                Send-Json -Response $response -Object (Invoke-SpoolerRestart)
            }
            elseif ($method -eq 'POST' -and $path -eq '/api/clear-queue') {
                Send-Json -Response $response -Object (Invoke-QueueClear)
            }
            else {
                Send-StaticFile -Response $response -RequestPath $path
            }
        } catch {
            Send-Json -Response $response -Object @{ Success = $false; Message = $_.Exception.Message } -StatusCode 500
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
