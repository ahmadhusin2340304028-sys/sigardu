<?php
// app/Models/Undangan.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Undangan extends Model
{
    protected $table = 'undangan';

    protected $fillable = [
        'judul_kegiatan',
        'tanggal',
        'waktu',
        'tempat',
        'pihak_mengundang',
        'bidang_terkait',
        'status_kegiatan',
        'menghadiri',
        'bukti',
        'delegasi',
    ];

    protected $casts = [
        'tanggal'    => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Status constants
    const STATUS_BELUM      = 'Belum Dilaksanakan';
    const STATUS_SELESAI    = 'Sudah Dilaksanakan';

    // Menghadiri constants
    const HADIR_YA          = 'Hadir';
    const HADIR_TIDAK       = 'Tidak Hadir';
    const HADIR_DELEGASI    = 'Delegasi';
    const HADIR_PENDING     = 'Pending';

    /**
     * Apakah undangan sudah lewat tanggalnya.
     */
    public function getIsPastAttribute(): bool
    {
        return $this->tanggal->isPast();
    }

    /**
     * URL bukti file.
     */
    public function getBuktiUrlAttribute(): ?string
    {
        return $this->bukti ? asset('storage/' . $this->bukti) : null;
    }
}
