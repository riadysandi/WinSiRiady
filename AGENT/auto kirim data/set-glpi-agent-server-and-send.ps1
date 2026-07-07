<#
.SYNOPSIS
    Trigger GLPI Agent mengirim inventory ke server prod SEKARANG (tanpa nunggu jadwal server).
#>

param(
    [string]$Server = "https://itpma-ticketing.pinusmerahabadi.co.id/plugins/glpiinventory/",
    [string]$Tag = "",
    [switch]$Diagnostic
)

$ErrorActionPreference = "Stop"

try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop } catch {}

function Show-Msg([string]$title, [string]$msg, [string]$icon = "Information") {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " $title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $msg
    try { [System.Windows.MessageBox]::Show($msg, $title, "OK", $icon) | Out-Null } catch {}
}

function Get-AgentPath {
    $agentPaths = @(
        "$env:ProgramFiles\GLPI-Agent",
        "$env:ProgramFiles(x86)\GLPI-Agent"
    )

    return $agentPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function New-DiagnosticLines {
    param(
        [string]$AgentPath,
        [string]$LauncherPath,
        [string]$ConfigPath,
        [string]$ServerUrl,
        [string]$ResolvedTag
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Timestamp     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $lines.Add("ComputerName  : $env:COMPUTERNAME")
    $lines.Add("UserName      : $env:USERNAME")
    $lines.Add("OS            : $([System.Environment]::OSVersion.VersionString)")
    $lines.Add("PowerShell    : $($PSVersionTable.PSVersion)")
    $lines.Add("AgentPath     : $(if ($AgentPath) { $AgentPath } else { '(tidak ditemukan)' })")
    $lines.Add("Launcher      : $(if ($LauncherPath -and (Test-Path $LauncherPath)) { $LauncherPath } else { '(tidak ditemukan)' })")
    $lines.Add("Config        : $(if ($ConfigPath -and (Test-Path $ConfigPath)) { $ConfigPath } else { '(tidak ditemukan)' })")
    $lines.Add("Service       : $(try { (Get-Service -Name 'glpi-agent' -ErrorAction Stop).Status } catch { 'Tidak ditemukan' })")
    $lines.Add("Tag           : $(if ([string]::IsNullOrWhiteSpace($ResolvedTag)) { '(kosong)' } else { $ResolvedTag })")
    $lines.Add("Server        : $ServerUrl")

    try {
        $uri = [Uri]$ServerUrl
        $lines.Add("ServerHost    : $($uri.Host)")
        $lines.Add("ServerPort    : $(if ($uri.IsDefaultPort) { if ($uri.Scheme -eq 'https') { 443 } elseif ($uri.Scheme -eq 'http') { 80 } else { '' } } else { $uri.Port })")
        try {
            $port = if ($uri.IsDefaultPort) {
                if ($uri.Scheme -eq "https") { 443 } elseif ($uri.Scheme -eq "http") { 80 } else { $uri.Port }
            } else {
                $uri.Port
            }
            $tnc = Test-NetConnection -ComputerName $uri.Host -Port $port -WarningAction SilentlyContinue
            $lines.Add("DNSResolved   : $($tnc.NameResolutionSucceeded)")
            $lines.Add("TcpReachable  : $($tnc.TcpTestSucceeded)")
            if ($tnc.RemoteAddress) { $lines.Add("RemoteAddress : $($tnc.RemoteAddress)") }
        } catch {
            $lines.Add("TcpTest       : Gagal - $($_.Exception.Message)")
        }
    } catch {
        $lines.Add("ServerParse   : Gagal - $($_.Exception.Message)")
    }

    if ($AgentPath) {
        $batVersion = Join-Path $AgentPath "glpi-agent.bat"
        if (Test-Path $batVersion) {
            try {
                $versionText = & $batVersion --version 2>&1 | Out-String
                $versionText = $versionText.Trim()
                if ($versionText) { $lines.Add("AgentVersion  : $versionText") }
            } catch {
                $lines.Add("AgentVersion  : Gagal - $($_.Exception.Message)")
            }
        }
    }

    return $lines
}

$agentPath = Get-AgentPath

if (-not $agentPath) {
    Show-Msg "GLPI Inventory - GAGAL" "GLPI Agent tidak ditemukan di Program Files.`nInstall dulu via INST\files_script.ps1" "Error"
    throw "GLPI Agent tidak ditemukan."
}

$glpiLauncher = Join-Path $agentPath "glpi-agent.bat"
$cfgFile = Join-Path $agentPath "etc\agent.cfg"
$logDir = "$env:TEMP\glpi-inventory-send"

if (-not (Test-Path $glpiLauncher)) {
    Show-Msg "GLPI Inventory - GAGAL" "Launcher GLPI Agent tidak ditemukan: $glpiLauncher" "Error"
    throw "Launcher GLPI Agent tidak ditemukan."
}

if (Test-Path $cfgFile) {
    $content = Get-Content $cfgFile -Raw
    if ([string]::IsNullOrWhiteSpace($Tag)) {
        $tagLine = ($content -split "`r?`n") | Where-Object { $_ -match "^\s*tag\s*=" } | Select-Object -First 1
        if ($tagLine -match "=\s*(.+?)\s*$") { $Tag = $Matches[1].Trim() }
    }
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logDir "send-$ts.log"
$errFile = Join-Path $logDir "send-$ts.err"
$diagFile = Join-Path $logDir "diagnostic-$ts.txt"
$agentLogFile = Join-Path $logDir "agent-$ts.log"

$diagLines = New-DiagnosticLines -AgentPath $agentPath -LauncherPath $glpiLauncher -ConfigPath $cfgFile -ServerUrl $Server -ResolvedTag $Tag
$diagLines | Set-Content -Path $diagFile -Encoding UTF8

$glpiArgs = @("--server=$Server", "--force", "--logger=file", "--logfile=$agentLogFile")
if (-not [string]::IsNullOrWhiteSpace($Tag)) { $glpiArgs += "--tag=$Tag" }

Write-Host ""
Write-Host ">> Mengirim inventory GLPI ke server..." -ForegroundColor Green
Write-Host "   Path  : $agentPath" -ForegroundColor Gray
Write-Host "   Server: $Server" -ForegroundColor Gray
Write-Host "   Tag   : $(if($Tag){$Tag}else{'(kosong)'})" -ForegroundColor Gray
Write-Host "   Log   : $logFile" -ForegroundColor Gray
Write-Host "   Agent : $agentLogFile" -ForegroundColor Gray
if ($Diagnostic) {
    Write-Host "   Diag  : $diagFile" -ForegroundColor Gray
}
Write-Host ""

$proc = Start-Process -FilePath $glpiLauncher `
    -ArgumentList $glpiArgs `
    -WorkingDirectory $agentPath `
    -Wait -PassThru -NoNewWindow `
    -RedirectStandardOutput $logFile `
    -RedirectStandardError $errFile

$out = if (Test-Path $logFile) { Get-Content $logFile -Raw -ErrorAction SilentlyContinue } else { "" }
$err = if (Test-Path $errFile) { Get-Content $errFile -Raw -ErrorAction SilentlyContinue } else { "" }

if ($Diagnostic) {
    Add-Content -Path $diagFile -Value ""
    Add-Content -Path $diagFile -Value "ProcessExitCode: $($proc.ExitCode)"
    Add-Content -Path $diagFile -Value "AgentLogFile   : $agentLogFile"
    if ($out) {
        Add-Content -Path $diagFile -Value ""
        Add-Content -Path $diagFile -Value "[STDOUT]"
        Add-Content -Path $diagFile -Value $out
    }
    if ($err) {
        Add-Content -Path $diagFile -Value ""
        Add-Content -Path $diagFile -Value "[STDERR]"
        Add-Content -Path $diagFile -Value $err
    }
}

if ($proc.ExitCode -eq 0) {
    $successMsg = "Inventory berhasil dikirim ke server."
    if ($Diagnostic) {
        $successMsg += "`n`nFile diagnosa:`n$diagFile"
    }
    Show-Msg "GLPI Inventory - BERHASIL" $successMsg
} else {
    $failureMsg = "ExitCode: $($proc.ExitCode)`n`nSTDOUT:`n$out`n`nSTDERR:`n$err`n`nLog dir: $logDir"
    if ($Diagnostic) {
        $failureMsg += "`n`nFile diagnosa:`n$diagFile"
    }
    Show-Msg "GLPI Inventory - GAGAL" $failureMsg "Error"
}
