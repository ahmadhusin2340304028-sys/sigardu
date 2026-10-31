<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::get('/', function () {
    return view('welcome');
});

Route::view('/privacy-policy', 'privacy');

Route::get('/files/{path}', function (string $path) {
    abort_unless(
        preg_match('/\Abukti\/[0-9]+\/[A-Za-z0-9._-]+\z|\Abukti-undangan\/[A-Za-z0-9._-]+\z/', $path) === 1,
        404
    );

    $disk = Storage::disk('public');
    abort_unless($disk->exists($path), 404);

    return response()->file($disk->path($path));
})->where('path', '.*')->name('bukti.file');
