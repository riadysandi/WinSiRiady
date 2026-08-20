@echo off
powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1') | iex"
