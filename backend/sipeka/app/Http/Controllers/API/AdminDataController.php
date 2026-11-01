<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Bidang;
use App\Models\BuktiKegiatan;
use App\Models\Kegiatan;
use App\Models\Undangan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use PhpOffice\PhpSpreadsheet\IOFactory;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/**
 * Administrative operations which intentionally affect more than one record.
 * All routes to this controller are protected by auth:sanctum + role:Admin.
 */
class AdminDataController extends Controller
{
    private const IMPORT_HEADERS = [
        'Bidang' => 'bidang',
        'Sasaran' => 'sasaran_strategis',
        'Indikator' => 'indikator_kinerja',
        'Program' => 'program',
        'Kegiatan' => 'kegiatan',
        'Sub Kegiatan' => 'sub_kegiatan',
        'Target Tahunan' => 'target',
        'Satuan' => 'satuan',
        'Pagu Tahunan' => 'pagu_anggaran',
        'tahun' => 'tahun',
    ];

    public function backup(): BinaryFileResponse|JsonResponse
    {
        $connection = config('database.connections.' . config('database.default'));

        if (($connection['driver'] ?? null) !== 'mysql') {
            return response()->json([
                'success' => false,
                'message' => 'Backup SQL saat ini hanya tersedia untuk database MySQL.',
            ], 422);
        }

        $directory = storage_path('app/private/backups');
        if (!is_dir($directory) && !mkdir($directory, 0755, true) && !is_dir($directory)) {
            return response()->json(['success' => false, 'message' => 'Folder backup tidak dapat dibuat.'], 500);
        }

        $filename = 'sipeka-backup-' . now()->format('Ymd-His') . '.sql';
        $path = $directory . DIRECTORY_SEPARATOR . $filename;
        try {
            // Tidak menggunakan mysqldump/proc_open. Shared hosting umumnya
            // memblokir shell, tetapi koneksi database Laravel tetap tersedia.
            $this->writeSqlBackup($path);
        } catch (\Throwable $exception) {
            @unlink($path);
            report($exception);
            return response()->json([
                'success' => false,
                'message' => 'Backup database gagal dibuat. Periksa izin folder storage dan koneksi database.',
            ], 500);
        }

        return response()->download($path, $filename, ['Content-Type' => 'application/sql'])
            ->deleteFileAfterSend(true);
    }

    /**
     * Create a MySQL-restorable schema and data dump without shell access.
     */
    private function writeSqlBackup(string $path): void
    {
        $handle = fopen($path, 'wb');
        if ($handle === false) {
            throw new \RuntimeException('File backup tidak dapat dibuat.');
        }

        try {
            fwrite($handle, "-- SIPEKA database backup\n");
            fwrite($handle, '-- Dibuat: ' . now()->toDateTimeString() . "\n\n");
            fwrite($handle, "SET NAMES utf8mb4;\nSET FOREIGN_KEY_CHECKS=0;\n\n");

            $tables = array_map(
                fn ($row) => array_values((array) $row)[0],
                DB::select('SHOW TABLES')
            );

            foreach ($tables as $table) {
                $quotedTable = $this->quoteIdentifier($table);
                $create = DB::selectOne("SHOW CREATE TABLE {$quotedTable}");
                $createStatement = array_values((array) $create)[1] ?? null;
                if (!$createStatement) {
                    throw new \RuntimeException("Struktur tabel {$table} tidak dapat dibaca.");
                }

                fwrite($handle, "DROP TABLE IF EXISTS {$quotedTable};\n");
                fwrite($handle, $createStatement . ";\n\n");

                $rows = DB::select("SELECT * FROM {$quotedTable}");
                if (empty($rows)) {
                    continue;
                }

                $columns = array_keys((array) $rows[0]);
                $quotedColumns = implode(', ', array_map($this->quoteIdentifier(...), $columns));
                foreach (array_chunk($rows, 200) as $chunk) {
                    $values = array_map(function ($row) {
                        return '(' . implode(', ', array_map(
                            fn ($value) => $this->quoteSqlValue($value),
                            array_values((array) $row)
                        )) . ')';
                    }, $chunk);
                    fwrite($handle, "INSERT INTO {$quotedTable} ({$quotedColumns}) VALUES\n");
                    fwrite($handle, implode(",\n", $values) . ";\n");
                }
                fwrite($handle, "\n");
            }

            fwrite($handle, "SET FOREIGN_KEY_CHECKS=1;\n");
        } finally {
            fclose($handle);
        }
    }

    private function quoteIdentifier(string $identifier): string
    {
        return '`' . str_replace('`', '``', $identifier) . '`';
    }

