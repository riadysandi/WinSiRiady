@echo off
PowerShell -ExecutionPolicy Bypass -File "%~dp0send-glpi-inventory-to-prod.ps1" -Diagnostic
pause
