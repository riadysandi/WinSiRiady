# Panduan Menambahkan Aplikasi di WinSiRiady Utility

Panduan ini menjelaskan cara menambahkan aplikasi baru ke dalam file konfigurasi `apps.json` Anda. Setelah menambahkan aplikasi, Anda cukup melakukan *commit* dan *push* ke GitHub agar aplikasi tersebut dapat langsung digunakan secara online menggunakan perintah `irm`.

---

## Format Dasar `apps.json`

File `apps.json` berisi array objek JSON. Setiap aplikasi didefinisikan dengan properti berikut:
* `Category` : Kategori aplikasi (misal: "Browsers", "Utilities"). Aplikasi dengan kategori yang sama akan dikelompokkan bersama di tampilan GUI.
* `Name` : Nama aplikasi yang akan tampil di GUI.
* `Type` : Jenis metode instalasi (`winget`, `direct_link`, atau `download_to_folder`).
* `Description` : Deskripsi singkat aplikasi.

Berikut adalah penjelasan detail untuk masing-masing tipe instalasi:

---

## 1. Aplikasi Standard via Winget (`"Type": "winget"`)
Gunakan metode ini untuk aplikasi publik umum yang tersedia di repositori resmi Windows Package Manager (Winget).

### Format JSON:
```json
  {
    "Category": "Browsers",
    "Name": "Google Chrome",
    "Type": "winget",
    "Id": "Google.Chrome",
    "Description": "Web browser dari Google."
  }
```

### Cara mencari `"Id"` aplikasi:
1. Buka PowerShell dan jalankan perintah:
   ```powershell
   winget search "Nama Aplikasi"
   ```
2. Ambil nilai kolom **Id** dari aplikasi yang Anda inginkan (contoh: `Google.Chrome` atau `RARLab.WinRAR`) dan masukkan ke properti `"Id"` di JSON.

---

## 2. Aplikasi Kustom via URL Langsung (`"Type": "direct_link"`)
Gunakan metode ini untuk mengunduh berkas `.exe` atau `.msi` dari server penyimpanan pribadi seperti **Nextcloud**, Google Drive, dll., lalu menginstalnya ke komputer.

### Format JSON:
```json
  {
    "Category": "Aplikasi Kustom",
    "Name": "Aplikasi Saya",
    "Type": "direct_link",
    "Url": "https://cloud.pinusmerahabadi.co.id/index.php/s/KODE_SHARE_NEXTCLOUD/download",
    "FileName": "AplikasiSaya.exe",
    "Args": "/S",
    "Description": "Unduh dan pasang aplikasi kustom dari Nextcloud."
  }
```

### Parameter Penting:
* **`Url`** : Link unduhan langsung. Jika menggunakan Nextcloud, buat *public share link* lalu tambahkan **/download** di bagian paling akhir URL.
* **`FileName`** : Nama berkas sementara saat diunduh ke PC Anda.
* **`Args` (Opsional)** : Argumen silent install (instalasi otomatis di latar belakang).
  * Contoh: `/S` (untuk installer jenis NSIS), `/silent` (Inno Setup), `/qn` (MSI).
  * *Jika dikosongkan/dihapus, installer akan muncul di layar secara interaktif seperti biasa.*

---

## 3. Berkas Arsip / File RAR (`"Type": "download_to_folder"`)
Gunakan metode ini jika Anda ingin mengunduh berkas `.zip`, `.rar`, atau berkas portable lainnya, lalu memindahkannya secara otomatis ke folder khusus **`C:\WinSiRiady`** di PC target.

### Format JSON (Hanya Unduh File RAR/ZIP):
```json
  {
    "Category": "Files Extraction",
    "Name": "Resetter Epson L5190",
    "Type": "download_to_folder",
    "Url": "https://cloud.pinusmerahabadi.co.id/index.php/s/6wGFSEAbRPHc8da/download",
    "FileName": "Resetter Epson L5190 ITKoding.rar",
    "Extract": false,
    "Description": "Unduh file resetter epson tanpa diekstrak ke C:\\WinSiRiady."
  }
```

### Format JSON (Unduh dan Ekstrak Otomatis):
```json
  {
    "Category": "Driver Pack",
    "Name": "Driver Printer Epson L120",
    "Type": "download_to_folder",
    "Url": "https://cloud.pinusmerahabadi.co.id/index.php/s/KODE_SHARE_DRIVERS/download",
    "FileName": "epson_l120.zip",
    "Extract": true,
    "Description": "Unduh dan ekstrak driver printer secara otomatis."
  }
```

### Parameter Penting:
* **`Extract`** : Set ke `true` jika ingin berkas arsip langsung diekstrak secara otomatis setelah unduhan selesai. Set ke `false` jika hanya ingin berkas rar/zip tetap utuh di folder `C:\WinSiRiady`.
  * *Pengecekan Otomatis:* Jika berkas berupa `.zip`, Windows akan mengekstraknya secara native. Jika berkas berupa `.rar` atau `.7z`, skrip akan otomatis memanggil aplikasi **7-Zip** (jika terinstal di `C:\Program Files\7-Zip\7z.exe`).

---

## 4. Cara Update Online di GitHub

Setelah Anda mengedit berkas `apps.json` di komputer Anda, jalankan rentetan perintah berikut di PowerShell Administrator Anda untuk mempublikasikan daftarnya agar bisa langsung diakses online oleh siapa saja:

```powershell
cd d:\PROJECT\WinSiRiady
git add apps.json
git commit -m "Update list aplikasi baru"
git push
```

Setelah perintah `git push` sukses, Anda langsung bisa menjalankan skrip online di PC mana pun menggunakan perintah satu baris ini:

```powershell
irm "https://raw.githubusercontent.com/riadysandi/WinSiRiady/master/WinSiRiady.ps1?$(Get-Random)" | iex
```
