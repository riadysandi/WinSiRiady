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

# === STEP 4: DEFINISI ANTARMUKA GUI PREMIUM (XAML) ===
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinSiRiady Utility" Height="620" Width="920" Background="#1e1e2e" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Sidebar Navigation Panel -->
        <Border Grid.Column="0" Background="#181825" BorderBrush="#313244" BorderThickness="0,0,1,0">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="100"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="50"/>
                </Grid.RowDefinitions>

                <!-- Title / Logo -->
                <StackPanel Grid.Row="0" VerticalAlignment="Center" Margin="20,0,0,0">
                    <TextBlock Text="WinSiRiady" FontSize="24" FontWeight="Bold" Foreground="#89b4fa"/>
                    <TextBlock Text="Windows Utility" FontSize="12" Foreground="#a6adc8" Margin="0,3,0,0"/>
                </StackPanel>

                <!-- Navigation Buttons -->
                <StackPanel Grid.Row="1" Margin="10,0,10,0">
                    <Button x:Name="BtnNavApps" Content="Instal Aplikasi" Height="40" Margin="0,5,0,5" Background="#313244" Foreground="#cdd6f4" FontWeight="SemiBold" BorderThickness="0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button x:Name="BtnNavTweaks" Content="Optimasi Sistem" Height="40" Margin="0,5,0,5" Background="Transparent" Foreground="#a6adc8" FontWeight="SemiBold" BorderThickness="0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button x:Name="BtnNavLog" Content="Console Log" Height="40" Margin="0,5,0,5" Background="Transparent" Foreground="#a6adc8" FontWeight="SemiBold" BorderThickness="0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button x:Name="BtnNavAbout" Content="Tentang" Height="40" Margin="0,5,0,5" Background="Transparent" Foreground="#a6adc8" FontWeight="SemiBold" BorderThickness="0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>

                <!-- Footer -->
                <TextBlock Grid.Row="2" Text="v1.0.0 - Stable | By Sandi Riady" FontSize="11" Foreground="#585b70" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <!-- Main Content Area -->
        <Grid Grid.Column="1" Margin="25">
            <!-- PAGE 1: APPS INSTALLER -->
            <Grid x:Name="PanelApps" Visibility="Visible">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="Instal Aplikasi" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,15"/>
                
                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="0,0,0,15">
                    <StackPanel x:Name="AppsContainer"/>
                </ScrollViewer>

                <StackPanel Grid.Row="2">
                    <!-- Custom Flat Styled ProgressBar -->
                    <ProgressBar x:Name="PrgInstall" Height="6" IsIndeterminate="True" Background="#313244" Foreground="#89b4fa" BorderThickness="0" Visibility="Collapsed" Margin="0,0,0,15">
                        <ProgressBar.Template>
                            <ControlTemplate TargetType="ProgressBar">
                                <Grid x:Name="TemplateRoot">
                                    <Border CornerRadius="3" Background="{TemplateBinding Background}"/>
                                    <Border x:Name="PART_Indicator" CornerRadius="3" Background="{TemplateBinding Foreground}" HorizontalAlignment="Left"/>
                                </Grid>
                            </ControlTemplate>
                        </ProgressBar.Template>
                    </ProgressBar>
                    <Button x:Name="BtnInstallApps" Content="Instal Aplikasi Terpilih" Height="45" Background="#89b4fa" Foreground="#11111b" FontWeight="Bold" BorderThickness="0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="8"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- PAGE 2: TWEAKS -->
            <Grid x:Name="PanelTweaks" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="Optimasi Sistem" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,15"/>
                
                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="0,0,0,15">
                    <StackPanel Margin="5">
                        <TextBlock Text="Pilih Tweak Optimasi Windows:" FontSize="14" FontWeight="SemiBold" Foreground="#a6adc8" Margin="0,0,0,15"/>
                        <CheckBox x:Name="ChkTelemetry" Content="Matikan Telemetri &amp; Diagnostik (Meningkatkan Privasi)" Foreground="#cdd6f4" FontSize="13" Margin="0,0,0,12" IsChecked="True"/>
                        <CheckBox x:Name="ChkCortana" Content="Nonaktifkan Cortana (Menghemat RAM)" Foreground="#cdd6f4" FontSize="13" Margin="0,0,0,12" IsChecked="True"/>
                        <CheckBox x:Name="ChkBloatware" Content="Hapus Aplikasi Bawaan (Bloatware Windows)" Foreground="#cdd6f4" FontSize="13" Margin="0,0,0,12" IsChecked="False"/>
                        <CheckBox x:Name="ChkDarkTheme" Content="Aktifkan Tema Gelap (Dark Mode)" Foreground="#cdd6f4" FontSize="13" Margin="0,0,0,12" IsChecked="True"/>
                    </StackPanel>
                </ScrollViewer>

                <StackPanel Grid.Row="2">
                    <ProgressBar x:Name="PrgTweaks" Height="6" IsIndeterminate="True" Background="#313244" Foreground="#a6e3a1" BorderThickness="0" Visibility="Collapsed" Margin="0,0,0,15">
                        <ProgressBar.Template>
                            <ControlTemplate TargetType="ProgressBar">
                                <Grid x:Name="TemplateRoot">
                                    <Border CornerRadius="3" Background="{TemplateBinding Background}"/>
                                    <Border x:Name="PART_Indicator" CornerRadius="3" Background="{TemplateBinding Foreground}" HorizontalAlignment="Left"/>
                                </Grid>
                            </ControlTemplate>
                        </ProgressBar.Template>
                    </ProgressBar>
                    <Button x:Name="BtnApplyTweaks" Content="Jalankan Optimasi Terpilih" Height="45" Background="#a6e3a1" Foreground="#11111b" FontWeight="Bold" BorderThickness="0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="8"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- PAGE 3: CONSOLE LOG -->
            <Grid x:Name="PanelLog" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="Console Output Log" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,15"/>
                <TextBox Grid.Row="1" x:Name="TxtLog" Background="#11111b" Foreground="#a6e3a1" FontFamily="Consolas" FontSize="12" BorderBrush="#313244" BorderThickness="1" VerticalScrollBarVisibility="Auto" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap" Padding="10">
                    <TextBox.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="8"/>
                        </Style>
                    </TextBox.Resources>
                </TextBox>
            </Grid>

            <!-- PAGE 4: ABOUT -->
            <Grid x:Name="PanelAbout" Visibility="Collapsed">
                <StackPanel Margin="5">
                    <TextBlock Text="Tentang WinSiRiady Utility" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,15"/>
                    <TextBlock Text="Aplikasi ini dikembangkan untuk mengotomatiskan instalasi perangkat lunak dan konfigurasi Windows pasca instalasi ulang." Foreground="#a6adc8" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,10"/>
                    <TextBlock Text="Dibuat oleh: Sandi Riady" FontSize="13" FontWeight="SemiBold" Foreground="#a6e3a1" Margin="0,0,0,20"/>
                    
                    <TextBlock Text="Repositori GitHub:" FontSize="14" FontWeight="SemiBold" Foreground="#cdd6f4" Margin="0,0,0,5"/>
                    <TextBlock Text="https://github.com/riadysandi/WinSiRiady" Foreground="#f9e2af" FontSize="13" Margin="0,0,0,20"/>

                    <TextBlock Text="Cara Menjalankan dari Cloud:" FontSize="14" FontWeight="SemiBold" Foreground="#cdd6f4" Margin="0,0,0,5"/>
                    <Border Background="#181825" CornerRadius="6" Padding="15" BorderBrush="#313244" BorderThickness="1">
                        <TextBlock Text="irm https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1 | iex" Foreground="#a6e3a1" FontFamily="Consolas" FontSize="11" TextWrapping="Wrap"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