    private function quoteSqlValue(mixed $value): string
    {
        if ($value === null) {
            return 'NULL';
        }

        $escaped = str_replace(
            ["\\", "\0", "\n", "\r", "\x1a", "'"],
            ["\\\\", "\\0", "\\n", "\\r", "\\Z", "\\'"],
            (string) $value
        );

        return "'{$escaped}'";
    }

    public function previewKegiatanCleanup(Request $request): JsonResponse
    {
        $validated = $request->validate(['tahun' => 'required|integer|min:2020|max:2099']);
        $ids = Kegiatan::where('tahun', $validated['tahun'])->pluck('id');

        return response()->json([
            'success' => true,
            'data' => [
                'tahun' => (int) $validated['tahun'],
                'kegiatan' => $ids->count(),
                'realisasi_fisik' => DB::table('realisasi_fisik')->whereIn('kegiatan_id', $ids)->count(),
                'realisasi_anggaran' => DB::table('realisasi_anggaran')->whereIn('kegiatan_id', $ids)->count(),
                'keterangan_kegiatan' => DB::table('keterangan_kegiatan')->whereIn('kegiatan_id', $ids)->count(),
                'bukti_kegiatan' => DB::table('bukti_kegiatan')->whereIn('kegiatan_id', $ids)->count(),
            ],
        ]);
    }

    public function deleteKegiatanByYear(Request $request): JsonResponse
    {
        $validated = $request->validate(['tahun' => 'required|integer|min:2020|max:2099']);
        $kegiatan = Kegiatan::where('tahun', $validated['tahun'])->get(['id']);
        $ids = $kegiatan->pluck('id');
        $paths = BuktiKegiatan::whereIn('kegiatan_id', $ids)->pluck('file_path')->filter()->all();

        DB::transaction(function () use ($ids) {
            // Foreign keys in the schema delete realisasi, keterangan and bukti.
            Kegiatan::whereIn('id', $ids)->delete();
        });

        foreach ($paths as $path) {
            Storage::disk('public')->delete($path);
        }

        return response()->json([
            'success' => true,
            'message' => "{$ids->count()} kegiatan tahun {$validated['tahun']} beserta data turunannya telah dihapus.",
            'data' => ['kegiatan_deleted' => $ids->count()],
        ]);
    }

    public function previewUndanganCleanup(Request $request): JsonResponse
    {
        $years = $this->retentionYears($request);
        $cutoff = now()->subYears($years)->startOfDay();
        $query = Undangan::whereDate('tanggal', '<', $cutoff);

        return response()->json([
            'success' => true,
            'data' => [
                'years' => $years,
                'cutoff' => $cutoff->toDateString(),
                'undangan' => (clone $query)->count(),
                'bukti' => (clone $query)->whereNotNull('bukti')->count(),
            ],
        ]);
    }

    public function deleteOldUndangan(Request $request): JsonResponse
    {
        $years = $this->retentionYears($request);
        $cutoff = now()->subYears($years)->startOfDay();
        $undangan = Undangan::whereDate('tanggal', '<', $cutoff)->get(['id', 'bukti']);

        DB::transaction(function () use ($undangan) {
            Undangan::whereIn('id', $undangan->pluck('id'))->delete();
        });

        foreach ($undangan->pluck('bukti')->filter() as $path) {
            Storage::disk('public')->delete($path);
        }

        return response()->json([
            'success' => true,
            'message' => "{$undangan->count()} undangan sebelum {$cutoff->format('d-m-Y')} telah dihapus.",
            'data' => ['undangan_deleted' => $undangan->count(), 'years' => $years],
        ]);
    }

