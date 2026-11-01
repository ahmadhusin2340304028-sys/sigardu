<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

/*
|--------------------------------------------------------------------------
| Halaman Blade SIGARDU
|--------------------------------------------------------------------------
| Semua halaman hanya "shell" Blade. Data diambil lewat /api/* (Bearer token,
| sama seperti aplikasi Flutter), jadi backend tidak berubah.
| Proteksi login/role di sisi halaman dilakukan JS (setara _AdminGuard di
| Flutter); keamanan sebenarnya tetap di middleware API.
*/

Route::view('/', 'splash');
Route::view('/login', 'auth.login');
Route::view('/dashboard', 'dashboard');
Route::view('/tentang', 'tentang');
Route::view('/undangan', 'undangan.index');

Route::prefix('kegiatan')->group(function () {
    Route::view('/', 'kegiatan.index');
    Route::get('/{id}', fn (string $id) => view('kegiatan.detail', ['id' => $id]))->whereNumber('id');
    Route::get('/{id}/realisasi', fn (string $id) => view('kegiatan.input-realisasi', ['id' => $id]))->whereNumber('id');
});

Route::prefix('admin')->group(function () {
    Route::view('/bidang', 'admin.bidang');
    Route::view('/kegiatan', 'admin.kegiatan');
    Route::view('/undangan', 'admin.undangan');
    Route::view('/data', 'admin.data');
});

Route::view('/privacy-policy', 'privacy');

// Baca file bukti TANPA `php artisan storage:link` (aman untuk hosting gratis).
// File diambil dari disk "public" (storage/app/public) lewat route ini.
Route::get('/files/{path}', function (string $path) {
    abort_unless(
        preg_match('/\Abukti\/[0-9]+\/[A-Za-z0-9._-]+\z|\Abukti-undangan\/[A-Za-z0-9._-]+\z/', $path) === 1,
        404
    );

    $disk = Storage::disk('public');
    abort_unless($disk->exists($path), 404);

    return response()->file($disk->path($path));
})->where('path', '.*')->name('bukti.file');
