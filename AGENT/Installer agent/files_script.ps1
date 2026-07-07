# =========================
# Install GLPI Agent (Full) + Prompt TAG
# + RustDesk (silent) + Set Permanent Password
# Interval inventory TIDAK diatur di klien (ikut server)
# =========================

# --- KONFIG ---
$ServerURL = "https://itpma-ticketing.pinusmerahabadi.co.id/plugins/glpiinventory/"
$Version   = "latest"  # GLPI Agent release tag; atau "1.12"
$Arch      = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$TempDir   = "$env:TEMP\glpi-agent-install"
$LogFile   = "$TempDir\install_glpi_agent_with_tag.log"
$MsiLogFile = "$TempDir\glpi-agent-msi.log"

function Test-IsAdministrator {
  $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ===== Helper Notifikasi =====
try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop } catch {}
function Show-Notify([string]$title, [string]$message, [string]$level = "Info") {
  Write-Host "[$level] $title : $message"
  try { [System.Windows.MessageBox]::Show($message, $title, 'OK', 'Information') | Out-Null } catch {}
}

if (-not (Test-IsAdministrator)) {
  $selfPath = $MyInvocation.MyCommand.Path
  if (-not $selfPath) {
    throw "Tidak bisa menentukan path script untuk elevasi admin."
  }

  Write-Host ">> Meminta hak Administrator untuk instalasi GLPI Agent..."
  try {
    Start-Process -FilePath "powershell.exe" `
      -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", "`"$selfPath`"") `
      -Verb RunAs `
      -Wait
    exit $LASTEXITCODE
  } catch {
    Show-Notify "Instalasi GLPI Agent - Gagal" "Instalasi butuh hak Administrator. Jalankan ulang lalu klik Yes pada UAC." "Error"
    throw
  }
}

# --- PREPARE ---
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
try { Stop-Transcript | Out-Null } catch {}
Start-Transcript -Path $LogFile -Append | Out-Null

# --- Input TAG dari user ---
Add-Type -AssemblyName Microsoft.VisualBasic
$AssetTag = [Microsoft.VisualBasic.Interaction]::InputBox(
  "Masukkan Nomor Asset (TAG) untuk agent GLPI:",
  "Input Nomor Asset",
  ""
).Trim()
if ([string]::IsNullOrWhiteSpace($AssetTag)) {
  Write-Error "Nomor Asset (TAG) wajib diisi. Batalkan instalasi."
  Show-Notify "Instalasi GLPI Agent - Gagal" "Nomor Asset (TAG) wajib diisi. Instalasi dibatalkan." "Error"
  Stop-Transcript | Out-Null
  exit 1
}

# --- Ambil GLPI Agent MSI dari GitHub releases ---
if ($Version -eq "latest") {
  $BaseApi = "https://api.github.com/repos/glpi-project/glpi-agent/releases/latest"
} else {
  $BaseApi = "https://api.github.com/repos/glpi-project/glpi-agent/releases/tags/$Version"
}
try {
  $release = Invoke-RestMethod -Uri $BaseApi -UseBasicParsing
  $asset = $release.assets |
    Where-Object { $_.name -match "glpi-agent-.*-$Arch\.msi$" } |
    Select-Object -First 1
  if (-not $asset) { throw "MSI $Arch tidak ditemukan pada rilis $($release.tag_name)" }
  $MsiUrl  = $asset.browser_download_url
  $MsiPath = Join-Path $TempDir $asset.name
  Write-Host ">> Unduh GLPI Agent: $MsiUrl"
  Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiPath -UseBasicParsing
} catch {
  Write-Error "Gagal unduh MSI GLPI Agent: $($_.Exception.Message)"
  Show-Notify "Instalasi GLPI Agent - Gagal" "Gagal unduh MSI: $($_.Exception.Message)" "Error"
  Stop-Transcript | Out-Null
  exit 1
}

# --- Instal GLPI Agent (tanpa konfigurasi interval lokal) ---
# Penting: HANYA parameter minimum yang diperlukan (SERVER & TAG), sisanya default.
$msiArgs = @(
  "/i", "`"$MsiPath`"",
  "SERVER=`"$ServerURL`"",
  "TAG=`"$AssetTag`"",
  "ADDLOCAL=ALL",
  "/quiet", "/norestart",
  "/l*v", "`"$MsiLogFile`""
)
Write-Host ">> Instal GLPI Agent (silent) dengan TAG=$AssetTag ..."
$proc = Start-Process "msiexec.exe" -ArgumentList $msiArgs -PassThru -Wait
if ($proc.ExitCode -ne 0) {
  Write-Error "Instalasi GLPI Agent gagal. Exit code: $($proc.ExitCode). Lihat log: $LogFile ; MSI log: $MsiLogFile"
  Show-Notify "Instalasi GLPI Agent - Gagal" "MSI ExitCode: $($proc.ExitCode)`nLog: $LogFile`nMSI log: $MsiLogFile" "Error"
  Stop-Transcript | Out-Null
  exit $proc.ExitCode
}

# --- Pastikan service GLPI Agent berjalan ---
$ServiceName = "glpi-agent"
try {
  $svc = Get-Service -Name $ServiceName -ErrorAction Stop
  if ($svc.Status -ne 'Running') { Start-Service -Name $ServiceName }
  Set-Service -Name $ServiceName -StartupType Automatic
} catch {
  Write-Warning "Service $ServiceName tidak bisa dijalankan: $($_.Exception.Message)"
}

# --- Notifikasi & Selesai ---
Write-Host ">> Selesai. Log: $LogFile"
Show-Notify "Instalasi GLPI Agent - Berhasil" ("GLPI Agent berhasil diinstal dengan TAG: $AssetTag`nService: $ServiceName (Auto)`nLog: $LogFile") "Success"
Stop-Transcript | Out-Null
