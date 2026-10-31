// lib/screens/kegiatan/detail_kegiatan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/models/kegiatan_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/kegiatan_provider.dart';
import '../../widgets/progress_bar.dart';

class DetailKegiatanScreen extends StatefulWidget {
  const DetailKegiatanScreen({super.key});

  @override
  State<DetailKegiatanScreen> createState() => _DetailKegiatanScreenState();
}

class _DetailKegiatanScreenState extends State<DetailKegiatanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kp = context.read<KegiatanProvider>();
      if (kp.selected != null) {
        // ✅ Fetch detail lengkap termasuk realisasi_fisik per bulan
        kp.loadKegiatanDetail(kp.selected!.id);
      }
    });
  }

  void _showTriwulanDialog(BuildContext context, KegiatanModel kegiatan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TriwulanSheet(kegiatan: kegiatan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kegiatan = context.watch<KegiatanProvider>().selected;
    print(
        "kegiatan: $kegiatan. Detail: ${kegiatan != null ? kegiatan.realisasiBulanan : 'null'}");
    if (kegiatan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.detailKegiatan)),
        body: Center(
          child: Text('Data tidak tersedia.',
              style: TextStyle(color: AppTheme.textMutedOf(context))),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.detailKegiatan)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ─────────────────────────────────────────────────
            _HeaderCard(kegiatan: kegiatan),
            const SizedBox(height: 12),

            // ── Info Table ───────────────────────────────────────────────────
            _InfoCard(
              title: 'Informasi Kegiatan',
              rows: [
                _InfoRow('Sasaran Strategis', kegiatan.sasaranStrategis),
                _InfoRow('Indikator', kegiatan.indikatorKinerja),
                _InfoRow('Program', kegiatan.program),
                _InfoRow('Kegiatan', kegiatan.kegiatan),
                _InfoRow('Sub Kegiatan', kegiatan.subKegiatan),
                _InfoRow('Target Fisik',
                    '${kegiatan.target.toStringAsFixed(2)} ${kegiatan.satuan}'),
                _InfoRow('Realisasi Fisik',
                    '${kegiatan.totalRealisasiFisik.toStringAsFixed(2)} ${kegiatan.satuan}'),
                _InfoRow('Sisa Target',
                    '${kegiatan.sisaTarget.toStringAsFixed(2)} ${kegiatan.satuan}'),
                _InfoRow('Pagu Anggaran',
                    AppUtils.formatCurrency(kegiatan.paguAnggaran)),
                _InfoRow('Realisasi Anggaran',
                    AppUtils.formatCurrency(kegiatan.totalRealisasiAnggaran)),
                _InfoRow('Sisa Anggaran',
                    AppUtils.formatCurrency(kegiatan.sisaAnggaran)),
                _InfoRow('Pelaksana', kegiatan.bidang),
                _InfoRow('Tahun Anggaran', kegiatan.tahun.toString()),
              ],
            ),
            const SizedBox(height: 12),

            // ── Progress Card ────────────────────────────────────────────────
            _Card(
              title: 'Capaian Realisasi',
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  AppProgressBar(
                    label: 'Realisasi Fisik',
                    target: kegiatan.target,
                    value: kegiatan.totalRealisasiFisik,
                  ),
                  AppProgressBar(
                    label: 'Realisasi Anggaran',
                    target: kegiatan.paguAnggaran,
                    value: kegiatan.totalRealisasiAnggaran,
                    color: AppColors.primaryMid,
                  ),
                  // Status pill
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Monthly Chart ─────────────────────────────────────────────────
            if ((kegiatan.realisasiBulanan).isNotEmpty) ...[
              _Card(
                title: 'Realisasi Fisik per Bulan (${kegiatan.satuan})',
                child: _MonthlyBarChart(data: kegiatan.realisasiBulanan),
              ),
              const SizedBox(height: 12),
            ],

            // ── CTA ───────────────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => _showTriwulanDialog(context, kegiatan),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text('Lihat Detail Triwulan',
                  style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.inputRealisasi),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Input Realisasi',
                    style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Header Card ─────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final KegiatanModel kegiatan;
  const _HeaderCard({required this.kegiatan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.borderOf(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kegiatan.nama,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryOf(context),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: [
              _Chip(
                  label: kegiatan.bidang,
                  bg: AppColors.primaryLight,
                  fg: AppColors.primaryDark),
              _Chip(
                  label: kegiatan.tahun.toString(),
                  bg: AppTheme.surfaceGrayOf(context),
                  fg: AppTheme.textMutedOf(context)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

// ─── Generic Card wrapper ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.borderOf(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Info Table Card ──────────────────────────────────────────────────────────

class _InfoRow {
  final String key;
  final String value;
  _InfoRow(this.key, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.borderOf(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
          ),
          const Divider(height: 0),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                            color: AppTheme.borderOf(context), width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(e.value.key,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedOf(context))),
                  ),
                  Expanded(
                    child: Text(
                      e.value.value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Monthly Bar Chart ────────────────────────────────────────────────────────

class _MonthlyBarChart extends StatefulWidget {
  final List data;
  const _MonthlyBarChart({required this.data});

  @override
  State<_MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<_MonthlyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  final _months = [
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
    'Des'
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.data.fold<double>(
        1, (prev, e) => e.fisik > prev ? e.fisik.toDouble() : prev);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        height: 90,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: widget.data.map<Widget>((d) {
            final frac = (d.fisik / maxVal) * _anim.value;
            final monthLabel =
                d.bulan >= 1 && d.bulan <= 12 ? _months[d.bulan - 1] : '?';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${d.fisik.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 7.5,
                          color: AppTheme.textMutedOf(context),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                      child: Container(
                        height: 55 * frac.clamp(0.05, 1.0) as double,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthLabel,
                      style: TextStyle(
                          fontSize: 8, color: AppTheme.textMutedOf(context)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Triwulan Sheet ───────────────────────────────────────────────────────────

class _TriwulanSheet extends StatelessWidget {
  final KegiatanModel kegiatan;
  const _TriwulanSheet({required this.kegiatan});

  // Hitung realisasi pada masing-masing triwulan.
  List<_TriwulanData> _buildTriwulan() {
    final bulanan = kegiatan.realisasiBulanan;

    return List.generate(4, (i) {
      final startBulan = i * 3 + 1; // 1, 4, 7, 10
      final endBulan = startBulan + 2; // 3, 6, 9, 12

      final bulanDiTriwulan = bulanan
          .where((b) => b.bulan >= startBulan && b.bulan <= endBulan)
          .toList()
        ..sort((a, b) => a.bulan.compareTo(b.bulan));

      final fisikTriwulan = bulanDiTriwulan.fold<double>(
        0,
        (sum, b) => sum + b.fisik,
      );
      final anggaranTriwulan = bulanDiTriwulan.fold<double>(
        0,
        (sum, b) => sum + b.anggaran,
      );
      // Data per bulan untuk tampilan detail
      final perBulan = List.generate(3, (j) {
        final bulanIdx = startBulan + j;
        final data = bulanDiTriwulan.where((b) => b.bulan == bulanIdx).toList();
        return _BulanItem(
          bulan: bulanIdx,
          fisik: data.isNotEmpty ? data.first.fisik : null,
          anggaran: data.isNotEmpty ? data.first.anggaran : null,
        );
      });

      return _TriwulanData(
        nomor: i + 1,
        fisikTriwulan: fisikTriwulan,
        anggaranTriwulan: anggaranTriwulan,
        perBulan: perBulan,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final triwulanList = _buildTriwulan();
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Handle + Header ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderOf(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Detail Realisasi per Triwulan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded,
                            size: 20, color: AppTheme.textMutedOf(context)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                // Sub info kegiatan
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Text(
                    '${kegiatan.bidang}  ·  Target: ${kegiatan.target.toStringAsFixed(0)} ${kegiatan.satuan}  ·  Pagu: ${AppUtils.formatCurrencyCompact(kegiatan.paguAnggaran)}',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textMutedOf(context)),
                  ),
                ),
                const Divider(height: 0),
              ],
            ),
          ),

          // ── Ringkasan kumulatif + daftar triwulan ──────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AkumulasiRealisasiCard(kegiatan: kegiatan),
                const SizedBox(height: 20),
                Text(
                  'Realisasi per Triwulan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 10),
                ...triwulanList.map(
                  (data) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TriwulanCard(data: data, kegiatan: kegiatan),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Model Triwulan ──────────────────────────────────────────────────────

class _BulanItem {
  final int bulan;
  final double? fisik;
  final double? anggaran;
  _BulanItem({required this.bulan, this.fisik, this.anggaran});
}

class _TriwulanData {
  final int nomor;
  final double fisikTriwulan;
  final double anggaranTriwulan;
  final List<_BulanItem> perBulan;

  _TriwulanData({
    required this.nomor,
    required this.fisikTriwulan,
    required this.anggaranTriwulan,
    required this.perBulan,
  });
}

// ─── Triwulan Card ────────────────────────────────────────────────────────────

class _TriwulanCard extends StatefulWidget {
  final _TriwulanData data;
  final KegiatanModel kegiatan;
  const _TriwulanCard({required this.data, required this.kegiatan});

  @override
  State<_TriwulanCard> createState() => _TriwulanCardState();
}

class _TriwulanCardState extends State<_TriwulanCard> {
  bool _expanded = false;

  static const _namaBulan = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final paguAnggaran = widget.kegiatan.paguAnggaran;
    final persenAnggaran = paguAnggaran > 0
        ? (d.anggaranTriwulan / paguAnggaran * 100).clamp(0.0, 100.0).toDouble()
        : 0.0;
    final persenFisik = widget.kegiatan.target > 0
        ? (d.fisikTriwulan / widget.kegiatan.target * 100)
            .clamp(0.0, 100.0)
            .toDouble()
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppTheme.borderOf(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // ── Header Triwulan ─────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Nomor triwulan
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'Q${d.nomor}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Triwulan ${d.nomor}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryOf(context),
                              ),
                            ),
                            Text(
                              _bulanRange(d.nomor),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMutedOf(context)),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppTheme.textMutedOf(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Realisasi pada triwulan ini saja.
                  _MiniProgressRow(
                    label: 'Fisik',
                    value: persenFisik,
                    color: AppColors.primary,
                    amount: d.fisikTriwulan.toStringAsFixed(1),
                    percentage: '${persenFisik.toStringAsFixed(1)}%',
                  ),
                  const SizedBox(height: 5),
                  _MiniProgressRow(
                    label: 'Anggaran',
                    value: persenAnggaran,
                    color: AppColors.primaryMid,
                    amount: AppUtils.formatCurrencyCompact(d.anggaranTriwulan),
                    percentage: '${persenAnggaran.toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),
          ),

          // ── Detail per Bulan (collapsible) ─────────────────────────────
          if (_expanded) ...[
            const Divider(height: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: d.perBulan.map((b) {
                  final hasB = (b.fisik != null && b.fisik! > 0) ||
                      (b.anggaran != null && b.anggaran! > 0);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: hasB
                          ? AppColors.primaryLight
                          : AppTheme.surfaceGrayOf(context),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: hasB
                            ? const Color(0xFFBFDBFE)
                            : AppTheme.borderOf(context),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Bulan label
                        SizedBox(
                          width: 78,
                          child: Text(
                            b.bulan >= 1 && b.bulan <= 12
                                ? _namaBulan[b.bulan]
                                : '-',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: hasB
                                  ? AppColors.primaryDark
                                  : AppTheme.textMutedOf(context),
                            ),
                          ),
                        ),
                        // Fisik
                        Expanded(
                          child: _BulanStat(
                            label: 'Fisik',
                            value: b.fisik != null
                                ? '${b.fisik!.toStringAsFixed(1)} ${widget.kegiatan.satuan}'
                                : '-',
                            hasData: b.fisik != null && b.fisik! > 0,
                          ),
                        ),
                        // Anggaran
                        Expanded(
                          child: _BulanStat(
                            label: 'Anggaran',
                            value: b.anggaran != null && b.anggaran! > 0
                                ? AppUtils.formatCurrencyCompact(b.anggaran!)
                                : '-',
                            hasData: b.anggaran != null && b.anggaran! > 0,
                            alignRight: true,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _bulanRange(int nomor) {
    const ranges = ['Jan – Mar', 'Apr – Jun', 'Jul – Sep', 'Okt – Des'];
    return ranges[(nomor - 1).clamp(0, 3)];
  }
}

// ─── Akumulasi Realisasi ─────────────────────────────────────────────────────

class _AkumulasiRealisasiCard extends StatelessWidget {
  final KegiatanModel kegiatan;
  const _AkumulasiRealisasiCard({required this.kegiatan});

  @override
  Widget build(BuildContext context) {
    final totalFisik = kegiatan.totalRealisasiFisik;
    final totalAnggaran = kegiatan.totalRealisasiAnggaran;
    final persenFisik = kegiatan.target > 0
        ? (totalFisik / kegiatan.target * 100).clamp(0.0, 100.0).toDouble()
        : 0.0;
    final persenAnggaran = kegiatan.paguAnggaran > 0
        ? (totalAnggaran / kegiatan.paguAnggaran * 100)
            .clamp(0.0, 100.0)
            .toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.borderOf(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akumulasi Realisasi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Total seluruh realisasi yang telah dicatat.',
            style:
                TextStyle(fontSize: 10, color: AppTheme.textMutedOf(context)),
          ),
          const SizedBox(height: 12),
          _MiniProgressRow(
            label: 'Fisik',
            value: persenFisik,
            color: AppColors.primary,
            amount: totalFisik.toStringAsFixed(1),
            percentage: '${persenFisik.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          _MiniProgressRow(
            label: 'Anggaran',
            value: persenAnggaran,
            color: AppColors.primaryMid,
            amount: AppUtils.formatCurrencyCompact(totalAnggaran),
            percentage: '${persenAnggaran.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }
}

// ─── Mini Progress Row ────────────────────────────────────────────────────────

class _MiniProgressRow extends StatelessWidget {
  final String label;
  final double value; // 0–100
  final Color color;
  final String amount;
  final String percentage;

  const _MiniProgressRow({
    required this.label,
    required this.value,
    required this.color,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, color: AppTheme.textMutedOf(context))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0).toDouble(),
              minHeight: 5,
              backgroundColor: AppTheme.borderOf(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 122,
          child: Text(
            '$amount | $percentage',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bulan Stat Cell ──────────────────────────────────────────────────────────

class _BulanStat extends StatelessWidget {
  final String label;
  final String value;
  final bool hasData;
  final bool alignRight;

  const _BulanStat({
    required this.label,
    required this.value,
    this.hasData = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, color: AppTheme.textMutedOf(context)),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasData
                ? AppTheme.textPrimaryOf(context)
                : AppTheme.textMutedOf(context),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    IconData icon;
    switch (status) {
      case 'On Track':
        bg = AppColors.successLight;
        fg = const Color(0xFF166534);
        icon = Icons.check_circle_rounded;
        break;
      case 'Selesai':
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
        icon = Icons.verified_rounded;
        break;
      default:
        bg = AppColors.warningLight;
        fg = const Color(0xFF92400E);
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(status,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
