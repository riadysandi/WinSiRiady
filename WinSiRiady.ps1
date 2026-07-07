# WinSiRiady Utility - Main Application Script
# Jalankan sebagai Administrator. Mendukung eksekusi lokal maupun via: irm URL | iex

# === STEP 1: ADMINISTRATOR CHECK ===
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm 'https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1' | iex`"" -Verb RunAs
    exit
}

# === STEP 2: RESOLVE ROOT PATH (Lokal atau Remote via IEX) ===
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$LocalRoot = if ($PSScriptRoot -and $PSScriptRoot -ne "") {
    $PSScriptRoot
} else {
    # Menjalankan via IEX/Cloud - download berkas pendukung ke TEMP dulu
    $tempRoot = Join-Path $env:TEMP "WinSiRiady"
    if (-not (Test-Path $tempRoot)) {
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    }

    $baseUrl = "https://raw.githubusercontent.com/riadysandi/WinSiRiady/master"
    Write-Host "[WinSiRiady] Mengunduh berkas dari GitHub..." -ForegroundColor Cyan
    
    try {
        Invoke-WebRequest -Uri "$baseUrl/apps.json" -OutFile (Join-Path $tempRoot "apps.json") -UseBasicParsing -ErrorAction Stop
        Invoke-WebRequest -Uri "$baseUrl/tweaks.ps1" -OutFile (Join-Path $tempRoot "tweaks.ps1") -UseBasicParsing -ErrorAction Stop
        Write-Host "[WinSiRiady] Berkas pendukung siap." -ForegroundColor Green
    } catch {
        Write-Host "[WinSiRiady] GAGAL mengunduh berkas: $_" -ForegroundColor Red
    }

    $tempRoot
}

# === STEP 3: LOAD WPF ASSEMBLIES ===
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

# === STEP 4: DEFINISI ANTARMUKA GUI (XAML) ===
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinSiRiady Utility" Height="650" Width="850" Background="#1e1e2e" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#252538" Padding="15" BorderBrush="#89b4fa" BorderThickness="0,0,0,2">
            <StackPanel>
                <TextBlock Text="WinSiRiady Utility" FontSize="26" FontWeight="Bold" Foreground="#89b4fa"/>
                <TextBlock Text="Alat Optimasi &amp; Instalasi Windows Pribadi" FontSize="12" Foreground="#a6adc8" Margin="0,5,0,0"/>
            </StackPanel>
        </Border>

        <!-- Main Content (Tabs) -->
        <TabControl Grid.Row="1" Background="#1e1e2e" BorderThickness="0" Margin="10">
            <TabControl.Resources>
                <Style TargetType="TabItem">
                    <Setter Property="Background" Value="#313244"/>
                    <Setter Property="Foreground" Value="#cdd6f4"/>
                    <Setter Property="Padding" Value="15,8"/>
                    <Setter Property="FontSize" Value="14"/>
                    <Setter Property="FontWeight" Value="SemiBold"/>
                    <Setter Property="BorderThickness" Value="0"/>
                </Style>
            </TabControl.Resources>

            <!-- TAB 1: INSTALL APPS -->
            <TabItem Header="Instal Aplikasi">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel x:Name="AppsContainer" Margin="5"/>
                    </ScrollViewer>
                    <Button Grid.Row="1" x:Name="BtnInstallApps" Content="Instal Aplikasi Terpilih" Height="40" Background="#89b4fa" Foreground="#11111b" FontWeight="Bold" BorderThickness="0" Margin="0,10,0,0"/>
                </Grid>
            </TabItem>

            <!-- TAB 2: SYSTEM OPTIMIZATION -->
            <TabItem Header="Optimasi Sistem">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel VerticalAlignment="Top" Margin="5">
                        <TextBlock Text="Pilih Tweak Optimasi Windows:" FontSize="16" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,15"/>
                        <CheckBox x:Name="ChkTelemetry" Content="Matikan Telemetri &amp; Diagnostik (Meningkatkan Privasi)" Foreground="#cdd6f4" FontSize="13" Margin="0,0,0,10" IsChecked="True"/>
                        <CheckBox x:Name="ChkCortana" Content="Nonaktifkan Cortana (Menghemat RAM)" Foreground="#cdd6f4" FontSize="13" Margin="0,0,0,10" IsChecked="True"/>
                        <CheckBox x:Name="ChkBloatware" Content="Hapus Aplikasi Bawaan (Bloatware Windows)" Foreground="#cdd6f4" FontSize="13" Margin="0,0,0,10" IsChecked="False"/>
                        <CheckBox x:Name="ChkDarkTheme" Content="Aktifkan Tema Gelap (Dark Mode)" Foreground="#cdd6f4" FontSize="13" Margin="0,0,0,10" IsChecked="True"/>
                    </StackPanel>
                    <Button Grid.Row="1" x:Name="BtnApplyTweaks" Content="Jalankan Optimasi Terpilih" Height="40" Background="#a6e3a1" Foreground="#11111b" FontWeight="Bold" BorderThickness="0" Margin="0,10,0,0"/>
                </Grid>
            </TabItem>

            <!-- TAB 3: CONSOLE LOG -->
            <TabItem Header="Console Log">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="Console Output Log:" FontSize="12" Foreground="#a6adc8" Margin="0,0,0,5"/>
                    <TextBox Grid.Row="1" x:Name="TxtLog" Background="#11111b" Foreground="#a6e3a1" FontFamily="Consolas" FontSize="12" BorderBrush="#313244" VerticalScrollBarVisibility="Auto" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap"/>
                </Grid>
            </TabItem>

            <!-- TAB 4: ABOUT -->
            <TabItem Header="Tentang">
                <StackPanel Margin="20">
                    <TextBlock Text="WinSiRiady Utility v1.0.0" FontSize="20" FontWeight="Bold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                    <TextBlock Text="Mengotomatiskan setup Windows Anda pasca instalasi ulang." Foreground="#cdd6f4" TextWrapping="Wrap" Margin="0,0,0,15"/>
                    <TextBlock Text="Repositori GitHub:" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,5"/>
                    <TextBlock Text="https://github.com/riadysandi/WinSiRiady" Foreground="#f9e2af" Margin="0,0,0,15"/>
                    <TextBlock Text="Cara Menjalankan dari Internet:" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,5"/>
                    <TextBlock Text="irm https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1 | iex" Foreground="#a6e3a1" FontFamily="Consolas" FontSize="11" TextWrapping="Wrap"/>
                </StackPanel>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

# === STEP 5: LOAD XAML KE WPF WINDOW ===
$reader = New-Object System.Xml.XmlNodeReader($xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# === STEP 6: BIND CONTROLS ===
$AppsContainer  = $Window.FindName("AppsContainer")
$BtnInstallApps = $Window.FindName("BtnInstallApps")
$BtnApplyTweaks = $Window.FindName("BtnApplyTweaks")
$TxtLog         = $Window.FindName("TxtLog")
$ChkTelemetry   = $Window.FindName("ChkTelemetry")
$ChkCortana     = $Window.FindName("ChkCortana")
$ChkBloatware   = $Window.FindName("ChkBloatware")
$ChkDarkTheme   = $Window.FindName("ChkDarkTheme")

# === STEP 7: HELPER FUNCTION LOG ===
function Write-GuiLog {
    param([string]$Message)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $TxtLog.AppendText("[$ts] $Message`r`n")
    $TxtLog.ScrollToEnd()
}

# Helper function buat warna brush yang terbukti bekerja di PowerShell WPF
function New-Brush {
    param([string]$hex)
    $color = [System.Windows.Media.ColorConverter]::ConvertFromString($hex)
    $brush = New-Object System.Windows.Media.SolidColorBrush
    $brush.Color = $color
    return $brush
}

Write-GuiLog "WinSiRiady Utility berhasil dimuat."
Write-GuiLog "Root directory: $LocalRoot"

# === STEP 8: LOAD APPS DARI apps.json ===
$appsJsonPath = Join-Path $LocalRoot "apps.json"
Write-GuiLog "Memuat daftar aplikasi dari: $appsJsonPath"

$Global:AppCheckBoxes = @()

if (Test-Path $appsJsonPath) {
    try {
        $apps = Get-Content -Raw -Path $appsJsonPath -Encoding UTF8 | ConvertFrom-Json
        $groupedApps = $apps | Group-Object -Property Category
        foreach ($group in $groupedApps) {
            # Header Kategori bergaya "- Browsers" (Dicetak Tebal / Bold)
            $header = New-Object System.Windows.Controls.TextBlock
            $header.Text = "- $($group.Name)"
            $header.FontSize = 13
            $header.FontWeight = [System.Windows.FontWeights]::Bold
            $header.Foreground = New-Brush "#89b4fa"
            $header.Margin = "0,6,0,3"
            $AppsContainer.Children.Add($header) | Out-Null

            # Grid 3 Kolom untuk aplikasi dalam kategori ini
            $grid = New-Object System.Windows.Controls.Grid
            $col1 = New-Object System.Windows.Controls.ColumnDefinition; $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $col2 = New-Object System.Windows.Controls.ColumnDefinition; $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $col3 = New-Object System.Windows.Controls.ColumnDefinition; $col3.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $grid.ColumnDefinitions.Add($col1)
            $grid.ColumnDefinitions.Add($col2)
            $grid.ColumnDefinitions.Add($col3)

            $appList = @($group.Group)
            $rowCount = [Math]::Ceiling($appList.Count / 3)
            for ($r = 0; $r -lt $rowCount; $r++) {
                $rowDef = New-Object System.Windows.Controls.RowDefinition
                $rowDef.Height = [System.Windows.GridLength]::Auto
                $grid.RowDefinitions.Add($rowDef)
            }

            for ($i = 0; $i -lt $appList.Count; $i++) {
                $app = $appList[$i]
                $row = [Math]::Floor($i / 3)
                $col = $i % 3

                # CheckBox Aplikasi (Font Normal / Tidak Bold, Jarak Rapat)
                $chk = New-Object System.Windows.Controls.CheckBox
                $chk.Content = $app.Name
                $chk.Foreground = New-Brush "#cdd6f4"
                $chk.FontSize = 12
                $chk.Margin = "4,1,4,1"
                $chk.Tag = $app
                [System.Windows.Controls.Grid]::SetRow($chk, $row)
                [System.Windows.Controls.Grid]::SetColumn($chk, $col)
                $grid.Children.Add($chk) | Out-Null
                $Global:AppCheckBoxes += $chk
            }

            $AppsContainer.Children.Add($grid) | Out-Null
        }
        Write-GuiLog "Berhasil memuat $($apps.Count) aplikasi dalam $($groupedApps.Count) kategori."
    } catch {
        Write-GuiLog "[-] Error membaca apps.json: $_"
    }
} else {
    Write-GuiLog "[-] File apps.json tidak ditemukan di: $appsJsonPath"
}

# === STEP 9: TIMER UNTUK MONITOR BACKGROUND JOB ===
$Global:Job = $null
$Global:MonitorTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:MonitorTimer.Interval = [TimeSpan]::FromMilliseconds(300)

$Global:MonitorTimer.Add_Tick({
    if ($null -ne $Global:Job) {
        $output = Receive-Job -Job $Global:Job
        if ($output) {
            foreach ($line in $output) {
                Write-GuiLog $line
            }
        }
        if ($Global:Job.State -ne "Running") {
            $Global:MonitorTimer.Stop()
            $leftover = Receive-Job -Job $Global:Job
            if ($leftover) {
                foreach ($line in $leftover) { Write-GuiLog $line }
            }
            Remove-Job -Job $Global:Job
            $Global:Job = $null
            $BtnInstallApps.IsEnabled = $true
            $BtnApplyTweaks.IsEnabled = $true
            Write-GuiLog "[+] Operasi selesai."
        }
    }
})

# === STEP 10: EVENT - INSTALL APPS ===
$BtnInstallApps.Add_Click({
    $selectedApps = @()
    foreach ($chk in $Global:AppCheckBoxes) {
        if ($chk.IsChecked -eq $true) {
            $selectedApps += $chk.Tag
        }
    }

    if ($selectedApps.Count -eq 0) {
        Write-GuiLog "[!] Pilih minimal satu aplikasi untuk diinstal."
        return
    }

    $BtnInstallApps.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false
    Write-GuiLog "[*] Memulai instalasi $($selectedApps.Count) aplikasi..."

    $InstallBlock = {
        param($appsToInstall)
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        foreach ($app in $appsToInstall) {
            Write-Output ">> Memproses: $($app.Name)..."
            if ($app.Type -eq "winget") {
                & winget install --id $app.Id --silent --accept-source-agreements --accept-package-agreements
                if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189 -or $LASTEXITCODE -eq -1978335222) {
                    Write-Output "[+] Berhasil: $($app.Name) (Terinstal / Sudah ada)"
                } else {
                    Write-Output "[-] Gagal: $($app.Name) (Exit code: $LASTEXITCODE)"
                }
            }
            elseif ($app.Type -eq "github_release") {
                try {
                    $api = Invoke-RestMethod -Uri "https://api.github.com/repos/$($app.Repo)/releases/latest" -ErrorAction Stop
                    $asset = $api.assets | Where-Object { $_.name -like $app.AssetFilter } | Select-Object -First 1
                    if ($null -eq $asset) {
                        Write-Output "[-] Tidak ditemukan aset dengan filter '$($app.AssetFilter)'"
                        continue
                    }
                    $dest = Join-Path $env:TEMP $asset.name
                    Write-Output "    Mengunduh $($asset.name)..."
                    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing
                    Start-Process -FilePath $dest -Wait
                    Remove-Item $dest -ErrorAction SilentlyContinue
                    Write-Output "[+] Selesai: $($app.Name)"
                } catch {
                    Write-Output "[-] Error GitHub Release: $_"
                }
            }
            elseif ($app.Type -eq "direct_link") {
                try {
                    $fileName = if ($app.FileName) { $app.FileName } else { [System.IO.Path]::GetFileName([System.Uri]::new($app.Url).AbsolutePath) }
                    if (-not $fileName) { $fileName = "installer.exe" }
                    
                    $dest = Join-Path $env:TEMP $fileName
                    Write-Output "    Mengunduh dari URL langsung..."
                    Invoke-WebRequest -Uri $app.Url -OutFile $dest -UseBasicParsing -ErrorAction Stop
                    
                    Write-Output "    Menjalankan installer: $fileName..."
                    $args = if ($app.Args) { $app.Args } else { "" }
                    if ($args -ne "") {
                        $proc = Start-Process -FilePath $dest -ArgumentList $args -Wait -PassThru
                        Write-Output "[+] Selesai: $($app.Name) (Exit code: $($proc.ExitCode))"
                    } else {
                        Start-Process -FilePath $dest -Wait
                        Write-Output "[+] Selesai: $($app.Name)"
                    }
                    Remove-Item $dest -ErrorAction SilentlyContinue
                } catch {
                    Write-Output "[-] Error unduhan langsung: $_"
                }
            }
            elseif ($app.Type -eq "download_to_folder") {
                try {
                    $targetDir = "C:\WinSiRiady"
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                        Write-Output "[*] Membuat folder: $targetDir"
                    }
                    
                    $fileName = if ($app.FileName) { $app.FileName } else { [System.IO.Path]::GetFileName([System.Uri]::new($app.Url).AbsolutePath) }
                    if (-not $fileName) { $fileName = "downloaded_file.zip" }
                    
                    $dest = Join-Path $targetDir $fileName
                    Write-Output "    Mengunduh berkas ke $targetDir..."
                    Invoke-WebRequest -Uri $app.Url -OutFile $dest -UseBasicParsing -ErrorAction Stop
                    Write-Output "[+] Berkas berhasil diunduh ke: $dest"
                    
                    # Auto extract if Extract is set to true
                    if ($app.Extract -eq $true) {
                        if ($fileName.EndsWith(".zip", [System.StringComparison]::OrdinalIgnoreCase)) {
                            Write-Output "    Mengekstrak berkas ZIP..."
                            Expand-Archive -Path $dest -DestinationPath $targetDir -Force
                            Write-Output "[+] Ekstraksi ZIP selesai."
                            Remove-Item $dest -ErrorAction SilentlyContinue
                        }
                        elseif ($fileName.EndsWith(".rar", [System.StringComparison]::OrdinalIgnoreCase) -or $fileName.EndsWith(".7z", [System.StringComparison]::OrdinalIgnoreCase)) {
                            $sevenZip = "C:\Program Files\7-Zip\7z.exe"
                            if (Test-Path $sevenZip) {
                                Write-Output "    Mengekstrak berkas dengan 7-Zip..."
                                & $sevenZip x $dest "-o$targetDir" -y 2>$null | Out-Null
                                Write-Output "[+] Ekstraksi selesai."
                                Remove-Item $dest -ErrorAction SilentlyContinue
                            } else {
                                Write-Output "[!] Gagal mengekstrak: 7-Zip tidak ditemukan di $sevenZip. File tetap disimpan di: $dest"
                            }
                        }
                    }
                } catch {
                    Write-Output "[-] Error download_to_folder: $_"
                }
            }
        }
    }

    $Global:Job = Start-Job -ScriptBlock $InstallBlock -ArgumentList @(,$selectedApps)
    $Global:MonitorTimer.Start()
})

# === STEP 11: EVENT - APPLY TWEAKS ===
$BtnApplyTweaks.Add_Click({
    $tweaks = @{
        Telemetry = [bool]$ChkTelemetry.IsChecked
        Cortana   = [bool]$ChkCortana.IsChecked
        Bloatware = [bool]$ChkBloatware.IsChecked
        DarkTheme = [bool]$ChkDarkTheme.IsChecked
    }

    $BtnInstallApps.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false
    Write-GuiLog "[*] Menjalankan optimasi sistem..."

    $TweaksBlock = {
        param($tweaks, $rootPath)
        $tweaksFile = Join-Path $rootPath "tweaks.ps1"
        if (Test-Path $tweaksFile) {
            . $tweaksFile
        } else {
            Write-Output "[-] tweaks.ps1 tidak ditemukan di: $rootPath"
            return
        }
        if ($tweaks.Telemetry) { Optimize-Telemetry }
        if ($tweaks.Cortana)   { Optimize-Cortana }
        if ($tweaks.Bloatware) { Remove-Bloatware }
        if ($tweaks.DarkTheme) { Enable-DarkTheme }
    }

    $Global:Job = Start-Job -ScriptBlock $TweaksBlock -ArgumentList $tweaks, $LocalRoot
    $Global:MonitorTimer.Start()
})

# === STEP 12: TAMPILKAN WINDOW ===
$Window.ShowDialog() | Out-Null
