# Tweaks & Optimization Functions for WinSiRiady

# 1. Disable Telemetry & Data Diagnostics
function Optimize-Telemetry {
    Write-Host "[*] Mengurangi Telemetri & Layanan Diagnostik..." -ForegroundColor Cyan
    try {
        # Registry tweaks to disable telemetry
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction SilentlyContinue
        
        # Disable Connected User Experiences and Telemetry service
        Stop-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
        
        # Disable WAP Push Message Routing Service
        Stop-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
        Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

        Write-Host "[+] Telemetri berhasil dinonaktifkan." -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Gagal menonaktifkan telemetri: $_" -ForegroundColor Red
    }
}

# 2. Disable Cortana
function Optimize-Cortana {
    Write-Host "[*] Menonaktifkan Cortana..." -ForegroundColor Cyan
    try {
        $RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (!(Test-Path $RegistryPath)) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Windows Search" -Force | Out-Null
        }
        Set-ItemProperty -Path $RegistryPath -Name "AllowCortana" -Value 0 -Force -ErrorAction SilentlyContinue
        Write-Host "[+] Cortana berhasil dinonaktifkan." -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Gagal menonaktifkan Cortana: $_" -ForegroundColor Red
    }
}

# 3. Clean Windows Bloatware (Common UWP Apps)
function Remove-Bloatware {
    Write-Host "[*] Menghapus aplikasi bawaan (Bloatware)..." -ForegroundColor Cyan
    $BloatList = @(
        "*Microsoft.3DBuilder*",
        "*Microsoft.BingNews*",
        "*Microsoft.BingWeather*",
        "*Microsoft.GetHelp*",
        "*Microsoft.Getstarted*",
        "*Microsoft.Messaging*",
        "*Microsoft.MicrosoftOfficeHub*",
        "*Microsoft.MicrosoftSolitaireCollection*",
        "*Microsoft.Office.OneNote*",
        "*Microsoft.People*",
        "*Microsoft.SkypeApp*",
        "*Microsoft.Wallet*",
        "*Microsoft.WindowsFeedbackHub*",
        "*Microsoft.XboxApp*",
        "*Microsoft.XboxGamingOverlay*",
        "*Microsoft.XboxSpeechToTextOverlay*"
    )

    foreach ($App in $BloatList) {
        $Package = Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue
        if ($Package) {
            Write-Host "    Menghapus: $($Package.Name)" -ForegroundColor Yellow
            Remove-AppxPackage -Package $Package.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        }
    }
    Write-Host "[+] Penghapusan bloatware selesai." -ForegroundColor Green
}

# 4. Set Windows to Dark Theme
function Enable-DarkTheme {
    Write-Host "[*] Mengaktifkan Tema Gelap (Dark Theme)..." -ForegroundColor Cyan
    try {
        # App Dark Theme
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Force -ErrorAction SilentlyContinue
        # System Dark Theme
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Force -ErrorAction SilentlyContinue
        Write-Host "[+] Tema Gelap berhasil diaktifkan." -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Gagal mengaktifkan tema gelap: $_" -ForegroundColor Red
    }
}

# 5. Disable BitLocker Decryption
function Disable-BitLockerVolume {
    Write-Host "[*] Memeriksa status enkripsi BitLocker..." -ForegroundColor Cyan
    try {
        $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue
        if (-not $volumes) {
            Write-Host "[info] Tidak ada drive dengan enkripsi BitLocker aktif atau modul BitLocker tidak tersedia." -ForegroundColor Yellow
            return
        }
        foreach ($vol in $volumes) {
            if ($vol.VolumeStatus -eq "FullyDecrypted") {
                Write-Host "    Drive $($vol.MountPoint) sudah tidak terenkripsi (Fully Decrypted)." -ForegroundColor Yellow
            } else {
                Write-Host "    Menonaktifkan BitLocker pada drive $($vol.MountPoint)..." -ForegroundColor Yellow
                Disable-BitLocker -MountPoint $vol.MountPoint -ErrorAction Stop
                Write-Host "[+] Proses dekripsi BitLocker dimulai untuk drive $($vol.MountPoint). Proses ini berjalan di latar belakang Windows." -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "[-] Gagal menonaktifkan BitLocker: $_" -ForegroundColor Red
    }
}

# 6. Create System Restore Point
function Create-SystemRestorePoint {
    Write-Host "[*] Mengaktifkan System Restore dan membuat Restore Point..." -ForegroundColor Cyan
    try {
        Write-Host "    Mengaktifkan System Restore pada drive C:..." -ForegroundColor Yellow
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Write-Host "    Membuat System Restore Point 'restore point Optimasi WinSiRiady'..." -ForegroundColor Yellow
        # Set registry key to bypass 24 hours frequency limit for testing if needed
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Force -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "restore point Optimasi WinSiRiady" -RestorePointType "APPLICATION_INSTALL" -ErrorAction Stop
        Write-Host "[+] System Restore Point berhasil dibuat." -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Gagal membuat Restore Point: $_" -ForegroundColor Red
        Write-Host "    (Catatan: Pastikan komputer tidak sedang membuat restore point lain atau batasan grup GPO memblokirnya)." -ForegroundColor Yellow
    }
}

# Export functions for import in other scripts
Export-ModuleMember -Function Optimize-Telemetry, Optimize-Cortana, Remove-Bloatware, Enable-DarkTheme, Disable-BitLockerVolume, Create-SystemRestorePoint
