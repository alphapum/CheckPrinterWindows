@echo off
REM ปุ่ม Restart Spooler / Clear Queue บนหน้าเว็บต้องการสิทธิ์ Administrator
REM ไฟล์นี้จะขอสิทธิ์ (UAC prompt) ให้อัตโนมัติเมื่อดับเบิลคลิก
net session >nul 2>&1
if %errorLevel% == 0 goto :run

echo กำลังขอสิทธิ์ Administrator...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:run
set "PORT=8787"

echo Printer Status Dashboard: http://localhost:%PORT%/
echo หน้าต่างนี้ต้องเปิดค้างไว้ตลอดเวลาที่ใช้งานเว็บ กด Ctrl+C เพื่อหยุด server
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-WebServer.ps1" -Port %PORT%
