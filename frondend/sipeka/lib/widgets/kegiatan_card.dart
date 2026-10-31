// lib/widgets/kegiatan_card.dart

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_utils.dart';
import '../models/kegiatan_model.dart';

class KegiatanCard extends StatelessWidget {
  final KegiatanModel kegiatan;
  final VoidCallback? onTap;
  final bool compact;

  const KegiatanCard({
    super.key,
    required this.kegiatan,
    this.onTap,
    this.compact = false,
  });

  Color get _accentColor => AppUtils.progressColor(kegiatan.progressFisik);

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;
    final titleColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: borderColor,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            // Accent line kiri
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(13),
                    bottomLeft: Radius.circular(13),
                  ),
                ),
              ),
            ),

            // Content utama (punya ripple effect)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              kegiatan.nama,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),

                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _BidangBadge(bidang: kegiatan.bidang),
                          if (!compact)
                            _YearBadge(year: kegiatan.tahun.toString()),
                        ],
                      ),

                      if (!compact) ...[
                        const SizedBox(height: 10),
                        _ProgressMiniRow(
                          label: 'Fisik',
                          value: kegiatan.totalRealisasiFisik,
                          target: kegiatan.target,
                          color: _accentColor,
                        ),
                        const SizedBox(height: 5),
                        _ProgressMiniRow(
                          label: 'Anggaran',
                          value: kegiatan.totalRealisasiAnggaran,
                          target: kegiatan.paguAnggaran,
                          color: AppColors.primaryMid,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        _ProgressMiniRow(
                          label: 'Fisik',
                          value: kegiatan.totalRealisasiFisik,
                          target: kegiatan.target,
                          color: _accentColor,
                        ),
                      ],

                      if (!compact) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              kegiatan.sisaAnggaran > 0
                                  ? 'Sisa: ${AppUtils.formatCurrencyCompact(kegiatan.sisaAnggaran)}'
                                  : 'Anggaran sudah terpakai',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              AppUtils.formatCurrencyCompact(
                                  kegiatan.paguAnggaran),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProgressMiniRow extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;

  const _ProgressMiniRow({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  double get _percentage =>
      target > 0 ? (value / target * 100).clamp(0.0, 100.0).toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (_percentage / 100).clamp(0.0, 1.0).toDouble(),
              minHeight: 5,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(
            '${_percentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
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

class _BidangBadge extends StatelessWidget {
  final String bidang;
  const _BidangBadge({required this.bidang});

  _BadgeStyle get _style {
    switch (bidang) {
      case 'Perencanaan dan Keuangan':
        return _BadgeStyle(
            bg: const Color(0xFFEFF6FF), fg: AppColors.primaryDark);
      case 'Umum dan Kepgawaian':
        return _BadgeStyle(
            bg: const Color(0xFFF0FDF4), fg: const Color(0xFF166534));
      case 'Perlindungan dan Jaminan Sosial':
        return _BadgeStyle(
            bg: const Color(0xFFFFF7ED), fg: const Color(0xFF92400E));
      case 'Rehabilitasi Sosial':
        return _BadgeStyle(
            bg: const Color(0xFFFDF4FF), fg: const Color(0xFF6B21A8));
      case 'Pemberdayaan Sosial':
        return _BadgeStyle(
            bg: const Color(0xFFECFEFF), fg: const Color(0xFF155E75));
      case 'Pemberdayaan Masyarakat':
        return _BadgeStyle(
            bg: const Color(0xFFECFEFF),
            fg: const Color.fromARGB(255, 103, 117, 21));
      default:
        return _BadgeStyle(bg: AppColors.surfaceGray, fg: AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Badge(label: bidang, bg: _style.bg, fg: _style.fg);
  }
}

// class _StatusBadge extends StatelessWidget {
//   final KegiatanStatus status;
//   const _StatusBadge({required this.status});

//   @override
//   Widget build(BuildContext context) {
//     Color bg, fg;
//     String label;
//     switch (status) {
//       case KegiatanStatus.onTrack:
//         bg = AppColors.successLight;
//         fg = const Color(0xFF166534);
//         label = 'On Track';
//         break;
//       case KegiatanStatus.atRisk:
//         bg = AppColors.warningLight;
//         fg = const Color(0xFF92400E);
//         label = 'At Risk';
//         break;
//       case KegiatanStatus.selesai:
//         bg = AppColors.primaryLight;
//         fg = AppColors.primaryDark;
//         label = 'Selesai';
//         break;
//     }
//     return _Badge(label: label, bg: bg, fg: fg);
//   }
// }

class _YearBadge extends StatelessWidget {
  final String year;
  const _YearBadge({required this.year});

  @override
  Widget build(BuildContext context) {
    return _Badge(
        label: year, bg: AppColors.surfaceGray, fg: AppColors.textMuted);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

class _BadgeStyle {
  final Color bg;
  final Color fg;
  _BadgeStyle({required this.bg, required this.fg});
}
