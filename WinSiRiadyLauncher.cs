using System;
using System.Diagnostics;
using System.Windows.Forms;

namespace WinSiRiadyLauncher
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = "powershell.exe";
            
            // Perintah lengkap yang kompatibel untuk Windows 7 hingga Windows 11
            string psCommand = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1') | iex";
            
            psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command \"" + psCommand + "\"";
            psi.Verb = "runas"; // Meminta akses Administrator (UAC prompt) otomatis
            psi.UseShellExecute = true;
            psi.WindowStyle = ProcessWindowStyle.Hidden;

            try
            {
                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Gagal menjalankan WinSiRiady:\n\n" + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
