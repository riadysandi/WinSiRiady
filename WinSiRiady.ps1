# === WinSiRiady Utility v2.0 ===
# Dibuat oleh: Sandi Riady
# Jalankan sebagai Administrator. Mendukung eksekusi lokal maupun via: irm URL | iex

# === STEP 1: ADMINISTRATOR CHECK ===
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm 'https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1' | iex`"" -Verb RunAs
    exit
}

# === STEP 2: RESOLVE ROOT PATH ===
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$LocalRoot = if ($PSScriptRoot -and $PSScriptRoot -ne "") {
    $PSScriptRoot
} else {
    $tempRoot = Join-Path $env:TEMP "WinSiRiady"
    if (-not (Test-Path $tempRoot)) { New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null }
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

# Pastikan folder C:\WinSiRiady ada
$WinSiRiadyDir = "C:\WinSiRiady"
if (-not (Test-Path $WinSiRiadyDir)) { New-Item -ItemType Directory -Path $WinSiRiadyDir -Force | Out-Null }

# === STEP 3: LOAD WPF ASSEMBLIES ===
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

# === STEP 4: DEFINISI GUI XAML ===
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinSiRiady Utility" Height="680" Width="1080" Background="#1e1e2e"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- SIDEBAR -->
        <Border Grid.Column="0" Background="#181825" BorderBrush="#313244" BorderThickness="0,0,1,0">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="100"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="75"/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row="0" VerticalAlignment="Center" Margin="20,0,0,0">
                    <TextBlock Text="WinSiRiady" FontSize="24" FontWeight="Bold" Foreground="#89b4fa"/>
                    <TextBlock Text="Windows Utility v2.0" FontSize="11" Foreground="#a6adc8" Margin="0,3,0,0"/>
                </StackPanel>
                <StackPanel Grid.Row="1" Margin="10,0,10,0">
                    <Button x:Name="BtnNavApps" Content="Instal Aplikasi" Height="40" Margin="0,4,0,4" Background="#313244" Foreground="#cdd6f4" FontWeight="SemiBold" BorderThickness="0" FontSize="13"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <Button x:Name="BtnNavDriver" Content="Driver" Height="40" Margin="0,4,0,4" Background="Transparent" Foreground="#a6adc8" FontWeight="SemiBold" BorderThickness="0" FontSize="13"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <Button x:Name="BtnNavGlpi" Content="GLPI Agent" Height="40" Margin="0,4,0,4" Background="Transparent" Foreground="#a6adc8" FontWeight="SemiBold" BorderThickness="0" FontSize="13"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <Button x:Name="BtnNavTweaks" Content="Optimasi Sistem" Height="40" Margin="0,4,0,4" Background="Transparent" Foreground="#a6adc8" FontWeight="SemiBold" BorderThickness="0" FontSize="13"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <Button x:Name="BtnNavLog" Content="Console Log" Height="40" Margin="0,4,0,4" Background="Transparent" Foreground="#a6adc8" FontWeight="SemiBold" BorderThickness="0" FontSize="13"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <Button x:Name="BtnNavAbout" Content="Tentang" Height="40" Margin="0,4,0,4" Background="Transparent" Foreground="#a6adc8" FontWeight="SemiBold" BorderThickness="0" FontSize="13"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                </StackPanel>
                <StackPanel Grid.Row="2" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <TextBlock Text="v2.0.0 - Stable | By Sandi Riady" FontSize="10" Foreground="#585b70" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="TxtStatusDetect" Text="Mendeteksi status instalasi..." FontSize="10" Foreground="#585b70" HorizontalAlignment="Center" Margin="0,3,0,0" TextWrapping="Wrap" TextAlignment="Center"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- CONTENT AREA -->
        <Grid Grid.Column="1" Margin="25">

            <!-- PAGE 1: INSTAL APLIKASI -->
            <Grid x:Name="PanelApps" Visibility="Visible">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <!-- Title + Backup buttons -->
                <DockPanel Grid.Row="0" Margin="0,0,0,12">
                    <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
                        <Button x:Name="BtnLoadSelection" Content="Muat Pilihan" Height="30" Margin="0,0,8,0" Background="#313244" Foreground="#cdd6f4" FontSize="12" BorderThickness="0" Padding="12,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                        <Button x:Name="BtnSaveSelection" Content="Simpan Pilihan" Height="30" Background="#313244" Foreground="#cdd6f4" FontSize="12" BorderThickness="0" Padding="12,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    </StackPanel>
                    <TextBlock Text="Instal Aplikasi" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" VerticalAlignment="Center"/>
                </DockPanel>
                <!-- Search box -->
                <Border Grid.Row="1" Background="#181825" CornerRadius="8" BorderBrush="#313244" BorderThickness="1" Margin="0,0,0,8">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="   Cari: " Foreground="#585b70" VerticalAlignment="Center" FontSize="12"/>
                         <TextBox Grid.Column="1" x:Name="TxtSearch" Background="#181825" Foreground="#cdd6f4" CaretBrush="#cdd6f4" BorderThickness="0" FontSize="13" Padding="4,8" VerticalAlignment="Center"/>
                    </Grid>
                </Border>
                <!-- Target Folder -->
                <Grid Grid.Row="2" Margin="0,0,0,10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="Folder Unduhan: " Foreground="#a6adc8" FontSize="12" VerticalAlignment="Center" Margin="0,0,6,0"/>
                    <Border Grid.Column="1" Background="#181825" CornerRadius="6" BorderBrush="#313244" BorderThickness="1">
                         <TextBox x:Name="TxtTargetFolder" Text="C:\WinSiRiady" Background="#181825" Foreground="#cdd6f4" CaretBrush="#cdd6f4" BorderThickness="0" FontSize="12" Padding="8,6"/>
                    </Border>
                    <Button Grid.Column="2" x:Name="BtnBrowse" Content="Browse..." Height="30" Margin="8,0,0,0" Background="#313244" Foreground="#cdd6f4" FontSize="12" BorderThickness="0" Padding="10,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                </Grid>
                <!-- App List -->
                <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto" Margin="0,0,0,8">
                    <StackPanel x:Name="AppsContainer"/>
                </ScrollViewer>
                <!-- Progress Label -->
                <TextBlock Grid.Row="4" x:Name="TxtProgressLabel" Text="" Foreground="#a6adc8" FontSize="12" Margin="0,0,0,5" Visibility="Collapsed"/>
                <!-- Progress Bar -->
                <ProgressBar Grid.Row="5" x:Name="PrgInstall" Height="8" Minimum="0" Maximum="100" Value="0" Background="#313244" Foreground="#89b4fa" BorderThickness="0" Visibility="Collapsed" Margin="0,0,0,10"/>
                <!-- Install Button -->
                <Button Grid.Row="6" x:Name="BtnInstallApps" Content="Instal Aplikasi Terpilih" Height="45" Background="#89b4fa" Foreground="#11111b" FontWeight="Bold" BorderThickness="0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
            </Grid>

            <!-- PAGE 2: DRIVER -->
            <Grid x:Name="PanelDriver" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="Unduh Driver" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,6"/>
                <TextBlock Grid.Row="1" Text="Tambahkan driver ke apps.json dengan Category: Drivers" Foreground="#585b70" FontSize="12" Margin="0,0,0,12"/>
                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Margin="0,0,0,8">
                    <StackPanel x:Name="DriverContainer"/>
                </ScrollViewer>
                <TextBlock Grid.Row="3" x:Name="TxtDriverProgressLabel" Text="" Foreground="#a6adc8" FontSize="12" Margin="0,0,0,5" Visibility="Collapsed"/>
                <ProgressBar Grid.Row="4" x:Name="PrgDriver" Height="8" Minimum="0" Maximum="100" Value="0" Background="#313244" Foreground="#cba6f7" BorderThickness="0" Visibility="Collapsed" Margin="0,0,0,10"/>
                <Button Grid.Row="5" x:Name="BtnDownloadDriver" Content="Unduh Driver Terpilih" Height="45" Background="#cba6f7" Foreground="#11111b" FontWeight="Bold" BorderThickness="0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
            </Grid>

            <!-- PAGE 3: TWEAKS -->
            <Grid x:Name="PanelTweaks" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
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
                <TextBlock Grid.Row="2" x:Name="TxtTweaksProgressLabel" Text="" Foreground="#a6adc8" FontSize="12" Margin="0,0,0,5" Visibility="Collapsed"/>
                <ProgressBar Grid.Row="3" x:Name="PrgTweaks" Height="8" Minimum="0" Maximum="100" Value="0" Background="#313244" Foreground="#a6e3a1" BorderThickness="0" Visibility="Collapsed" Margin="0,0,0,10"/>
                <Button Grid.Row="4" x:Name="BtnApplyTweaks" Content="Jalankan Optimasi Terpilih" Height="45" Background="#a6e3a1" Foreground="#11111b" FontWeight="Bold" BorderThickness="0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
            </Grid>

            <!-- PAGE 4: CONSOLE LOG -->
            <Grid x:Name="PanelLog" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <DockPanel Grid.Row="0" Margin="0,0,0,8">
                    <Button x:Name="BtnOpenLogFile" DockPanel.Dock="Right" Content="Buka File Log" Height="30" Background="#313244" Foreground="#cdd6f4" FontSize="12" BorderThickness="0" Padding="12,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <TextBlock Text="Console Output Log" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" VerticalAlignment="Center"/>
                </DockPanel>
                <TextBlock Grid.Row="1" Text="Log tersimpan di: C:\WinSiRiady\install_history.log" Foreground="#585b70" FontSize="11" Margin="0,0,0,10"/>
                <TextBox Grid.Row="2" x:Name="TxtLog" Background="#11111b" Foreground="#a6e3a1" FontFamily="Consolas" FontSize="12" BorderBrush="#313244" BorderThickness="1" VerticalScrollBarVisibility="Auto" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap" Padding="10"><TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></TextBox.Resources></TextBox>
            </Grid>

            <!-- PAGE 5: GLPI AGENT -->
            <Grid x:Name="PanelGlpi" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/> <!-- Title -->
                    <RowDefinition Height="Auto"/> <!-- Status Banner Card -->
                    <RowDefinition Height="Auto"/> <!-- 2 Columns Grid (Install & Update TAG) -->
                    <RowDefinition Height="*"/>    <!-- Center Deploy Button Area -->
                    <RowDefinition Height="Auto"/> <!-- Progress Label -->
                    <RowDefinition Height="Auto"/> <!-- Progress Bar -->
                </Grid.RowDefinitions>
                
                <!-- Title -->
                <TextBlock Grid.Row="0" Text="GLPI Agent Manager" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,15"/>
                
                <!-- Status Banner Card -->
                <Border Grid.Row="1" x:Name="BorderGlpiStatusBanner" CornerRadius="8" Padding="15" Margin="0,0,0,20" BorderThickness="1">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock x:Name="TxtGlpiStatusIcon" Grid.Column="0" Text="" FontSize="24" FontWeight="Bold" Margin="0,0,15,0" VerticalAlignment="Center"/>
                        <StackPanel Grid.Column="1" VerticalAlignment="Center">
                            <TextBlock x:Name="TxtGlpiStatusTitle" Text="Memeriksa Status..." FontSize="14" FontWeight="Bold" Foreground="#cdd6f4"/>
                            <TextBlock x:Name="TxtGlpiStatusDesc" Text="Harap tunggu sebentar." FontSize="11" Foreground="#a6adc8" Margin="0,2,0,0"/>
                        </StackPanel>
                    </Grid>
                </Border>
                
                <!-- 2 Columns Grid (Install & Update TAG) -->
                <Grid Grid.Row="2" Margin="0,0,0,20">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="20"/> <!-- Gap -->
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- BOX 1: INSTALASI (Kiri) -->
                    <Border Grid.Column="0" Background="#181825" CornerRadius="10" Padding="20" BorderBrush="#313244" BorderThickness="1" VerticalAlignment="Top">
                        <StackPanel>
                            <TextBlock Text="Instal Agent Baru" FontSize="15" FontWeight="Bold" Foreground="#89b4fa" Margin="0,0,0,5"/>
                            <TextBlock Text="Pasang agent baru jika belum terinstal di sistem." FontSize="11" Foreground="#585b70" Margin="0,0,0,15"/>
                            
                            <TextBlock Text="Masukkan Nomor Asset (TAG):" Foreground="#a6adc8" FontSize="12" Margin="0,0,0,6"/>
                            <Border Background="#11111b" CornerRadius="6" BorderBrush="#313244" BorderThickness="1" Margin="0,0,0,18">
                                 <TextBox x:Name="TxtGlpiInstallTag" Background="#11111b" Foreground="#cdd6f4" CaretBrush="#cdd6f4" BorderThickness="0" FontSize="13" Padding="10,8"/>
                            </Border>
                            
                            <Button x:Name="BtnGlpiInstall" Content="Mulai Instalasi" Height="38" Background="#89b4fa" Foreground="#11111b" FontWeight="Bold" BorderThickness="0">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </StackPanel>
                    </Border>
                    
                    <!-- BOX 2: KELOLA TAG (Ralat TAG) (Kanan) -->
                    <Border Grid.Column="2" x:Name="BorderGlpiManage" Background="#181825" CornerRadius="10" Padding="20" BorderBrush="#313244" BorderThickness="1" VerticalAlignment="Top">
                        <StackPanel>
                            <TextBlock Text="Ubah Asset TAG" FontSize="15" FontWeight="Bold" Foreground="#a6e3a1" Margin="0,0,0,5"/>
                            <TextBlock Text="Koreksi Asset TAG jika terjadi salah input sebelumnya." FontSize="11" Foreground="#585b70" Margin="0,0,0,15"/>
                            
                            <TextBlock Text="Ubah Nomor Asset (TAG):" Foreground="#a6adc8" FontSize="12" Margin="0,0,0,6"/>
                            <Grid Margin="0,0,0,18">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.Column="0" Background="#11111b" CornerRadius="6" BorderBrush="#313244" BorderThickness="1" Margin="0,0,8,0">
                                     <TextBox x:Name="TxtGlpiCurrentTag" Background="#11111b" Foreground="#cdd6f4" CaretBrush="#cdd6f4" BorderThickness="0" FontSize="13" Padding="10,8"/>
                                </Border>
                                <Button Grid.Column="1" x:Name="BtnGlpiUpdateTag" Content="Update TAG" Height="36" Width="95" Background="#a6e3a1" Foreground="#11111b" FontWeight="Bold" BorderThickness="0">
                                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                                </Button>
                            </Grid>
                            
                            <Separator Background="#313244" Margin="0,5,0,15"/>
                            
                            <TextBlock Text="Hapus Agent dari Sistem:" Foreground="#a6adc8" FontSize="12" Margin="0,0,0,6"/>
                            <Button x:Name="BtnGlpiUninstall" Content="Uninstall GLPI Agent" Height="36" Background="#f38ba8" Foreground="#11111b" FontWeight="Bold" BorderThickness="0">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </StackPanel>
                    </Border>
                </Grid>
                
                <!-- Deploy Sekarang (Bawah Tengah) -->
                <StackPanel Grid.Row="3" VerticalAlignment="Top" HorizontalAlignment="Center" Width="400" Margin="0,10,0,0">
                    <TextBlock Text="Kirim Data Inventory (Deploy ke Server):" Foreground="#a6adc8" FontSize="12" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                    <Button x:Name="BtnGlpiDeploy" Content="Deploy Sekarang (Force Inventory)" Height="42" Background="#f9e2af" Foreground="#11111b" FontWeight="Bold" BorderThickness="0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                </StackPanel>

                <!-- Progress Label -->
                <TextBlock Grid.Row="4" x:Name="TxtGlpiProgressLabel" Text="" Foreground="#a6adc8" FontSize="12" Margin="0,15,0,5" Visibility="Collapsed"/>
                <!-- Progress Bar -->
                <ProgressBar Grid.Row="5" x:Name="PrgGlpi" Height="8" Minimum="0" Maximum="100" Value="0" Background="#313244" Foreground="#89b4fa" BorderThickness="0" Visibility="Collapsed" Margin="0,0,0,10"/>
            </Grid>

            <!-- PAGE 6: TENTANG -->
            <Grid x:Name="PanelAbout" Visibility="Collapsed">
                <StackPanel Margin="5">
                    <TextBlock Text="Tentang WinSiRiady Utility" FontSize="20" FontWeight="Bold" Foreground="#cdd6f4" Margin="0,0,0,15"/>
                    <TextBlock Text="Dibuat oleh: Sandi Riady" FontSize="14" FontWeight="SemiBold" Foreground="#a6e3a1" Margin="0,0,0,10"/>
                    <TextBlock Text="Aplikasi ini dikembangkan untuk mengotomatiskan instalasi perangkat lunak dan konfigurasi Windows pasca instalasi ulang." Foreground="#a6adc8" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,20"/>
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

# === STEP 5: LOAD XAML ===
$reader = New-Object System.Xml.XmlNodeReader($xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# === STEP 6: BIND CONTROLS ===
$BtnNavApps          = $Window.FindName("BtnNavApps")
$BtnNavDriver        = $Window.FindName("BtnNavDriver")
$BtnNavTweaks        = $Window.FindName("BtnNavTweaks")
$BtnNavLog           = $Window.FindName("BtnNavLog")
$BtnNavAbout         = $Window.FindName("BtnNavAbout")
$PanelApps           = $Window.FindName("PanelApps")
$PanelDriver         = $Window.FindName("PanelDriver")
$PanelTweaks         = $Window.FindName("PanelTweaks")
$PanelLog            = $Window.FindName("PanelLog")
$PanelAbout          = $Window.FindName("PanelAbout")
$AppsContainer       = $Window.FindName("AppsContainer")
$DriverContainer     = $Window.FindName("DriverContainer")
$TxtSearch           = $Window.FindName("TxtSearch")
$TxtTargetFolder     = $Window.FindName("TxtTargetFolder")
$BtnBrowse           = $Window.FindName("BtnBrowse")
$BtnSaveSelection    = $Window.FindName("BtnSaveSelection")
$BtnLoadSelection    = $Window.FindName("BtnLoadSelection")
$BtnInstallApps      = $Window.FindName("BtnInstallApps")
$BtnDownloadDriver   = $Window.FindName("BtnDownloadDriver")
$BtnApplyTweaks      = $Window.FindName("BtnApplyTweaks")
$BtnOpenLogFile      = $Window.FindName("BtnOpenLogFile")
$TxtLog              = $Window.FindName("TxtLog")
$TxtProgressLabel    = $Window.FindName("TxtProgressLabel")
$TxtDriverProgressLabel = $Window.FindName("TxtDriverProgressLabel")
$TxtTweaksProgressLabel = $Window.FindName("TxtTweaksProgressLabel")
$PrgInstall          = $Window.FindName("PrgInstall")
$PrgDriver           = $Window.FindName("PrgDriver")
$PrgTweaks           = $Window.FindName("PrgTweaks")
$TxtStatusDetect     = $Window.FindName("TxtStatusDetect")
$ChkTelemetry        = $Window.FindName("ChkTelemetry")
$ChkCortana          = $Window.FindName("ChkCortana")
$ChkBloatware        = $Window.FindName("ChkBloatware")
$ChkDarkTheme        = $Window.FindName("ChkDarkTheme")

$BtnNavGlpi          = $Window.FindName("BtnNavGlpi")
$PanelGlpi           = $Window.FindName("PanelGlpi")
$BorderGlpiStatusBanner = $Window.FindName("BorderGlpiStatusBanner")
$TxtGlpiStatusIcon   = $Window.FindName("TxtGlpiStatusIcon")
$TxtGlpiStatusTitle  = $Window.FindName("TxtGlpiStatusTitle")
$TxtGlpiStatusDesc   = $Window.FindName("TxtGlpiStatusDesc")
$TxtGlpiInstallTag   = $Window.FindName("TxtGlpiInstallTag")
$BtnGlpiInstall      = $Window.FindName("BtnGlpiInstall")
$BorderGlpiManage    = $Window.FindName("BorderGlpiManage")
$TxtGlpiCurrentTag   = $Window.FindName("TxtGlpiCurrentTag")
$BtnGlpiUpdateTag    = $Window.FindName("BtnGlpiUpdateTag")
$BtnGlpiDeploy       = $Window.FindName("BtnGlpiDeploy")
$BtnGlpiUninstall    = $Window.FindName("BtnGlpiUninstall")
$TxtGlpiProgressLabel = $Window.FindName("TxtGlpiProgressLabel")
$PrgGlpi             = $Window.FindName("PrgGlpi")

# === STEP 7: HELPER FUNCTIONS ===
function Write-GuiLog {
    param([string]$Message)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $TxtLog.AppendText("[$ts] $Message`r`n")
    $TxtLog.ScrollToEnd()
}

function New-Brush {
    param([string]$hex)
    $color = [System.Windows.Media.ColorConverter]::ConvertFromString($hex)
    $brush = New-Object System.Windows.Media.SolidColorBrush
    $brush.Color = $color
    return $brush
}

function Write-LogFile {
    param([string]$AppName, [string]$Status)
    $logPath = "C:\WinSiRiady\install_history.log"
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    try { Add-Content -Path $logPath -Value "[$ts] $AppName -- $Status" -Encoding UTF8 } catch {}
}

function Show-CustomNotification {
    param([string]$message, [string]$type = "success")

    $icon = "&#x2713;"
    $iconColor = "#a6e3a1"
    if ($type -eq "warning") { $icon = "!"; $iconColor = "#f9e2af" }

    [xml]$notifXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="WinSiRiady" Height="160" Width="380" Background="Transparent"
            WindowStartupLocation="CenterOwner" ResizeMode="NoResize" WindowStyle="None" AllowsTransparency="True">
        <Border Background="#1e1e2e" BorderBrush="#313244" BorderThickness="2" CornerRadius="12">
            <Grid Margin="15">
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <TextBlock Text="$icon" FontSize="32" FontWeight="Bold" Foreground="$iconColor" Margin="0,0,15,0" VerticalAlignment="Center"/>
                    <TextBlock Text="$message" FontSize="13" FontWeight="SemiBold" Foreground="#cdd6f4" TextWrapping="Wrap" VerticalAlignment="Center" Width="255"/>
                </StackPanel>
                <Button Grid.Row="1" x:Name="BtnCloseNotif" Content="Selesai" Height="32" Width="100" Background="#89b4fa" Foreground="#11111b" FontWeight="Bold" BorderThickness="0" HorizontalAlignment="Center">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                </Button>
            </Grid>
        </Border>
    </Window>
"@
    $nReader = New-Object System.Xml.XmlNodeReader($notifXaml)
    $nWin = [Windows.Markup.XamlReader]::Load($nReader)
    $nWin.Owner = $Window
    $nWin.FindName("BtnCloseNotif").Add_Click({ $nWin.Close() })
    $nWin.Add_MouseLeftButtonDown({ $nWin.DragMove() })
    $nWin.ShowDialog() | Out-Null
}
function Update-GlpiStatus {
    $ServiceName = "glpi-agent"
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    $glpiInstalled = $svc -ne $null
    
    $regPath = "HKLM:\SOFTWARE\GLPI-Agent"
    if (-not (Test-Path $regPath)) {
        $regPath = "HKLM:\SOFTWARE\Wow6432Node\GLPI-Agent"
    }
    
    $currentTag = ""
    if (Test-Path $regPath) {
        $currentTag = (Get-ItemProperty -Path $regPath -Name "tag" -ErrorAction SilentlyContinue).tag
    }

    if ($glpiInstalled -or (Test-Path "C:\Program Files\GLPI-Agent\glpi-agent.bat")) {
        $BorderGlpiStatusBanner.Background = New-Brush "#1a3a2a" # Dark Green
        $BorderGlpiStatusBanner.BorderBrush = New-Brush "#a6e3a1" # Light Green
        $TxtGlpiStatusIcon.Text = [char]0x2713
        $TxtGlpiStatusIcon.Foreground = New-Brush "#a6e3a1"
        $TxtGlpiStatusTitle.Text = "GLPI Agent Aktif & Terinstal"
        $TxtGlpiStatusTitle.Foreground = New-Brush "#a6e3a1"
        $TxtGlpiStatusDesc.Text = if ($currentTag) { "Terhubung dengan Asset TAG: $currentTag. Service berjalan normal." } else { "Terinstal tetapi TAG belum diset. Silakan isi TAG di panel kanan." }
        
        # Disable installation
        $TxtGlpiInstallTag.IsEnabled = $false
        $BtnGlpiInstall.IsEnabled = $false
        
        # Enable management
        $BorderGlpiManage.IsEnabled = $true
        $TxtGlpiCurrentTag.IsEnabled = $true
        $BtnGlpiUpdateTag.IsEnabled = $true
        $BtnGlpiDeploy.IsEnabled = $true
        $BtnGlpiUninstall.IsEnabled = $true
        
        # Set current tag text
        $TxtGlpiCurrentTag.Text = $currentTag
    } else {
        $BorderGlpiStatusBanner.Background = New-Brush "#3e2428" # Dark Red
        $BorderGlpiStatusBanner.BorderBrush = New-Brush "#f38ba8" # Light Red
        $TxtGlpiStatusIcon.Text = "!"
        $TxtGlpiStatusIcon.Foreground = New-Brush "#f38ba8"
        $TxtGlpiStatusTitle.Text = "GLPI Agent Belum Terpasang"
        $TxtGlpiStatusTitle.Foreground = New-Brush "#f38ba8"
        $TxtGlpiStatusDesc.Text = "Masukkan nomor Asset TAG di panel kiri untuk memulai proses instalasi agent baru."
        
        # Enable installation
        $TxtGlpiInstallTag.IsEnabled = $true
        $BtnGlpiInstall.IsEnabled = $true
        
        # Disable management
        $BorderGlpiManage.IsEnabled = $false
        $TxtGlpiCurrentTag.IsEnabled = $false
        $BtnGlpiUpdateTag.IsEnabled = $false
        $BtnGlpiDeploy.IsEnabled = $false
        $BtnGlpiUninstall.IsEnabled = $false
        $TxtGlpiCurrentTag.Text = ""
    }
}


Write-GuiLog "WinSiRiady Utility v2.0 berhasil dimuat."
Write-GuiLog "Root directory: $LocalRoot"

# === STEP 8: NAVIGATION ===
$Panels     = @{ Apps = $PanelApps; Driver = $PanelDriver; Glpi = $PanelGlpi; Tweaks = $PanelTweaks; Log = $PanelLog; About = $PanelAbout }
$NavButtons = @{ Apps = $BtnNavApps; Driver = $BtnNavDriver; Glpi = $BtnNavGlpi; Tweaks = $BtnNavTweaks; Log = $BtnNavLog; About = $BtnNavAbout }

function Switch-Panel {
    param([string]$target)
    foreach ($key in $Panels.Keys) {
        $Panels[$key].Visibility  = [System.Windows.Visibility]::Collapsed
        $NavButtons[$key].Background = [System.Windows.Media.Brushes]::Transparent
        $NavButtons[$key].Foreground = New-Brush "#a6adc8"
    }
    $Panels[$target].Visibility  = [System.Windows.Visibility]::Visible
    $NavButtons[$target].Background = New-Brush "#313244"
    $NavButtons[$target].Foreground = New-Brush "#cdd6f4"
}

$BtnNavApps.Add_Click({   Switch-Panel "Apps" })
$BtnNavDriver.Add_Click({ Switch-Panel "Driver" })
$BtnNavGlpi.Add_Click({   Switch-Panel "Glpi" })
$BtnNavTweaks.Add_Click({ Switch-Panel "Tweaks" })
$BtnNavLog.Add_Click({    Switch-Panel "Log" })
$BtnNavAbout.Add_Click({  Switch-Panel "About" })

# === STEP 9: LOAD APPS DARI apps.json ===
$Global:AppCheckBoxes    = @()   # Apps biasa
$Global:DriverCheckBoxes = @()   # Driver apps
$Global:CategoryGroups   = @{}   # Untuk search & select-all

$appsJsonPath = Join-Path $LocalRoot "apps.json"
Write-GuiLog "Memuat daftar aplikasi dari: $appsJsonPath"

function Build-AppGrid {
    param($group, $container, $checkboxList)

    # Header row
    $headerPanel = New-Object System.Windows.Controls.TextBlock
    $headerPanel.Text = "- $($group.Name)"
    $headerPanel.FontSize = 13
    $headerPanel.FontWeight = [System.Windows.FontWeights]::Bold
    $headerPanel.Foreground = New-Brush "#89b4fa"
    $headerPanel.Margin = New-Object System.Windows.Thickness(0, 8, 0, 3)
    $container.Children.Add($headerPanel) | Out-Null

    # Grid 3 kolom
    $grid = New-Object System.Windows.Controls.Grid
    for ($c = 0; $c -lt 3; $c++) {
        $colDef = New-Object System.Windows.Controls.ColumnDefinition
        $colDef.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $grid.ColumnDefinitions.Add($colDef)
    }

    $appList = @($group.Group)
    $rowCount = [Math]::Ceiling($appList.Count / 3)
    for ($r = 0; $r -lt $rowCount; $r++) {
        $rowDef = New-Object System.Windows.Controls.RowDefinition
        $rowDef.Height = [System.Windows.GridLength]::Auto
        $grid.RowDefinitions.Add($rowDef)
    }

    $catBoxes = @()
    for ($i = 0; $i -lt $appList.Count; $i++) {
        $app = $appList[$i]
        $row = [Math]::Floor($i / 3)
        $col = $i % 3

        $chk = New-Object System.Windows.Controls.CheckBox
        $chk.Content = $app.Name
        $chk.Foreground = New-Brush "#cdd6f4"
        $chk.FontSize = 12
        $chk.Margin = New-Object System.Windows.Thickness(4, 1, 4, 1)
        $chk.Tag = $app
        [System.Windows.Controls.Grid]::SetRow($chk, $row)
        [System.Windows.Controls.Grid]::SetColumn($chk, $col)
        $grid.Children.Add($chk) | Out-Null
        $checkboxList += $chk
        $catBoxes += $chk
    }

    $container.Children.Add($grid) | Out-Null



    # Store in global for search filter
    $Global:CategoryGroups[$group.Name] = @{
        HeaderPanel = $headerPanel
        Grid        = $grid
        CheckBoxes  = $catBoxes
    }

    return $checkboxList
}

if (Test-Path $appsJsonPath) {
    try {
        $apps = Get-Content -Raw -Path $appsJsonPath -Encoding UTF8 | ConvertFrom-Json
        $groupedApps = $apps | Group-Object -Property Category

        $driverGroups = @($groupedApps | Where-Object { $_.Name -like "*Driver*" })
        $normalGroups = @($groupedApps | Where-Object { $_.Name -notlike "*Driver*" })

        foreach ($group in $normalGroups) {
            $Global:AppCheckBoxes = Build-AppGrid -group $group -container $AppsContainer -checkboxList $Global:AppCheckBoxes
        }

        if ($driverGroups.Count -eq 0) {
            $hint = New-Object System.Windows.Controls.TextBlock
            $hint.Text = "Belum ada driver. Tambahkan ke apps.json dengan Category: Drivers"
            $hint.Foreground = New-Brush "#585b70"
            $hint.FontSize = 13
            $hint.Margin = New-Object System.Windows.Thickness(0, 20, 0, 0)
            $DriverContainer.Children.Add($hint) | Out-Null
        } else {
            foreach ($group in $driverGroups) {
                $Global:DriverCheckBoxes = Build-AppGrid -group $group -container $DriverContainer -checkboxList $Global:DriverCheckBoxes
                $Global:AppCheckBoxes += $Global:DriverCheckBoxes
            }
        }

        Write-GuiLog "Berhasil memuat $($apps.Count) aplikasi."
    } catch {
        Write-GuiLog "[-] Error membaca apps.json: $_"
    }
} else {
    Write-GuiLog "[-] File apps.json tidak ditemukan."
}

# === STEP 10: SEARCH FILTER ===
$TxtSearch.Add_TextChanged({
    $query = $TxtSearch.Text.Trim().ToLower()
    foreach ($key in $Global:CategoryGroups.Keys) {
        $grp = $Global:CategoryGroups[$key]
        $hasVisible = $false
        foreach ($chk in $grp.CheckBoxes) {
            $visible = ($query -eq "") -or ($chk.Tag.Name.ToLower().Contains($query))
            $chk.Visibility = if ($visible) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
            if ($visible) { $hasVisible = $true }
        }
        $vis = if ($hasVisible -or $query -eq "") { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        $grp.HeaderPanel.Visibility = $vis
        $grp.Grid.Visibility = $vis
    }
})

# === STEP 11: BACKUP & RESTORE PILIHAN ===
$BtnSaveSelection.Add_Click({
    $selIds = $Global:AppCheckBoxes | Where-Object { $_.IsChecked -eq $true } | ForEach-Object { $_.Tag.Id }
    if (-not $selIds) {
        Show-CustomNotification "Pilih minimal satu aplikasi untuk disimpan." "warning"
        return
    }
    $selIds | ConvertTo-Json | Set-Content "$WinSiRiadyDir\my_selection.json" -Encoding UTF8
    Show-CustomNotification "Pilihan berhasil disimpan ke C:\WinSiRiady\my_selection.json" "success"
})

$BtnLoadSelection.Add_Click({
    $selPath = "$WinSiRiadyDir\my_selection.json"
    if (-not (Test-Path $selPath)) {
        Show-CustomNotification "File pilihan tidak ditemukan. Simpan pilihan terlebih dahulu." "warning"
        return
    }
    $ids = Get-Content $selPath -Encoding UTF8 | ConvertFrom-Json
    foreach ($chk in $Global:AppCheckBoxes) {
        if ($chk.IsEnabled -and $chk.Tag.Id) {
            $chk.IsChecked = ($ids -contains $chk.Tag.Id)
        }
    }
})

# === STEP 12: BROWSE FOLDER ===
$BtnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Pilih folder tujuan unduhan"
    $dialog.SelectedPath = $TxtTargetFolder.Text
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $TxtTargetFolder.Text = $dialog.SelectedPath
    }
})

# === STEP 13: OPEN LOG FILE ===
$BtnOpenLogFile.Add_Click({
    $logPath = "$WinSiRiadyDir\install_history.log"
    if (Test-Path $logPath) {
        Start-Process notepad $logPath
    } else {
        Show-CustomNotification "File log belum ada. Jalankan instalasi terlebih dahulu." "warning"
    }
})

# === STEP 14: STATUS DETECTION (winget list di background) ===
$Global:StatusJob = Start-Job -ScriptBlock {
    try { $out = & winget list 2>$null | Out-String; Write-Output $out }
    catch { Write-Output "" }
}

$Global:StatusTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:StatusTimer.Interval = [TimeSpan]::FromMilliseconds(500)
$Global:StatusTimer.Add_Tick({
    if ($Global:StatusJob -and $Global:StatusJob.State -ne "Running") {
        $Global:StatusTimer.Stop()
        $rawOutput = Receive-Job -Job $Global:StatusJob
        Remove-Job -Job $Global:StatusJob -Force -ErrorAction SilentlyContinue
        $Global:StatusJob = $null

        $installedCount = 0
        foreach ($chk in $Global:AppCheckBoxes) {
            $appId = $chk.Tag.Id
            if ($appId -and $rawOutput -match [regex]::Escape($appId)) {
                $chk.IsEnabled = $false
                $chk.Foreground = New-Brush "#4a5568"
                $chk.Content = "$($chk.Content.ToString()) [Installed]"
                $installedCount++
            }
        }
        $TxtStatusDetect.Text = "Status terdeteksi. $installedCount app sudah terinstal."
    }
})
$Global:StatusTimer.Start()

# === STEP 15: MONITOR TIMER UNTUK BACKGROUND JOB ===
$Global:Job          = $null
$Global:ActivePrgBar = $null
$Global:ActiveLabel  = $null

$Global:MonitorTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:MonitorTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$Global:MonitorTimer.Add_Tick({
    if ($null -ne $Global:Job) {
        $output = Receive-Job -Job $Global:Job
        foreach ($line in $output) {
            if ($line -match '^\[PROG\](\d+):(\d+):(.+)$') {
                $cur = [int]$matches[1]; $tot = [int]$matches[2]; $appName = $matches[3]
                if ($Global:ActivePrgBar) {
                    $Global:ActivePrgBar.Value = [Math]::Round(($cur - 1) / $tot * 100)
                }
                if ($Global:ActiveLabel) {
                    $Global:ActiveLabel.Text = "Memproses: $appName... ($cur dari $tot)"
                    $Global:ActiveLabel.Visibility = [System.Windows.Visibility]::Visible
                }
                Write-GuiLog ">> Memproses: $appName... ($cur / $tot)"
            } else {
                Write-GuiLog $line
            }
        }

        if ($Global:Job.State -ne "Running") {
            $Global:MonitorTimer.Stop()
            $leftover = Receive-Job -Job $Global:Job
            foreach ($line in $leftover) { Write-GuiLog $line }
            Remove-Job -Job $Global:Job -Force -ErrorAction SilentlyContinue
            $Global:Job = $null

            # Reset UI
            $BtnInstallApps.IsEnabled = $true
            $BtnDownloadDriver.IsEnabled = $true
            $BtnApplyTweaks.IsEnabled = $true
            $BtnGlpiInstall.IsEnabled = $true
            $BtnGlpiUpdateTag.IsEnabled = $true
            $BtnGlpiDeploy.IsEnabled = $true
            Update-GlpiStatus

            if ($Global:ActivePrgBar) {
                $Global:ActivePrgBar.Value = 100
                $Global:ActivePrgBar.Visibility = [System.Windows.Visibility]::Collapsed
            }
            if ($Global:ActiveLabel) { $Global:ActiveLabel.Text = ""; $Global:ActiveLabel.Visibility = [System.Windows.Visibility]::Collapsed }
            $Global:ActivePrgBar = $null
            $Global:ActiveLabel  = $null

            Write-GuiLog "[+] Operasi selesai."
            Show-CustomNotification "Proses selesai! Lihat Console Log untuk detail." "success"
        }
    }
})

# === STEP 16: INSTALL SCRIPT BLOCK ===
$InstallScriptBlock = {
    param($appsToInstall, $targetDir, $logPath)

    function Write-Log { param($n, $s)
        $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        try { Add-Content -Path $logPath -Value "[$ts] $n -- $s" -Encoding UTF8 } catch {}
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Ratakan array jika bersarang (nested array)
    $apps = @()
    if ($appsToInstall -is [System.Collections.IList] -or $appsToInstall -is [Array]) {
        if ($appsToInstall.Count -eq 1 -and ($appsToInstall[0] -is [System.Collections.IList] -or $appsToInstall[0] -is [Array])) {
            $apps = @($appsToInstall[0])
        } else {
            $apps = @($appsToInstall)
        }
    } else {
        $apps = @($appsToInstall)
    }

    $total = $apps.Count

    for ($i = 0; $i -lt $total; $i++) {
        $app = $apps[$i]
        $progLine = "[PROG]" + ($i+1).ToString() + ":" + $total.ToString() + ":" + $app.Name
        Write-Output $progLine


        if ($app.Type -eq "winget") {
            & winget install --id $app.Id --silent --accept-source-agreements --accept-package-agreements 2>$null
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189 -or $LASTEXITCODE -eq -1978335222) {
                Write-Output "[+] Berhasil: $($app.Name)"
                Write-Log $app.Name "Berhasil"
            } else {
                Write-Output "[-] Gagal: $($app.Name) (Exit: $LASTEXITCODE)"
                Write-Log $app.Name "Gagal (Exit: $LASTEXITCODE)"
            }
        }
        elseif ($app.Type -eq "github_release") {
            try {
                $api = Invoke-RestMethod -Uri "https://api.github.com/repos/$($app.Repo)/releases/latest" -ErrorAction Stop
                $asset = $api.assets | Where-Object { $_.name -like $app.AssetFilter } | Select-Object -First 1
                if (-not $asset) { Write-Output "[-] Aset tidak ditemukan: $($app.Name)"; Write-Log $app.Name "Gagal - aset tidak ditemukan"; continue }
                $dest = Join-Path $env:TEMP $asset.name
                Write-Output "    Mengunduh $($asset.name)..."
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing
                Start-Process -FilePath $dest -Wait
                Remove-Item $dest -ErrorAction SilentlyContinue
                Write-Output "[+] Selesai: $($app.Name)"
                Write-Log $app.Name "Berhasil"
            } catch { Write-Output "[-] Error: $_"; Write-Log $app.Name "Gagal: $_" }
        }
        elseif ($app.Type -eq "direct_link") {
            try {
                $fileName = if ($app.FileName) { $app.FileName } else { [System.IO.Path]::GetFileName([System.Uri]::new($app.Url).AbsolutePath) }
                if (-not $fileName) { $fileName = "installer.exe" }
                $dest = Join-Path $env:TEMP $fileName
                Write-Output "    Mengunduh $fileName..."
                Invoke-WebRequest -Uri $app.Url -OutFile $dest -UseBasicParsing -ErrorAction Stop
                $args = if ($app.Args) { $app.Args } else { "" }
                if ($args) {
                    $proc = Start-Process -FilePath $dest -ArgumentList $args -Wait -PassThru
                    Write-Output "[+] Selesai: $($app.Name) (Exit: $($proc.ExitCode))"
                } else {
                    Start-Process -FilePath $dest -Wait
                    Write-Output "[+] Selesai: $($app.Name)"
                }
                Remove-Item $dest -ErrorAction SilentlyContinue
                Write-Log $app.Name "Berhasil"
            } catch { Write-Output "[-] Error: $_"; Write-Log $app.Name "Gagal: $_" }
        }
        elseif ($app.Type -eq "download_to_folder") {
            try {
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                $fileName = if ($app.FileName) { $app.FileName } else { [System.IO.Path]::GetFileName([System.Uri]::new($app.Url).AbsolutePath) }
                if (-not $fileName) { $fileName = "downloaded_file.zip" }
                $dest = Join-Path $targetDir $fileName
                Write-Output "    Mengunduh ke $targetDir..."
                Invoke-WebRequest -Uri $app.Url -OutFile $dest -UseBasicParsing -ErrorAction Stop
                Write-Output "[+] Berhasil diunduh: $dest"
                Write-Log $app.Name "Berhasil diunduh ke $dest"

                if ($app.Extract -eq $true) {
                    if ($fileName.EndsWith(".zip", [System.StringComparison]::OrdinalIgnoreCase)) {
                        Write-Output "    Mengekstrak ZIP..."
                        Expand-Archive -Path $dest -DestinationPath $targetDir -Force
                        Remove-Item $dest -ErrorAction SilentlyContinue
                        Write-Output "[+] Ekstraksi ZIP selesai."
                    } elseif ($fileName.EndsWith(".rar", [System.StringComparison]::OrdinalIgnoreCase) -or $fileName.EndsWith(".7z", [System.StringComparison]::OrdinalIgnoreCase)) {
                        $sevenZip = "C:\Program Files\7-Zip\7z.exe"
                        if (Test-Path $sevenZip) {
                            Write-Output "    Mengekstrak dengan 7-Zip..."
                            & $sevenZip x $dest "-o$targetDir" -y 2>$null | Out-Null
                            Remove-Item $dest -ErrorAction SilentlyContinue
                            Write-Output "[+] Ekstraksi selesai."
                        } else { Write-Output "[!] 7-Zip tidak ditemukan, file dibiarkan." }
                    }
                }
            } catch { Write-Output "[-] Error: $_"; Write-Log $app.Name "Gagal: $_" }
        }
    }
}

# === STEP 17: INSTALL APPS BUTTON ===
$BtnInstallApps.Add_Click({
    $selected = @($Global:AppCheckBoxes | Where-Object { $_.IsChecked -eq $true })
    if ($selected.Count -eq 0) {
        Show-CustomNotification "Pilih minimal satu aplikasi untuk diinstal." "warning"
        return
    }

    $BtnInstallApps.IsEnabled = $false
    $BtnDownloadDriver.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false

    $PrgInstall.Value = 0
    $PrgInstall.Visibility = [System.Windows.Visibility]::Visible
    $TxtProgressLabel.Visibility = [System.Windows.Visibility]::Visible
    $TxtProgressLabel.Text = "Menyiapkan instalasi..."
    $Global:ActivePrgBar = $PrgInstall
    $Global:ActiveLabel  = $TxtProgressLabel

    Write-GuiLog "[*] Memulai instalasi $($selected.Count) aplikasi..."
    Switch-Panel "Log"

    $targetDir = $TxtTargetFolder.Text
    $logPath   = "$WinSiRiadyDir\install_history.log"

    $Global:Job = Start-Job -ScriptBlock $InstallScriptBlock -ArgumentList @(,$selected.Tag), $targetDir, $logPath
    $Global:MonitorTimer.Start()
})

# === STEP 18: DOWNLOAD DRIVER BUTTON ===
$BtnDownloadDriver.Add_Click({
    $selected = @($Global:DriverCheckBoxes | Where-Object { $_.IsChecked -eq $true })
    if ($selected.Count -eq 0) {
        Show-CustomNotification "Pilih minimal satu driver untuk diunduh." "warning"
        return
    }

    $BtnInstallApps.IsEnabled = $false
    $BtnDownloadDriver.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false

    $PrgDriver.Value = 0
    $PrgDriver.Visibility = [System.Windows.Visibility]::Visible
    $TxtDriverProgressLabel.Visibility = [System.Windows.Visibility]::Visible
    $TxtDriverProgressLabel.Text = "Menyiapkan unduhan driver..."
    $Global:ActivePrgBar = $PrgDriver
    $Global:ActiveLabel  = $TxtDriverProgressLabel

    Write-GuiLog "[*] Memulai unduhan $($selected.Count) driver..."
    Switch-Panel "Log"

    $targetDir = $TxtTargetFolder.Text
    $logPath   = "$WinSiRiadyDir\install_history.log"

    $Global:Job = Start-Job -ScriptBlock $InstallScriptBlock -ArgumentList @(,$selected.Tag), $targetDir, $logPath
    $Global:MonitorTimer.Start()
})

# === STEP 19: APPLY TWEAKS BUTTON ===
$BtnApplyTweaks.Add_Click({
    $tweaks = @{
        Telemetry = [bool]$ChkTelemetry.IsChecked
        Cortana   = [bool]$ChkCortana.IsChecked
        Bloatware = [bool]$ChkBloatware.IsChecked
        DarkTheme = [bool]$ChkDarkTheme.IsChecked
    }

    $BtnInstallApps.IsEnabled = $false
    $BtnDownloadDriver.IsEnabled = $false
    $BtnApplyTweaks.IsEnabled = $false

    $PrgTweaks.Value = 0
    $PrgTweaks.Visibility = [System.Windows.Visibility]::Visible
    $TxtTweaksProgressLabel.Visibility = [System.Windows.Visibility]::Visible
    $TxtTweaksProgressLabel.Text = "Menjalankan optimasi..."
    $Global:ActivePrgBar = $PrgTweaks
    $Global:ActiveLabel  = $TxtTweaksProgressLabel

    Write-GuiLog "[*] Menjalankan optimasi sistem..."
    Switch-Panel "Log"

    $TweaksBlock = {
        param($tweaks, $rootPath)
        $tweaksFile = Join-Path $rootPath "tweaks.ps1"
        if (Test-Path $tweaksFile) { . $tweaksFile } else { Write-Output "[-] tweaks.ps1 tidak ditemukan."; return }
        if ($tweaks.Telemetry) { Write-Output "[PROG]1:4:Matikan Telemetri"; Optimize-Telemetry }
        if ($tweaks.Cortana)   { Write-Output "[PROG]2:4:Nonaktifkan Cortana"; Optimize-Cortana }
        if ($tweaks.Bloatware) { Write-Output "[PROG]3:4:Hapus Bloatware"; Remove-Bloatware }
        if ($tweaks.DarkTheme) { Write-Output "[PROG]4:4:Aktifkan Dark Mode"; Enable-DarkTheme }
    }

    $Global:Job = Start-Job -ScriptBlock $TweaksBlock -ArgumentList $tweaks, $LocalRoot
    $Global:MonitorTimer.Start()
})

# === STEP 19.5: GLPI AGENT HANDLERS ===
$GlpiInstallScriptBlock = {
    param($AssetTag, $logPath)
    
    function Write-Log { param($n, $s)
        $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        try { Add-Content -Path $logPath -Value "[$ts] $n -- $s" -Encoding UTF8 } catch {}
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Output "[PROG]1:3:Mencari rilis GLPI Agent terbaru..."
    
    $ServerURL = "https://itpma-ticketing.pinusmerahabadi.co.id/plugins/glpiinventory/"
    $Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    $TempDir = "$env:TEMP\glpi-agent-install"
    $MsiLogFile = "$TempDir\glpi-agent-msi.log"
    
    if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir | Out-Null }
    
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/glpi-project/glpi-agent/releases/latest" -UseBasicParsing -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -match "glpi-agent-.*-$Arch\.msi$" } | Select-Object -First 1
        if (-not $asset) { throw "MSI $Arch tidak ditemukan" }
        
        $MsiUrl  = $asset.browser_download_url
        $MsiPath = Join-Path $TempDir $asset.name
        
        Write-Output "[PROG]2:3:Mengunduh GLPI Agent installer..."
        Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiPath -UseBasicParsing -ErrorAction Stop
        
        Write-Output "[PROG]3:3:Menginstal GLPI Agent..."
        $msiArgs = @(
            "/i", "`"$MsiPath`"",
            "SERVER=`"$ServerURL`"",
            "TAG=`"$AssetTag`"",
            "ADDLOCAL=ALL",
            "/quiet", "/norestart",
            "/l*v", "`"$MsiLogFile`""
        )
        $proc = Start-Process "msiexec.exe" -ArgumentList $msiArgs -PassThru -Wait
        
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            Write-Output "[+] GLPI Agent berhasil diinstal dengan TAG: $AssetTag"
            Write-Log "GLPI Agent" "Berhasil diinstal"
            
            # Start service
            $ServiceName = "glpi-agent"
            try {
                $svc = Get-Service -Name $ServiceName -ErrorAction Stop
                if ($svc.Status -ne 'Running') { Start-Service -Name $ServiceName }
                Set-Service -Name $ServiceName -StartupType Automatic
                Write-Output "[+] Service glpi-agent berjalan otomatis."
            } catch {
                Write-Output "[!] Gagal menjalankan service: $_"
            }
        } else {
            Write-Output "[-] Gagal menginstal GLPI Agent. Exit code: $($proc.ExitCode)"
            Write-Log "GLPI Agent" "Gagal (Exit: $($proc.ExitCode))"
        }
    } catch {
        Write-Output "[-] Error saat instalasi: $_"
        Write-Log "GLPI Agent" "Gagal ($_)"
    }
}

$GlpiDeployScriptBlock = {
    param($logPath)
    Write-Output "[PROG]1:1:Menjalankan Force Inventory..."
    $glpiBat = "C:\Program Files\GLPI-Agent\glpi-agent.bat"
    if (Test-Path $glpiBat) {
        Write-Output "[*] Memulai sinkronisasi data inventory ke server GLPI..."
        $proc = Start-Process -FilePath $glpiBat -ArgumentList "--force", "--logger=stderr" -NoNewWindow -PassThru -Wait
        if ($proc.ExitCode -eq 0) {
            Write-Output "[+] Deploy/Inventory berhasil dikirim."
        } else {
            Write-Output "[-] Deploy/Inventory selesai dengan kode keluar: $($proc.ExitCode)"
        }
    } else {
        Write-Output "[-] Bat file GLPI Agent tidak ditemukan di C:\Program Files\GLPI-Agent"
    }
}

$GlpiUninstallScriptBlock = {
    param($logPath)
    
    function Write-Log { param($n, $s)
        $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        try { Add-Content -Path $logPath -Value "[$ts] $n -- $s" -Encoding UTF8 } catch {}
    }

    Write-Output "[PROG]1:1:Mencari entri instalasi GLPI Agent..."
    $uninstallKey = Get-ChildItem -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -like "*GLPI Agent*" -or $_.DisplayName -like "*GLPI-Agent*" }

    if ($uninstallKey) {
        $uninstallString = $uninstallKey.UninstallString
        if ($uninstallString -match '({[A-Z0-9\-]+})') {
            $guid = $Matches[1]
            Write-Output "[*] Menemukan GLPI Agent GUID: $guid"
            Write-Output "[*] Memulai uninstalasi silang..."
            $proc = Start-Process "msiexec.exe" -ArgumentList "/x", $guid, "/qn", "/norestart" -PassThru -Wait
            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                Write-Output "[+] GLPI Agent berhasil diuninstal."
                Write-Log "GLPI Agent" "Berhasil diuninstal"
            } else {
                Write-Output "[-] Uninstalasi gagal dengan exit code: $($proc.ExitCode)"
                Write-Log "GLPI Agent" "Gagal diuninstal (Exit: $($proc.ExitCode))"
            }
        } else {
            $cleanCmd = $uninstallString -replace '"', ''
            Write-Output "[*] Menjalankan perintah uninstal: $cleanCmd"
            if ($cleanCmd -match "msiexec") { $cleanCmd = $cleanCmd + " /qn /norestart" }
            $proc = Start-Process cmd.exe -ArgumentList "/c $cleanCmd" -PassThru -Wait
            if ($proc.ExitCode -eq 0) {
                Write-Output "[+] GLPI Agent berhasil diuninstal."
                Write-Log "GLPI Agent" "Berhasil diuninstal"
            } else {
                Write-Output "[-] Uninstalasi selesai dengan exit code: $($proc.ExitCode)"
                Write-Log "GLPI Agent" "Gagal diuninstal (Exit: $($proc.ExitCode))"
            }
        }
        
        # Salin log agent sebelum dihapus ke folder C:\WinSiRiady
        Write-Output "[*] Mem-backup log GLPI Agent ke C:\WinSiRiady..."
        $backupDir = "C:\WinSiRiady"
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        
        $possibleLogs = @(
            (Join-Path $env:ProgramData "GLPI-Agent\glpi-agent.log"),
            "C:\Program Files\GLPI-Agent\glpi-agent.log",
            "C:\Program Files\GLPI-Agent\logs\glpi-agent.log"
        )
        
        foreach ($log in $possibleLogs) {
            if (Test-Path $log) {
                try {
                    $destPath = Join-Path $backupDir "glpi-agent-backup.log"
                    Copy-Item -Path $log -Destination $destPath -Force -ErrorAction Stop
                    Write-Output "[+] Berhasil mem-backup log ke: $destPath"
                    break
                } catch {
                    Write-Output "[!] Gagal mem-backup log '$log': $_"
                }
            }
        }

        # Hapus sisa folder dan log jika ada
        Write-Output "[*] Membersihkan sisa folder, log, dan cache GLPI Agent..."
        if (Test-Path "C:\Program Files\GLPI-Agent") {
            Remove-Item "C:\Program Files\GLPI-Agent" -Recurse -Force -ErrorAction SilentlyContinue
        }
        $progDataPath = Join-Path $env:ProgramData "GLPI-Agent"
        if (Test-Path $progDataPath) {
            Remove-Item $progDataPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Output "[-] GLPI Agent tidak ditemukan di registry sistem."
    }
}

$BtnGlpiInstall.Add_Click({
    $tag = $TxtGlpiInstallTag.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Show-CustomNotification "TAG tidak boleh kosong untuk instalasi baru!" "warning"
        return
    }
    if ($tag -notmatch '^\d+$') {
        Show-CustomNotification "TAG hanya boleh diisi angka!" "warning"
        return
    }

    $BtnGlpiInstall.IsEnabled = $false
    $BtnGlpiUpdateTag.IsEnabled = $false
    $BtnGlpiDeploy.IsEnabled = $false

    $PrgGlpi.Value = 0
    $PrgGlpi.Visibility = [System.Windows.Visibility]::Visible
    $TxtGlpiProgressLabel.Visibility = [System.Windows.Visibility]::Visible
    $TxtGlpiProgressLabel.Text = "Menyiapkan instalasi GLPI Agent..."
    $Global:ActivePrgBar = $PrgGlpi
    $Global:ActiveLabel  = $TxtGlpiProgressLabel

    Write-GuiLog "[*] Memulai instalasi GLPI Agent dengan TAG: $tag..."
    Switch-Panel "Log"

    $logPath = "$WinSiRiadyDir\install_history.log"
    $Global:Job = Start-Job -ScriptBlock $GlpiInstallScriptBlock -ArgumentList $tag, $logPath
    $Global:MonitorTimer.Start()
})

$BtnGlpiUpdateTag.Add_Click({
    $newTag = $TxtGlpiCurrentTag.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($newTag)) {
        Show-CustomNotification "TAG baru tidak boleh kosong!" "warning"
        return
    }
    if ($newTag -notmatch '^\d+$') {
        Show-CustomNotification "TAG hanya boleh diisi angka!" "warning"
        return
    }
    $regPath = "HKLM:\SOFTWARE\GLPI-Agent"
    if (-not (Test-Path $regPath)) { $regPath = "HKLM:\SOFTWARE\Wow6432Node\GLPI-Agent" }
    if (Test-Path $regPath) {
        try {
            Set-ItemProperty -Path $regPath -Name "tag" -Value $newTag -Force -ErrorAction Stop
            Write-GuiLog "[*] Mengupdate TAG ke '$newTag' dan merestart service glpi-agent..."
            Restart-Service -Name "glpi-agent" -Force -ErrorAction Stop
            Show-CustomNotification "TAG berhasil diupdate ke '$newTag' dan service berhasil direstart!" "success"
            Update-GlpiStatus
        } catch {
            Show-CustomNotification "Gagal mengupdate TAG: $_" "warning"
        }
    } else {
        Show-CustomNotification "Registry GLPI Agent tidak ditemukan." "warning"
    }
})

$BtnGlpiDeploy.Add_Click({
    $BtnGlpiInstall.IsEnabled = $false
    $BtnGlpiUpdateTag.IsEnabled = $false
    $BtnGlpiDeploy.IsEnabled = $false

    $PrgGlpi.Value = 0
    $PrgGlpi.Visibility = [System.Windows.Visibility]::Visible
    $TxtGlpiProgressLabel.Visibility = [System.Windows.Visibility]::Visible
    $TxtGlpiProgressLabel.Text = "Menjalankan deploy/inventory..."
    $Global:ActivePrgBar = $PrgGlpi
    $Global:ActiveLabel  = $TxtGlpiProgressLabel

    Write-GuiLog "[*] Memulai deploy/force inventory ke server GLPI..."
    Switch-Panel "Log"

    $logPath = "$WinSiRiadyDir\install_history.log"
    $Global:Job = Start-Job -ScriptBlock $GlpiDeployScriptBlock -ArgumentList $logPath
    $Global:MonitorTimer.Start()
})

$BtnGlpiUninstall.Add_Click({
    $BtnGlpiInstall.IsEnabled = $false
    $BtnGlpiUpdateTag.IsEnabled = $false
    $BtnGlpiDeploy.IsEnabled = $false
    $BtnGlpiUninstall.IsEnabled = $false

    $PrgGlpi.Value = 0
    $PrgGlpi.Visibility = [System.Windows.Visibility]::Visible
    $TxtGlpiProgressLabel.Visibility = [System.Windows.Visibility]::Visible
    $TxtGlpiProgressLabel.Text = "Menghapus GLPI Agent dari sistem..."
    $Global:ActivePrgBar = $PrgGlpi
    $Global:ActiveLabel  = $TxtGlpiProgressLabel

    Write-GuiLog "[*] Memulai uninstalasi GLPI Agent..."
    Switch-Panel "Log"

    $logPath = "$WinSiRiadyDir\install_history.log"
    $Global:Job = Start-Job -ScriptBlock $GlpiUninstallScriptBlock -ArgumentList $logPath
    $Global:MonitorTimer.Start()
})

$TxtGlpiInstallTag.Add_TextChanged({
    $text = $this.Text
    $numeric = $text -replace '[^0-9]', ''
    if ($text -ne $numeric) {
        $this.Text = $numeric
        $this.CaretIndex = $numeric.Length
    }
})

$TxtGlpiCurrentTag.Add_TextChanged({
    $text = $this.Text
    $numeric = $text -replace '[^0-9]', ''
    if ($text -ne $numeric) {
        $this.Text = $numeric
        $this.CaretIndex = $numeric.Length
    }
})

Update-GlpiStatus

# === STEP 20: TAMPILKAN WINDOW ===
$Window.ShowDialog() | Out-Null
