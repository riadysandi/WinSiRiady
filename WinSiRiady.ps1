# WinSiRiady Utility - Main Application Script
# Run this script as Administrator to launch the GUI.

# 1. Administrator Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    # Relaunch as Admin
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Load Assemblies for WPF GUI
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

# 3. GUI Layout Definition (XAML)
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinSiRiady Utility" Height="650" Width="850" Background="#1e1e2e" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="180"/>
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

            <!-- TAB 3: ABOUT -->
            <TabItem Header="Tentang">
                <StackPanel Margin="20">
                    <TextBlock Text="WinSiRiady Utility v1.0.0" FontSize="20" FontWeight="Bold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                    <TextBlock Text="Mengotomatiskan setup Windows Anda pasca instalasi ulang." Foreground="#cdd6f4" TextWrapping="Wrap" Margin="0,0,0,15"/>
                    
                    <TextBlock Text="Repositori GitHub:" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,5"/>
                    <TextBlock Text="https://github.com/riadysandi/WinSiRiady" Foreground="#f9e2af" Margin="0,0,0,15"/>

                    <TextBlock Text="Cara Kerja Fitur Download GitHub Release:" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,5"/>
                    <TextBlock Text="Untuk aplikasi kustom, skrip ini menanyakan API GitHub untuk mencari file .exe atau .msi rilis terbaru dari repositori target, mengunduh file tersebut ke folder TEMP, lalu mengeksekusinya secara lokal." Foreground="#a6adc8" TextWrapping="Wrap"/>
                </StackPanel>
            </TabItem>
        </TabControl>

        <!-- Log Output Console -->
        <Grid Grid.Row="2" Margin="10,0,10,10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="Console Output Log:" FontSize="12" Foreground="#a6adc8" Margin="0,0,0,5"/>
            <TextBox Grid.Row="1" x:Name="TxtLog" Background="#11111b" Foreground="#a6e3a1" FontFamily="Consolas" FontSize="12" BorderBrush="#313244" VerticalScrollBarVisibility="Auto" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap"/>
        </Grid>
    </Grid>
</Window>
"@

