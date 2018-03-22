@ECHO OFF
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command ". "%~dpn0.ps1"; Launch-WinAdminGUI"' -Verb RunAs}"