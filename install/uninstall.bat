@echo off
rem Removes RAC Maker (uninstall.ps1 does the work). Your maps stay.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
