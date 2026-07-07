# WinSiRiady Utility

**WinSiRiady** adalah aplikasi utilitas berbasis PowerShell GUI (WPF) untuk melakukan setup awal, optimasi sistem, dan instalasi aplikasi secara massal pada sistem operasi Windows 10/11 setelah melakukan instalasi ulang.

Aplikasi ini dirancang menggunakan desain modern gelap (*dark theme*) dan berjalan secara non-blocking menggunakan *background job* PowerShell sehingga UI tetap responsif saat instalasi sedang berjalan.

---

## Fitur Utama

1. **Instalasi Aplikasi Cepat:**
   * **Winget Integration:** Mengunduh dan memasang aplikasi publik resmi secara otomatis (Chrome, Firefox, VS Code, dll.) secara *silent*.
   * **GitHub Releases Integration (Metode 3):** Mencari aset `.exe` rilis terbaru dari repositori GitHub Anda sendiri, mendownload secara otomatis, dan menjalankan installer secara lokal.
2. **Optimasi Sistem (Tweaks):**
   * Menonaktifkan Telemetri dan Layanan Diagnostik Windows untuk meningkatkan privasi.
   * Menonaktifkan asisten Cortana untuk menghemat konsumsi RAM.
   * Menghapus aplikasi bawaan Windows yang tidak diinginkan (*Bloatware removal*).
   * Mengaktifkan Tema Gelap (*Dark Mode*) untuk sistem dan aplikasi.

---

## Cara Menjalankan Aplikasi

Buka terminal **PowerShell sebagai Administrator** dan jalankan perintah satu baris berikut untuk langsung meluncurkan GUI:

```powershell
irm https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1 | iex
```

> *Catatan: Jika branch default repositori Anda adalah `main`, ganti `master` dengan `main` pada URL di atas.*

---

## Menambahkan Aplikasi Kustom (Metode 3)

Untuk menambahkan aplikasi kustom Anda yang ingin diunduh via GitHub Releases:
1. Unggah berkas installer `.exe` aplikasi Anda ke bagian **Releases** di repositori GitHub `riadysandi/WinSiRiady`.
2. Edit file `apps.json` di proyek ini dan tambahkan item baru dengan tipe `github_release`:
   ```json
   {
     "Category": "Nama Kategori",
     "Name": "Nama Aplikasi Anda",
     "Type": "github_release",
     "Repo": "riadysandi/WinSiRiady",
     "AssetFilter": "*nama_file*.exe",
     "Description": "Deskripsi singkat aplikasi Anda."
   }
   ```
3. Simpan dan commit perubahan tersebut ke repositori GitHub Anda.

---

## Struktur Proyek

* `WinSiRiady.ps1` - Berkas utama aplikasi yang merender GUI WPF dan mengatur alur eksekusi.
* `apps.json` - Berkas konfigurasi daftar aplikasi yang akan dimuat ke GUI.
* `tweaks.ps1` - Berkas berisi kumpulan fungsi optimasi sistem Windows.
* `.gitignore` - Konfigurasi Git untuk mengabaikan berkas yang tidak diperlukan.
