@echo off
rem Copy to %TEMP% first so the install folder can be deleted while this runs.
copy /y "%~dp0Uninstall.ps1" "%TEMP%\pd_uninstall.ps1" >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\pd_uninstall.ps1" -InstallDir "%~dp0."
