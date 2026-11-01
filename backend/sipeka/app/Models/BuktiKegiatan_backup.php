<?php
// app/Models/BuktiKegiatan.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BuktiKegiatan extends Model
{
    protected $table = 'bukti_kegiatan';

    protected $fillable = [
        'kegiatan_id',
        'bulan',
        'file_path',
    ];

    protected $casts = [
        'bulan' => 'integer',
    ];

    public $timestamps = false;

    public function kegiatan(): BelongsTo
    {
        return $this->belongsTo(Kegiatan::class, 'kegiatan_id');
    }

    /**
     * Full URL untuk mengakses file.
     */
    public function getFileUrlAttribute(): string
    {
        return asset('storage/' . $this->file_path);
    }
}