# === STEP 5: LOAD XAML KE WPF WINDOW ===
$reader = New-Object System.Xml.XmlNodeReader($xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# === STEP 6: BIND CONTROLS ===
# Sidebar Buttons
$BtnNavApps     = $Window.FindName("BtnNavApps")
$BtnNavTweaks   = $Window.FindName("BtnNavTweaks")
$BtnNavLog      = $Window.FindName("BtnNavLog")
$BtnNavAbout    = $Window.FindName("BtnNavAbout")

# Panels
$PanelApps      = $Window.FindName("PanelApps")
$PanelTweaks    = $Window.FindName("PanelTweaks")
$PanelLog       = $Window.FindName("PanelLog")
$PanelAbout     = $Window.FindName("PanelAbout")

# Page Content Controls
$AppsContainer  = $Window.FindName("AppsContainer")
$BtnInstallApps = $Window.FindName("BtnInstallApps")
$BtnApplyTweaks = $Window.FindName("BtnApplyTweaks")
$TxtLog         = $Window.FindName("TxtLog")
$ChkTelemetry   = $Window.FindName("ChkTelemetry")
$ChkCortana     = $Window.FindName("ChkCortana")
$ChkBloatware   = $Window.FindName("ChkBloatware")
$ChkDarkTheme   = $Window.FindName("ChkDarkTheme")
$PrgInstall     = $Window.FindName("PrgInstall")
$PrgTweaks      = $Window.FindName("PrgTweaks")

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

# Fungsi notifikasi kustom bertema gelap dengan sudut melengkung dan mendukung DragMove
function Show-CustomNotification {
    param(
        [string]$message,
        [string]$type = "success"
    )
    
    # Petakan tipe ikon ke XML entity aman dan warna CSS/WPF
    $icon = "&#x2713;"     # Simbol Checkmark ✓ (Aman dari encoding)
    $iconColor = "#a6e3a1" # Hijau sukses
    
    if ($type -eq "warning") {
        $icon = "!"
        $iconColor = "#f9e2af" # Kuning peringatan
    }
    
    [xml]$notifXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="WinSiRiady Notification" Height="170" Width="380" Background="Transparent" WindowStartupLocation="CenterOwner" ResizeMode="NoResize" WindowStyle="None" AllowsTransparency="True">
        <Border Background="#1e1e2e" BorderBrush="#313244" BorderThickness="2" CornerRadius="12">
            <Grid Margin="15">
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <StackPanel Grid.Row="0" HorizontalAlignment="Center" VerticalAlignment="Center" Orientation="Horizontal">
                    <TextBlock Text="$icon" FontSize="36" FontWeight="Bold" Foreground="$iconColor" Margin="0,0,15,0" VerticalAlignment="Center"/>
                    <TextBlock Text="$message" FontSize="13" FontWeight="SemiBold" Foreground="#cdd6f4" TextWrapping="Wrap" VerticalAlignment="Center" Width="260"/>
                </StackPanel>
                
                <Button Grid.Row="1" x:Name="BtnCloseNotif" Content="Selesai" Height="32" Width="100" Background="#89b4fa" Foreground="#11111b" FontWeight="Bold" BorderThickness="0" HorizontalAlignment="Center">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="6"/>
                        </Style>
                    </Button.Resources>
                </Button>
            </Grid>
        </Border>
    </Window>
"@
    $notifReader = New-Object System.Xml.XmlNodeReader($notifXaml)
    $notifWindow = [Windows.Markup.XamlReader]::Load($notifReader)
    $notifWindow.Owner = $Window
    
    $btnClose = $notifWindow.FindName("BtnCloseNotif")
    $btnClose.Add_Click({
        $notifWindow.Close()
    })
    
    # Memungkinkan jendela didrag kemana saja
    $notifWindow.Add_MouseLeftButtonDown({
        $notifWindow.DragMove()
    })
    
    $notifWindow.ShowDialog() | Out-Null
}

Write-GuiLog "WinSiRiady Utility berhasil dimuat."
Write-GuiLog "Root directory: $LocalRoot"

# === STEP 8: SIDEBAR NAVIGATION LOGIC ===
$Panels = @{
    Apps   = $PanelApps
    Tweaks = $PanelTweaks
    Log    = $PanelLog
    About  = $PanelAbout
}

$NavButtons = @{
    Apps   = $BtnNavApps
    Tweaks = $BtnNavTweaks
    Log    = $BtnNavLog
    About  = $BtnNavAbout
}

function Switch-Panel {
    param([string]$target)
    
    # Sembunyikan semua panel, reset background tombol nav ke transparan
    foreach ($key in $Panels.Keys) {
        $Panels[$key].Visibility = [System.Windows.Visibility]::Collapsed
        $NavButtons[$key].Background = [System.Windows.Media.Brushes]::Transparent
        $NavButtons[$key].Foreground = New-Brush "#a6adc8"
    }
    
    # Tampilkan panel target, warnai tombol nav yang aktif
    $Panels[$target].Visibility = [System.Windows.Visibility]::Visible
    $NavButtons[$target].Background = New-Brush "#313244"
    $NavButtons[$target].Foreground = New-Brush "#cdd6f4"
}

$BtnNavApps.Add_Click({ Switch-Panel "Apps" })
$BtnNavTweaks.Add_Click({ Switch-Panel "Tweaks" })
$BtnNavLog.Add_Click({ Switch-Panel "Log" })
$BtnNavAbout.Add_Click({ Switch-Panel "About" })

# === STEP 9: LOAD APPS DARI apps.json ===
$appsJsonPath = Join-Path $LocalRoot "apps.json"
Write-GuiLog "Memuat daftar aplikasi dari: $appsJsonPath"

$Global:AppCheckBoxes = @()

if (Test-Path $appsJsonPath) {
    try {
        $apps = Get-Content -Raw -Path $appsJsonPath -Encoding UTF8 | ConvertFrom-Json
        $groupedApps = $apps | Group-Object -Property Category
        $brushConverter = New-Object System.Windows.Media.BrushConverter

        foreach ($group in $groupedApps) {
            # Header Kategori bergaya "- Browsers" (Dicetak Tebal / Bold)
            $header = New-Object System.Windows.Controls.TextBlock
            $header.Text = "- $($group.Name)"
            $header.FontSize = 13
            $header.FontWeight = [System.Windows.FontWeights]::Bold
            $header.Foreground = New-Brush "#89b4fa"
            $header.Margin = New-Object System.Windows.Thickness(0, 6, 0, 3)
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

                # CheckBox Aplikasi (Font Normal, Jarak Rapat)
                $chk = New-Object System.Windows.Controls.CheckBox
                $chk.Content = $app.Name
                $chk.Foreground = New-Brush "#cdd6f4"
                $chk.FontSize = 12
                $chk.Margin = New-Object System.Windows.Thickness(4, 1, 4, 1)
                $chk.Tag = $app
                [System.Windows.Controls.Grid]::SetRow($chk, $row)
                [System.Windows.Controls.Grid]::SetColumn($chk, $col)
                $grid.Children.Add($chk) | Out-Null
                $Global:AppCheckBoxes += $chk
            }

            $AppsContainer.Children.Add($grid) | Out-Null
        }
        Write-GuiLog "Berhasil memuat $($apps.Count) aplikasi."
    } catch {
        Write-GuiLog "[-] Error membaca apps.json: $_"
    }
} else {
    Write-GuiLog "[-] File apps.json tidak ditemukan di: $appsJsonPath"
}

