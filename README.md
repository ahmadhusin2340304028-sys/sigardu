# SIGARDU

**Sistem Informasi Pelaporan Kinerja dan Anggaran Kegiatan** — aplikasi untuk memantau realisasi fisik dan anggaran kegiatan per bulan dan triwulan, serta mengelola undangan, dengan hak akses per bidang.

Satu backend REST API dipakai oleh dua klien: **aplikasi mobile (Flutter)** dan **aplikasi web (Laravel Blade)**.

![Laravel](https://img.shields.io/badge/Laravel-11-FF2D20?logo=laravel&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?logo=mysql&logoColor=white)

<!-- Tambahkan screenshot di sini, contoh:
| Dashboard | Input Realisasi | Undangan |
|---|---|---|
| ![](docs/screenshots/dashboard.png) | ![](docs/screenshots/realisasi.png) | ![](docs/screenshots/undangan.png) |
-->

## Fitur

**Pemantauan kinerja & anggaran**

- Dashboard ringkasan: total kegiatan, rata-rata realisasi fisik, serapan anggaran, progres per bidang
- Daftar kegiatan dengan pencarian, filter bidang, dan infinite scroll
- Detail kegiatan: grafik realisasi bulanan dan rincian per triwulan
- Input realisasi fisik, anggaran, keterangan, dan unggah bukti (PDF/JPG/PNG) per bulan
- Export laporan ke **Excel** dan **PDF** dengan filter bidang, tahun, dan capaian minimal

**Undangan**

- Konfirmasi hadir (dengan opsi delegasi dan bukti kehadiran) atau tidak hadir
- Undangan pending terdekat tampil di dashboard

**Administrasi (khusus Admin)**

- Kelola bidang beserta akun staff-nya (hapus bidang dengan konfirmasi dua tahap)
- Kelola kegiatan dan undangan
- Kelola data: backup database `.sql`, impor kegiatan dari Excel, hapus kegiatan per tahun, hapus undangan yang melewati masa simpan

**Umum**

- Login berbasis token, mode terang/gelap

## Hak akses

| Role                     | Akses                                                                            |
| ------------------------ | -------------------------------------------------------------------------------- |
| Admin                    | Seluruh fitur, termasuk menu administrasi                                        |
| Staff bidang             | Melihat semua kegiatan; input realisasi dan bukti hanya untuk kegiatan bidangnya |
| Kepala Dinas, Sekretaris | Hanya melihat (view-only)                                                        |

Aturan ini ditegakkan di sisi API lewat middleware `role` dan `bidang.access`, bukan hanya disembunyikan di tampilan.

## Arsitektur

```
Aplikasi Flutter ─┐
                  ├──► Laravel REST API (/api, Sanctum Bearer token) ──► MySQL
Aplikasi Web ─────┘
(Blade + JS)
```

```
sigardu/
├── backend/   # Laravel: REST API + halaman web Blade
├── mobile/    # Flutter
├── LICENSE
└── README.md
```

## Tech stack

| Bagian  | Teknologi                                                  |
| ------- | ---------------------------------------------------------- |
| Backend | Laravel 11, Laravel Sanctum, MySQL, DomPDF, PhpSpreadsheet |
| Mobile  | Flutter, Dart, Provider, Dio, file_picker                  |
| Web     | Blade, JavaScript (tanpa framework/build step), CSS kustom |

## Catatan teknis

- **Satu API, dua klien** — web memakai endpoint dan token yang sama dengan mobile, sehingga logika bisnis tidak diduplikasi.
- **Cocok untuk shared hosting** — file bukti dilayani lewat route `/files/{path}` tanpa `storage:link`, dan backup SQL dibuat lewat koneksi database Laravel tanpa `mysqldump`.
- **Impor Excel aman** — seluruh baris divalidasi lebih dulu; data hanya disimpan jika semuanya valid, dalam satu transaksi.
- **Laporan Excel** mengikuti format laporan realisasi (kolom K/A per bulan, pengelompokan triwulan, kolom ringkasan).

## Menjalankan project

### Backend (API + web)

```bash
cd backend
composer install
cp .env.example .env        # atur DB_* dan APP_URL
php artisan key:generate
php artisan migrate
php artisan serve
```

Buat akun Admin pertama:

```bash
php artisan tinker
>>> App\Models\User::create(['username' => 'admin', 'password' => bcrypt('ganti-password'), 'role' => 'Admin']);
```

Aplikasi web dapat dibuka di `http://127.0.0.1:8000`.

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

Atur alamat API di `lib/providers/dio_provider.dart` (`baseApiUrl`), misalnya `http://10.0.2.2:8000/api` untuk emulator Android.

## Tim

- Ahmad Husin — Software Engineer
- Rangga Saputra — Frontend Developer
- Adi Saputra — UI/UX Designer

## Lisensi

[MIT](LICENSE)