# 4. Load XML XAML to WPF Window Object
$reader = New-Object System.Xml.XmlNodeReader($xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# 5. Bind WPF Controls to PowerShell Variables
$AppsContainer = $Window.FindName("AppsContainer")
$BtnInstallApps = $Window.FindName("BtnInstallApps")
$BtnApplyTweaks = $Window.FindName("BtnApplyTweaks")
$TxtLog = $Window.FindName("TxtLog")

# Checkboxes for Tweaks
$ChkTelemetry = $Window.FindName("ChkTelemetry")
$ChkCortana = $Window.FindName("ChkCortana")
$ChkBloatware = $Window.FindName("ChkBloatware")
$ChkDarkTheme = $Window.FindName("ChkDarkTheme")

# Helper function to append to GUI console log
function Write-GuiLog {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $TxtLog.AppendText("[$timestamp] $Message`r`n")
    $TxtLog.ScrollToEnd()
}

Write-GuiLog "WinSiRiady Utility berhasil dimuat."
Write-GuiLog "Membaca daftar aplikasi dari apps.json..."

# 6. Load Apps dynamically from apps.json
$appsJsonPath = Join-Path $PSScriptRoot "apps.json"
if (Test-Path $appsJsonPath) {
    try {
        $apps = Get-Content -Raw -Path $appsJsonPath | ConvertFrom-Json
        $groupedApps = $apps | Group-Object Category

        # List of created CheckBoxes to scan when installing
        $Global:AppCheckBoxes = @()

        foreach ($group in $groupedApps) {
            # Category Header
            $header = New-Object System.Windows.Controls.TextBlock
            $header.Text = $group.Name
            $header.FontSize = 14
            $header.FontWeight = [System.Windows.FontWeights]::Bold
            $header.Foreground = [System.Windows.Media.BrushConverter]::ConvertFromString("#cba6f7")
            $header.Margin = "0,10,0,5"
            $AppsContainer.Children.Add($header) | Out-Null

            foreach ($app in $group.Group) {
                # Individual CheckBox for Application
                $chk = New-Object System.Windows.Controls.CheckBox
                $chk.Content = "$($app.Name) - $($app.Description)"
                $chk.Foreground = [System.Windows.Media.BrushConverter]::ConvertFromString("#cdd6f4")
                $chk.FontSize = 12
                $chk.Margin = "10,2,0,2"
                
                # Store the custom app properties as an object inside Tag
                $chk.Tag = $app
                $AppsContainer.Children.Add($chk) | Out-Null
                $Global:AppCheckBoxes += $chk
            }
        }
        Write-GuiLog "Berhasil memuat $($apps.Count) aplikasi."
    }
    catch {
        Write-GuiLog "[-] Error membaca apps.json: $_"
    }
}
else {
    Write-GuiLog "[-] File apps.json tidak ditemukan di: $appsJsonPath"
}

# 7. Job Progress Monitoring Timer Setup
$Global:Job = $null
$Global:MonitorTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:MonitorTimer.Interval = [TimeSpan]::FromMilliseconds(200)

$Global:MonitorTimer.Add_Tick({
    if ($Global:Job) {
        # Receive output from the job dynamically
        $output = Receive-Job -Job $Global:Job
        if ($output) {
            foreach ($line in $output) {
                Write-GuiLog $line
            }
        }
        
        # Check if job is finished
        if ($Global:Job.State -ne "Running") {
            $Global:MonitorTimer.Stop()
            
            # Print any leftover output
            $leftover = Receive-Job -Job $Global:Job
            if ($leftover) {
                foreach ($line in $leftover) {
                    Write-GuiLog $line
                }
            }
            
            Remove-Job -Job $Global:Job
            $Global:Job = $null
            
            # Enable Buttons
            $BtnInstallApps.IsEnabled = $true
            $BtnApplyTweaks.IsEnabled = $true
            Write-GuiLog "[+] Operasi Selesai."
        }
    }
})

# 8. Event Handler for Installing Apps
$BtnInstallApps.Add_Click({
    # Identify which apps are checked
    $selectedApps = @()
    foreach ($chk in $Global:AppCheckBoxes) {
        if ($chk.IsChecked) {
            $selectedApps += $chk.Tag
        }
    }

    if ($selectedApps.Count -eq 0) {
        Write-GuiLog "[!] Silakan pilih minimal satu aplikasi untuk diinstal."
        return
    }

    # Disable buttons during action
    $BtnInstallApps.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false

    Write-GuiLog "[*] Menjalankan instalasi aplikasi di background job..."

    # Scriptblock for the background job
    $InstallScriptBlock = {
        param($appsToInstall)
        
        foreach ($app in $appsToInstall) {
            Write-Output "Memulai instalasi: $($app.Name)..."
            
            if ($app.Type -eq "winget") {
                Write-Output "Menjalankan Winget untuk: $($app.Id)"
                # Start Winget process silently
                $process = Start-Process winget -ArgumentList "install --id $($app.Id) --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -PassThru -Wait
                if ($process.ExitCode -eq 0) {
                    Write-Output "[+] Berhasil menginstal $($app.Name) via Winget."
                } else {
                    Write-Output "[-] Gagal menginstal $($app.Name). Code: $($process.ExitCode)"
                }
            }
            elseif ($app.Type -eq "github_release") {
                Write-Output "Menghubungi API GitHub untuk repo: $($app.Repo)..."
                try {
                    # Configure TLS 1.2
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    
                    # Call Github API
                    $api = Invoke-RestMethod -Uri "https://api.github.com/repos/$($app.Repo)/releases/latest" -ErrorAction Stop
                    $asset = $api.assets | Where-Object { $_.name -like $app.AssetFilter } | Select-Object -First 1
                    
                    if ($null -eq $asset) {
                        Write-Output "[-] Aset tidak ditemukan dengan filter '$($app.AssetFilter)' pada rilis GitHub."
                        continue
                    }
                    
                    $downloadUrl = $asset.browser_download_url
                    $tempDir = [System.IO.Path]::GetTempPath()
                    $destFile = Join-Path $tempDir $asset.name
                    
                    Write-Output "Mengunduh $($asset.name) dari GitHub Releases..."
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $destFile -ErrorAction Stop
                    
                    Write-Output "Menjalankan installer: $($asset.name)..."
                    $installProc = Start-Process -FilePath $destFile -Wait -PassThru
                    Write-Output "[+] File installer $($asset.name) telah dieksekusi."
                    
                    # Try to cleanup installer file
                    Remove-Item $destFile -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Output "[-] Gagal memproses instalasi rilis GitHub: $_"
                }
            }
        }
    }

    # Start Background Job
    $Global:Job = Start-Job -ScriptBlock $InstallScriptBlock -ArgumentList @(,$selectedApps)
    $Global:MonitorTimer.Start()
})

# 9. Event Handler for System Optimization (Tweaks)
$BtnApplyTweaks.Add_Click({
    $TweaksToRun = @{
        Telemetry = $ChkTelemetry.IsChecked
        Cortana = $ChkCortana.IsChecked
        Bloatware = $ChkBloatware.IsChecked
        DarkTheme = $ChkDarkTheme.IsChecked
    }

    $BtnInstallApps.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false

    Write-GuiLog "[*] Menjalankan optimasi sistem di background job..."

    # Scriptblock for the tweaks job
    $TweaksScriptBlock = {
        param($tweaks, $rootPath)
        
        # Import Tweaks module functions
        $tweaksModulePath = Join-Path $rootPath "tweaks.ps1"
        if (Test-Path $tweaksModulePath) {
            . $tweaksModulePath
        } else {
            Write-Output "[-] Gagal menemukan tweaks.ps1 di $rootPath"
            return
        }

        if ($tweaks.Telemetry) {
            Optimize-Telemetry
        }
        if ($tweaks.Cortana) {
            Optimize-Cortana
        }
        if ($tweaks.Bloatware) {
            Remove-Bloatware
        }
        if ($tweaks.DarkTheme) {
            Enable-DarkTheme
        }
    }

    # Start Background Job and pass directory root for dot-sourcing
    $Global:Job = Start-Job -ScriptBlock $TweaksScriptBlock -ArgumentList $TweaksToRun, $PSScriptRoot
    $Global:MonitorTimer.Start()
})

# 10. Display Window Dialog
$Window.ShowDialog() | Out-Null