# === STEP 10: TIMER UNTUK MONITOR BACKGROUND JOB ===
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
            
            # Re-enable Buttons
            $BtnInstallApps.IsEnabled = $true
            $BtnApplyTweaks.IsEnabled = $true
            
            # Hide ProgressBars
            $PrgInstall.Visibility = [System.Windows.Visibility]::Collapsed
            $PrgInstall.IsIndeterminate = $false
            $PrgTweaks.Visibility = [System.Windows.Visibility]::Collapsed
            $PrgTweaks.IsIndeterminate = $false

            Write-GuiLog "[+] Operasi selesai."
            
            # Notifikasi kustom bertema gelap saat selesai
            Show-CustomNotification "Proses instalasi / optimasi sistem telah selesai!" "✓" "#a6e3a1"
        }
    }
})

# === STEP 11: EVENT - INSTALL APPS ===
$BtnInstallApps.Add_Click({
    $selectedApps = @()
    foreach ($chk in $Global:AppCheckBoxes) {
        if ($chk.IsChecked -eq $true) {
            $selectedApps += $chk.Tag
        }
    }

    if ($selectedApps.Count -eq 0) {
        Show-CustomNotification "Pilih minimal satu aplikasi untuk diinstal." "!" "#f9e2af"
        return
    }

    # Lock UI & Show ProgressBar
    $BtnInstallApps.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false
    $PrgInstall.Visibility = [System.Windows.Visibility]::Visible
    $PrgInstall.IsIndeterminate = $true

    Write-GuiLog "[*] Memulai instalasi $($selectedApps.Count) aplikasi..."
    
    # Auto switch to Console Log Panel so the user sees the installation live progress!
    Switch-Panel "Log"

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

# === STEP 12: EVENT - APPLY TWEAKS ===
$BtnApplyTweaks.Add_Click({
    $tweaks = @{
        Telemetry = [bool]$ChkTelemetry.IsChecked
        Cortana   = [bool]$ChkCortana.IsChecked
        Bloatware = [bool]$ChkBloatware.IsChecked
        DarkTheme = [bool]$ChkDarkTheme.IsChecked
    }

    # Lock UI & Show ProgressBar
    $BtnInstallApps.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false
    $PrgTweaks.Visibility = [System.Windows.Visibility]::Visible
    $PrgTweaks.IsIndeterminate = $true

    Write-GuiLog "[*] Menjalankan optimasi sistem..."
    
    # Auto switch to Console Log Panel so the user sees the tweaks output live!
    Switch-Panel "Log"

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

# === STEP 13: TAMPILKAN WINDOW ===
$Window.ShowDialog() | Out-Null
