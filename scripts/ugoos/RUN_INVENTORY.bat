@echo off
REM Run Windows system inventory with Rich dashboard. Saves to TOC.md in this folder.
REM Requires: Python with rich (pip install rich). Falls back to PowerShell if Python missing.

cd /d "%~dp0"

python inventory-rich.py "%~dp0TOC.md" 2>nul
if %errorlevel% equ 0 goto :done

python3 inventory-rich.py "%~dp0TOC.md" 2>nul
if %errorlevel% equ 0 goto :done

py inventory-rich.py "%~dp0TOC.md" 2>nul
if %errorlevel% equ 0 goto :done

echo Python not found. Using PowerShell...
powershell -ExecutionPolicy Bypass -File "%~dp0windows-system-inventory.ps1" > "%~dp0TOC.md"

:done
echo.
echo Inventory saved to TOC.md
pause
