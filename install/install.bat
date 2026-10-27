@echo off
rem Installs RAC Maker (install.ps1 does the work; this only starts it, whatever the PowerShell script policy).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
