// lib/screens/kegiatan/input_realisasi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/kegiatan_model.dart';
import '../../models/realisasi_model.dart';
import '../../providers/dio_provider.dart';
import '../../providers/kegiatan_provider.dart';
import '../../providers/realisasi_provider.dart';

class InputRealisasiScreen extends StatefulWidget {
  const InputRealisasiScreen({super.key});

  @override
  State<InputRealisasiScreen> createState() => _InputRealisasiScreenState();
}

class _InputRealisasiScreenState extends State<InputRealisasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fisikCtrl = TextEditingController();
  final _anggaranCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  bool _formVisible = false; // form hanya tampil setelah bulan dipilih
  PlatformFile? _selectedBuktiFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kp = context.read<KegiatanProvider>();
      final rp = context.read<RealisasiProvider>();
      if (kp.selected != null) {
        rp.loadRealisasi(kp.selected!.id);
      }
    });
  }

  @override
  void dispose() {
    _fisikCtrl.dispose();
    _anggaranCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  // ── Saat bulan dipilih: auto-fill form jika ada data ─────────────────────
  void _onBulanSelected(int bulanIndex, RealisasiProvider rp) {
    rp.selectBulan(bulanIndex);
    final data = rp.selectedBulanData;
    print(
      'Bulan $bulanIndex dipilih. Data: fisik=${data?.fisik}, anggaran=${data?.anggaran}, keterangan=${data?.keterangan}, bukti=${data?.bukti != null ? 'ada' : 'tidak ada'}',
    );

    if (data != null && data.hasData) {
      // Ada data → isi form dengan nilai yang sudah tersimpan
      _fisikCtrl.text = data.fisik != null
          ? data.fisik!.toStringAsFixed(data.fisik! % 1 == 0 ? 0 : 2)
          : '';
      _anggaranCtrl.text =
          data.anggaran != null ? data.anggaran!.toStringAsFixed(0) : '';
      _catatanCtrl.text = data.keterangan ?? '';
    } else {
      // Belum ada data → form kosong
      _fisikCtrl.clear();
      _anggaranCtrl.clear();
      _catatanCtrl.clear();
    }

    setState(() {
      _formVisible = true;
      _selectedBuktiFile = null;
    });
  }

  Future<void> _pickBuktiFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'jpeg'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      if (!mounted) return;
      AppUtils.showError(context, 'Ukuran file maksimal 5 MB.');
      return;
    }

    if (file.bytes == null) {
      if (!mounted) return;
      AppUtils.showError(context, 'File tidak bisa dibaca. Coba pilih ulang.');
      return;
    }

    setState(() => _selectedBuktiFile = file);
  }

  void _clearSelectedBukti() {
    setState(() => _selectedBuktiFile = null);
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final rp = context.read<RealisasiProvider>();
    final kp = context.read<KegiatanProvider>();
    final kegiatan = kp.selected;
    if (kegiatan == null || rp.selectedBulan == null) return;
    if (!kegiatan.canManage) {
      AppUtils.showError(
        context,
        'Anda hanya bisa melihat realisasi kegiatan bidang lain.',
      );
      return;
    }

    final fisikVal = double.tryParse(_fisikCtrl.text.replaceAll(',', '.')) ?? 0;
    final anggaranVal =
        double.tryParse(_anggaranCtrl.text.replaceAll('.', '')) ?? 0;

    final buktiFile = _selectedBuktiFile;

    final ok = await rp.submitRealisasi(
      kegiatanId: kegiatan.id,
      bulan: rp.selectedBulan!,
      realisasiFisik: fisikVal,
      realisasiAnggaran: anggaranVal,
      keterangan:
          _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
    );

    if (!mounted) return;
    var finalOk = ok;
    if (ok && buktiFile != null) {
      finalOk = await rp.uploadBukti(
        kegiatanId: kegiatan.id,
        bulan: rp.selectedBulan!,
        fileName: buktiFile.name,
        fileBytes: buktiFile.bytes!,
      );
    }

    if (!mounted) return;
    if (finalOk) {
      if (buktiFile != null) _clearSelectedBukti();
      AppUtils.showSuccess(
        context,
        rp.successMessage ?? 'Realisasi berhasil disimpan.',
      );
      // Refresh detail kegiatan juga
      await kp.loadKegiatanDetail(kegiatan.id);
    } else {
      AppUtils.showError(
        context,
        rp.errorMessage ?? 'Gagal menyimpan realisasi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kp = context.watch<KegiatanProvider>();
    final rp = context.watch<RealisasiProvider>();
    final kegiatan = kp.selected;
    final canManage = kegiatan?.canManage ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.inputRealisasi)),
      body: rp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Banner kegiatan ───────────────────────────────────────
                if (kegiatan != null) _KegiatanBanner(kegiatan: kegiatan),
                const SizedBox(height: 16),

                // ── Sisa realisasi keseluruhan ────────────────────────────
                if (rp.realisasiKegiatan != null && kegiatan != null)
                  _RealisasiSummaryCard(kegiatan: kegiatan),
                const SizedBox(height: 16),

                // ── Step 1: Pilih bulan ───────────────────────────────────
                const _StepLabel(
                  step: '1',
                  label: 'Pilih Bulan Realisasi',
                  isActive: true,
                ),
                const SizedBox(height: 10),
                _BulanGrid(
                  realisasi: rp.realisasiKegiatan,
                  selectedBulan: rp.selectedBulan,
                  onSelect: (b) => _onBulanSelected(b, rp),
                ),
                const SizedBox(height: 20),

                // ── Step 2: Form isi data (tampil setelah bulan dipilih) ──
                if (_formVisible && rp.selectedBulan != null) ...[
                  _StepLabel(
                    step: '2',
                    label: 'Isi Data Realisasi — '
                        '${AppMonths.list[(rp.selectedBulan ?? 1) - 1]}',
                    isActive: true,
                  ),
                  const SizedBox(height: 12),

                  // Badge jika sedang edit data yang sudah ada
                  if (rp.selectedBulanData != null &&
                      rp.selectedBulanData!.hasData)
                    _EditBadge(
                      bulan: AppMonths.list[(rp.selectedBulan ?? 1) - 1],
                    ),
                  if (!canManage) const _ReadOnlyBadge(),
                  const SizedBox(height: 12),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Realisasi Fisik ──────────────────────────────
                        _FormSection(
                          label:
                              'Realisasi Fisik (${kegiatan?.satuan ?? 'unit'})',
                          hint: 'Persentase fisik yang sudah tercapai',
                          child: TextFormField(
                            controller: _fisikCtrl,
                            readOnly: !canManage,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Contoh: 75',
                              suffixText: '%',
                              suffixStyle: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Realisasi fisik wajib diisi';
                              }
                              final val = double.tryParse(
                                v.replaceAll(',', '.'),
                              );
                              if (val == null) return 'Angka tidak valid';
                              if (val < 0 || val > 100) {
                                return 'Nilai 0 – 100';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Realisasi Anggaran ───────────────────────────
                        _FormSection(
                          label: 'Realisasi Anggaran (Rp)',
                          hint:
                              'Nominal anggaran yang sudah terpakai bulan ini',
                          child: TextFormField(
                            controller: _anggaranCtrl,
                            readOnly: !canManage,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Contoh: 5000000',
                              prefixText: 'Rp ',
                              prefixStyle: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Realisasi anggaran wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Keterangan ───────────────────────────────────
                        _FormSection(
                          label: 'Keterangan',
                          hint: 'Opsional — catatan kendala atau progres',
                          child: TextFormField(
                            controller: _catatanCtrl,
                            readOnly: !canManage,
                            maxLines: 3,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText:
                                  'Contoh: Pengadaan material sudah selesai...',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Bukti yang sudah ada ─────────────────────────
                        _FormSection(
                          label: 'File Bukti',
                          hint: rp.selectedBulanData?.bukti == null
                              ? 'Opsional, PDF/JPG/PNG maksimal 5 MB'
                              : 'Pilih file baru jika ingin mengganti bukti lama',
                          child: _BuktiPickerCard(
                            selectedFile: _selectedBuktiFile,
                            existingBukti: rp.selectedBulanData?.bukti,
                            onPick: rp.isSubmitting || !canManage
                                ? null
                                : _pickBuktiFile,
                            onClear: rp.isSubmitting || !canManage
                                ? null
                                : _clearSelectedBukti,
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (rp.selectedBulanData?.bukti != null)
                          _BuktiCard(bukti: rp.selectedBulanData!.bukti!),
                        const SizedBox(height: 8),

                        // ── Tombol simpan ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed:
                                rp.isSubmitting || !canManage ? null : _submit,
                            icon: rp.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 18),
                            label: Text(
                              rp.isSubmitting
                                  ? 'Menyimpan...'
                                  : (!canManage
                                      ? 'Hanya Lihat Data'
                                      : _selectedBuktiFile != null
                                          ? 'Simpan & Unggah Bukti'
                                          : (rp.selectedBulanData != null &&
                                                  rp.selectedBulanData!.hasData
                                              ? 'Perbarui Realisasi'
                                              : 'Simpan Realisasi')),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ─── Kegiatan Banner ─────────────────────────────────────────────────────────

class _KegiatanBanner extends StatelessWidget {
  final dynamic kegiatan;
  const _KegiatanBanner({required this.kegiatan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kegiatan.nama,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${kegiatan.bidang} · ${kegiatan.tahun}',
            style: const TextStyle(fontSize: 11, color: AppColors.primaryMid),
          ),
          Text(
            'pagu : ${AppUtils.formatCurrencyCompact(kegiatan.anggaran)} · '
            'target : ${kegiatan.target} ${kegiatan.satuan}',
            style: const TextStyle(fontSize: 11, color: AppColors.primaryMid),
          ),
        ],
      ),
    );
  }
}

// ─── Ringkasan Realisasi Card ─────────────────────────────────────────────────

class _RealisasiSummaryCard extends StatelessWidget {
  final KegiatanModel kegiatan;
  const _RealisasiSummaryCard({required this.kegiatan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Sisa Realisasi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Sisa Anggaran',
                  value: 'Rp. ${kegiatan.sisaAnggaran}',
                  color: AppColors.primaryMid,
                ),
              ),
              Container(width: 0.5, height: 36, color: AppColors.border),
              Expanded(
                child: _SummaryItem(
                  label: 'Sisa Target',
                  value:
                      '${kegiatan.sisaTarget.toStringAsFixed(2)} ${kegiatan.satuan}',
                  color: AppUtils.progressColor(kegiatan.sisaTarget),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ─── Step Label ───────────────────────────────────────────────────────────────

class _StepLabel extends StatelessWidget {
  final String step;
  final String label;
  final bool isActive;
  const _StepLabel({
    required this.step,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bulan Grid ───────────────────────────────────────────────────────────────

class _BulanGrid extends StatelessWidget {
  final RealisasiKegiatan? realisasi;
  final int? selectedBulan;
  final ValueChanged<int> onSelect;

  const _BulanGrid({
    required this.realisasi,
    required this.selectedBulan,
    required this.onSelect,
  });

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ags',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: 12,
      itemBuilder: (ctx, i) {
        final bulanIndex = i + 1;
        final isSelected = selectedBulan == bulanIndex;
        final bulanData = realisasi?.getBulan(bulanIndex);
        final hasData = bulanData?.hasData ?? false;

        return GestureDetector(
          onTap: () => onSelect(bulanIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : hasData
                      ? AppColors.successLight
                      : AppColors.surfaceGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : hasData
                        ? AppColors.success
                        : AppColors.border,
                width: isSelected ? 0 : 0.75,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _months[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : hasData
                            ? AppColors.success
                            : AppColors.textSecondary,
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 2),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 10,
                    color: isSelected
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.success,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Edit Badge ───────────────────────────────────────────────────────────────

class _EditBadge extends StatelessWidget {
  final String bulan;
  const _EditBadge({required this.bulan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A), width: 0.75),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, size: 14, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data bulan $bulan sudah ada — form terisi otomatis. '
              'Ubah data dan Simpan untuk mengedit.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form Section Wrapper ─────────────────────────────────────────────────────

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.75),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kegiatan ini bukan bidang Anda. Data bisa dilihat, tetapi tidak bisa disimpan.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _FormSection({required this.label, required this.child, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Bukti Card ───────────────────────────────────────────────────────────────

class _BuktiPickerCard extends StatelessWidget {
  final PlatformFile? selectedFile;
  final BuktiDetail? existingBukti;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  const _BuktiPickerCard({
    required this.selectedFile,
    required this.existingBukti,
    required this.onPick,
    required this.onClear,
  });

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final file = selectedFile;
    final hasExisting = existingBukti != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.75),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: file != null
                  ? AppColors.primaryLight
                  : (hasExisting
                      ? const Color(0xFFECFDF5)
                      : AppColors.surfaceGray),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              file != null
                  ? Icons.upload_file_rounded
                  : (hasExisting
                      ? Icons.verified_rounded
                      : Icons.note_add_rounded),
              color: file != null
                  ? AppColors.primary
                  : (hasExisting ? AppColors.success : AppColors.textMuted),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file?.name ??
                      (hasExisting
                          ? 'Bukti lama tersedia'
                          : 'Belum ada file bukti'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  file != null
                      ? '${_formatSize(file.size)} - akan diunggah saat disimpan'
                      : (hasExisting
                          ? 'Kosongkan jika tidak ingin mengganti file.'
                          : 'Lampirkan file pendukung realisasi.'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (file != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Batal pilih file',
              visualDensity: VisualDensity.compact,
            )
          else
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.attach_file_rounded, size: 14),
              label: const Text('Pilih', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
            ),
        ],
      ),
    );
  }
}

class _BuktiCard extends StatelessWidget {
  final BuktiDetail bukti;
  const _BuktiCard({required this.bukti});

  String? _fileUrlForDevice() {
    final url = bukti.fileUrl;
    if (url == null || url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return url;

    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      final apiUri = Uri.parse(DioProvider.baseApiUrl);
      return uri
          .replace(
            scheme: apiUri.scheme,
            host: apiUri.host,
            port: apiUri.hasPort ? apiUri.port : null,
          )
          .toString();
    }

    return url;
  }

  Future<void> _openFile(BuildContext context) async {
    final url = _fileUrlForDevice();
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL file tidak tersedia')));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      var opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka file: $url')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka file: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = _fileUrlForDevice();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 6),
                Text(
                  'Bukti Pendukung Tersimpan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // File info + open button
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // File icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bukti.isPdf
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    bukti.isPdf
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    color: bukti.isPdf ? AppColors.danger : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // File name & type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bukti.fileName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        bukti.isPdf ? 'Dokumen PDF' : 'Gambar',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Open button
                OutlinedButton.icon(
                  onPressed: () => _openFile(context),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Buka', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),

          // Direct URL jika ada
          if (fileUrl != null) ...[
            const Divider(height: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 13,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fileUrl,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryMid,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: fileUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL disalin ke clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
