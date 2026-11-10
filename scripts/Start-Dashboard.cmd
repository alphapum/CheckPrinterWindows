@echo off
rem Opens PrinterDashboard.hta as Administrator (UAC prompt -> click Yes).
powershell.exe -NoProfile -Command "Start-Process -FilePath 'mshta.exe' -ArgumentList '\"%~dp0PrinterDashboard.hta\" /elevated' -Verb RunAs"