    public function importKegiatan(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx|max:10240',
        ]);

        try {
            $spreadsheet = IOFactory::load($request->file('file')->getRealPath());
            // Ambil nilai mentah sel, bukan nilai yang sudah diformat Excel.
            // Dengan format tampilan, contoh 15000000 dapat terbaca sebagai
            // "Rp15.000.000" pada sebagian server dan gagal validasi numeric.
            $rows = $spreadsheet->getActiveSheet()->toArray(null, true, false, false);
        } catch (\Throwable $exception) {
            report($exception);
            return response()->json(['success' => false, 'message' => 'File Excel tidak dapat dibaca.'], 422);
        }

        $headerRow = $this->findHeaderRow($rows);
        if ($headerRow === null) {
            return response()->json([
                'success' => false,
                'message' => 'Header template tidak ditemukan. Gunakan template kegiatan yang disediakan.',
            ], 422);
        }

        $headerMap = $this->headerMap($rows[$headerRow]);
        $errors = [];
        $payload = [];

        foreach (array_slice($rows, $headerRow + 1) as $offset => $row) {
            if ($this->isBlankRow($row)) {
                continue;
            }

            $excelRow = $headerRow + $offset + 2;
            $item = [];
            foreach (self::IMPORT_HEADERS as $header => $field) {
                $item[$field] = trim((string) ($row[$headerMap[$header]] ?? ''));
            }
            $item['target'] = $this->numberValue($row[$headerMap['Target Tahunan']] ?? null);
            $item['pagu_anggaran'] = $this->numberValue($row[$headerMap['Pagu Tahunan']] ?? null);
            $item['tahun'] = $this->numberValue($row[$headerMap['tahun']] ?? null);

            $validator = Validator::make($item, [
                'sasaran_strategis' => 'required|string',
                'indikator_kinerja' => 'required|string',
                'satuan' => 'required|string|max:50',
                'target' => 'required|numeric|min:0',
                'tahun' => 'required|integer|digits:4|min:2020|max:2099',
                'bidang' => 'required|string|max:100',
                'program' => 'required|string',
                'kegiatan' => 'required|string',
                'sub_kegiatan' => 'required|string',
                'pagu_anggaran' => 'required|numeric|min:0',
            ]);

            if ($validator->fails()) {
                $errors[] = ['row' => $excelRow, 'messages' => $validator->errors()->all()];
            } else {
                $payload[] = $item;
            }
        }

        if (count($payload) > 5000) {
            return response()->json(['success' => false, 'message' => 'Maksimal 5.000 baris per impor.'], 422);
        }
        if (!empty($errors)) {
            $firstError = $errors[0];
            return response()->json([
                'success' => false,
                'message' => 'Impor dibatalkan. Baris ' . $firstError['row'] . ': ' . implode(', ', $firstError['messages']),
                'errors' => array_slice($errors, 0, 50),
                'error_count' => count($errors),
            ], 422);
        }
        if (empty($payload)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada baris kegiatan yang terisi pada file Excel.',
            ], 422);
        }

        $now = now();
        $payload = array_map(fn ($item) => [...$item, 'created_at' => $now, 'updated_at' => $now], $payload);
        $bidangNames = collect($payload)->pluck('bidang')->unique()->values();
        $existingBidang = Bidang::whereIn('nama', $bidangNames)->pluck('nama');
        $newBidang = $bidangNames->diff($existingBidang)->values();

        DB::transaction(function () use ($payload, $newBidang, $now) {
            // Import dijalankan Admin. Bidang yang baru muncul pada template
            // dijadikan master agar seluruh baris template dapat disimpan.
            if ($newBidang->isNotEmpty()) {
                Bidang::insert($newBidang->map(fn ($nama) => [
                    'nama' => $nama,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])->all());
            }

            Kegiatan::insert($payload);
        });

        return response()->json([
            'success' => true,
            'message' => count($payload) . ' kegiatan berhasil diimpor.',
            'data' => [
                'imported' => count($payload),
                'bidang_created' => $newBidang->count(),
            ],
        ], 201);
    }

    private function retentionYears(Request $request): int
    {
        return (int) $request->validate(['years' => 'required|integer|min:1|max:50'])['years'];
    }

    private function findHeaderRow(array $rows): ?int
    {
        foreach ($rows as $index => $row) {
            $headers = array_map(fn ($value) => $this->normalizeHeader($value), $row);
            $needed = array_map(fn ($header) => $this->normalizeHeader($header), array_keys(self::IMPORT_HEADERS));
            if (empty(array_diff($needed, $headers))) {
                return $index;
            }
        }
        return null;
    }

    private function headerMap(array $row): array
    {
        $map = [];
        foreach (self::IMPORT_HEADERS as $header => $_field) {
            $needle = $this->normalizeHeader($header);
            foreach ($row as $index => $value) {
                if ($this->normalizeHeader($value) === $needle) {
                    $map[$header] = $index;
                    break;
                }
            }
        }
        return $map;
    }

    private function normalizeHeader(mixed $value): string
    {
        return mb_strtolower(trim(preg_replace('/\s+/', ' ', (string) $value)));
    }

    private function isBlankRow(array $row): bool
    {
        return collect($row)->every(fn ($value) => $value === null || trim((string) $value) === '');
    }

    private function numberValue(mixed $value): mixed
    {
        if (is_numeric($value)) {
            return $value;
        }
        return str_replace(['.', ','], ['', '.'], trim((string) $value));
    }
}
