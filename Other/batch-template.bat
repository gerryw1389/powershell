@ECHO OFF
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dpn0.ps1""' -Verb RunAs}"
PAUSE

@ECHO OFF
PowerShell.exe -NoProfile ^
-Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command ". "%~dpn0.ps1"; Set-Outlook2013Config "' -Verb RunAs}"