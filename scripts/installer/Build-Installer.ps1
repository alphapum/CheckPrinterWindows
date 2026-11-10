# Builds PrinterDashboard-Setup.exe (single file) using Windows' built-in IExpress.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$root = Split-Path $here -Parent
$out  = Join-Path $root 'PrinterDashboard-Setup.exe'

$tmpExe = Join-Path $env:TEMP 'PrinterDashboard-Setup.exe'
Remove-Item $tmpExe -ErrorAction SilentlyContinue
$stage = Join-Path $env:TEMP 'pd_build'
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory $stage | Out-Null
foreach ($f in 'PrinterDashboard.hta','Dashboard-Runner.ps1','PrinterLib.ps1') { Copy-Item (Join-Path $root $f) $stage }
foreach ($f in 'Install.cmd','Install.ps1','PrinterCheck.ico','Uninstall.cmd','Uninstall.ps1') { Copy-Item (Join-Path $here $f) $stage }

$names = Get-ChildItem $stage -File | Select-Object -ExpandProperty Name
$strings = ($names | ForEach-Object -Begin {$i=0} -Process { "FILE$i=`"$_`""; $i++ }) -join "`r`n"
$list    = ($names | ForEach-Object -Begin {$i=0} -Process { "%FILE$i%="; $i++ }) -join "`r`n"

$sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$tmpExe
FriendlyName=Printer Dashboard Setup
AppLaunched=cmd /c Install.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[Strings]
$strings
[SourceFiles]
SourceFiles0=$stage\
[SourceFiles0]
$list
"@
$sedPath = Join-Path $env:TEMP 'pd_build.sed'
Set-Content -Path $sedPath -Value $sed -Encoding ASCII

$proc = Start-Process iexpress.exe -ArgumentList "/N",$sedPath -PassThru -WindowStyle Hidden
[void]$proc.WaitForExit(120000)
if (Test-Path $tmpExe) { Copy-Item $tmpExe $out -Force }
if (Test-Path $out) { "Built: $out ($([int]((Get-Item $out).Length/1KB)) KB)" } else { throw "IExpress did not produce $out" }
