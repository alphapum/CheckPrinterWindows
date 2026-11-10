@echo off
set "INTERVAL_SECONDS=5"

REM หน้าต่างนี้จะค้างไว้และแจ้งสถานะ printer "ทุกเครื่องที่ติดตั้งในระบบ" แบบ realtime
REM ทุก %INTERVAL_SECONDS% วินาที ปิดหน้าต่างเอง หรือกด Ctrl+C เพื่อหยุด

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-PrinterReady.ps1" -Loop -IntervalSeconds %INTERVAL_SECONDS%
