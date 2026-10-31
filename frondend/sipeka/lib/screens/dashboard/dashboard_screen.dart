// lib/screens/dashboard/dashboard_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kegiatan_provider.dart';
import '../../providers/undangan_provider.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/progress_bar.dart';
import '../../models/kegiatan_model.dart';
import '../../models/undangan_model.dart';
import '../../providers/theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kp = context.read<KegiatanProvider>();
      final up = context.read<UndanganProvider>();
      // ✅ INI YANG KURANG
      kp.loadDashboard();

      if (up.allUndangan.isEmpty) up.loadUndangan();
      up.loadNearestPendingUndangan();
    });
  }

  Future<void> _showHadiriDialog(
    BuildContext context,
    UndanganProvider up,
    UndanganModel undangan,
  ) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final identitasHadir = user?.bidang?.isNotEmpty == true
        ? user!.bidang!
        : user?.username ?? '-';

    bool isDelegasi = false;
    final delegasiCtrl = TextEditingController();
    PlatformFile? selectedBukti;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Konfirmasi Kehadiran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceGrayOf(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.borderOf(context), width: 0.5),
                    ),
                    child: Text(
                      undangan.judul,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DashboardDialogInfoRow(
                    label: 'Dihadiri oleh',
                    value: identitasHadir,
                    icon: Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setS(() => isDelegasi = !isDelegasi),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDelegasi
                                ? AppColors.primary
                                : AppTheme.surfaceOf(context),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDelegasi
                                  ? AppColors.primary
                                  : AppTheme.borderOf(context),
                              width: 1.5,
                            ),
                          ),
                          child: isDelegasi
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Hadir sebagai delegasi',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: isDelegasi
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              const Text(
                                'Keterangan delegasi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: delegasiCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Contoh: perwakilan/delegasi kepala dinas',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bukti kehadiran (opsional)',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        if (result.files.single.size > 5 * 1024 * 1024) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('File maksimal 5 MB'),
                              ),
                            );
                          }
                          return;
                        }
                        setS(() => selectedBukti = result.files.single);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGrayOf(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedBukti != null
                              ? AppColors.success
                              : AppTheme.borderOf(context),
                          width: selectedBukti != null ? 1 : 0.75,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedBukti != null
                                ? Icons.check_circle_rounded
                                : Icons.attach_file_rounded,
                            size: 18,
                            color: selectedBukti != null
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedBukti?.name ?? 'Pilih file bukti...',
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedBukti != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedBukti != null)
                            GestureDetector(
                              onTap: () => setS(() => selectedBukti = null),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Konfirmasi'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await up.konfirmasiHadir(
        id: undangan.id,
        delegasi: isDelegasi && delegasiCtrl.text.trim().isNotEmpty
            ? delegasiCtrl.text.trim()
            : null,
        buktiBytes: selectedBukti?.bytes != null
            ? List<int>.from(selectedBukti!.bytes!)
            : null,
        buktiFileName: selectedBukti?.name,
      );

      if (context.mounted) {
        if (ok) {
          AppUtils.showSuccess(
            context,
            up.lastMessage ?? 'Kehadiran berhasil dikonfirmasi.',
          );
          await up.loadNearestPendingUndangan();
        } else {
          AppUtils.showError(
            context,
            up.errorMessage ?? 'Gagal mengonfirmasi kehadiran.',
          );
        }
        up.clearMessage();
      }
    }

    delegasiCtrl.dispose();
  }

  Future<void> _showTidakHadirDialog(
    BuildContext context,
    UndanganProvider up,
    UndanganModel undangan,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text('Tidak Dapat Hadir'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${undangan.judul}"',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Konfirmasi bahwa Anda tidak dapat hadir dalam undangan ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Konfirmasi'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await up.tandaiTidakHadir(id: undangan.id);
      if (context.mounted) {
        if (ok) {
          AppUtils.showInfo(
            context,
            up.lastMessage ?? 'Undangan ditandai tidak hadir.',
          );
          await up.loadNearestPendingUndangan();
        } else {
          AppUtils.showError(
            context,
            up.errorMessage ?? 'Gagal memperbarui status.',
          );
        }
        up.clearMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kp = context.watch<KegiatanProvider>();
    final up = context.watch<UndanganProvider>();
    final user = auth.user;
    final summary = kp.summary;
    final nearestPending = up.nearestPendingUndangan;

    // dashboard_screen.dart — di dalam build()

    // Jika loading selesai tapi summary masih null, tampilkan pesan
    if (!kp.isLoading && kp.summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data dashboard',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => kp.loadDashboard(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white.withOpacity(0.22),
              child: Text(
                user?.initials ?? 'U',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: kp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await kp.loadDashboard();
                await up.loadUndangan();
                await up.loadNearestPendingUndangan();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Greeting ───────────────────────────────────────────────
                  _GreetingBanner(name: user?.username ?? 'User'),
                  const SizedBox(height: 18),

                  // ── Summary Cards ──────────────────────────────────────────
                  const _SectionTitle('Ringkasan Kinerja'),
                  const SizedBox(height: 10),
                  if (summary != null) ...[
                    // Row 1
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Total Kegiatan',
                            value: '${summary.totalKegiatan}',
                            size: 22,
                            subtitle: 'Tahun ${DateTime.now().year}',
                            icon: Icons.task_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryCard(
                            label: 'Realisasi Fisik',
                            value: summary.rataRataFisik.toStringAsFixed(1),
                            size: 22,
                            subtitle: 'Rata-rata',
                            icon: Icons.trending_up_rounded,
                            accentColor: AppUtils.progressColor(
                              summary.rataRataFisik,
                            ),
                            bgColor: AppUtils.progressColor(
                              summary.rataRataFisik,
                            ).withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 2
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Total Anggaran',
                            value: AppUtils.formatCurrency(
                              summary.totalAnggaran,
                            ),
                            size: 18,
                            subtitle: 'kegiatan',
                            icon: Icons.money_rounded,
                            accentColor: AppColors.success,
                            bgColor: AppColors.successLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryCard(
                            label: 'Target Fisik',
                            value:
                                '${(summary.totalRealisasiFisik / summary.totalTarget * 100).toStringAsFixed(1)}%',
                            size: 22,
                            subtitle: 'Terealisasi',
                            icon: Icons.analytics_rounded,
                            accentColor: AppColors.warning,
                            bgColor: AppColors.warningLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Anggaran full-width
                    _AnggaranCard(summary: summary),
                    const SizedBox(height: 10),
                    if (up.isLoadingNearestPending && nearestPending == null)
                      const _PendingUndanganLoadingCard()
                    else if (nearestPending != null)
                      _DashboardPendingUndanganCard(
                        undangan: nearestPending,
                        isUpdating: up.isUpdating,
                        onHadiri: () =>
                            _showHadiriDialog(context, up, nearestPending),
                        onTidakHadir: () =>
                            _showTidakHadirDialog(context, up, nearestPending),
                        onOpenAll: () =>
                            Navigator.pushNamed(context, AppRoutes.undangan),
                      ),
                  ],

                  const SizedBox(height: 20),

                  // ── Progress per Bidang ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('Progres per Bidang'),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.kegiatan),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lihat semua',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _BidangProgressCard(summary: summary!),

                  const SizedBox(height: 20),

                  // ── Quick Actions ──────────────────────────────────────────
                  const _SectionTitle('Aksi Cepat'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Input Realisasi',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.kegiatan),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.mail_outline_rounded,
                          label: 'Undangan',
                          badge: up.pendingCount,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.undangan),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
      ),
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  final String name;
  const _GreetingBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.waving_hand_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'Haloo '),
                  TextSpan(
                    text: name.split(' ').first,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const TextSpan(text: ' — Selamat datang di SIGARDU'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnggaranCard extends StatelessWidget {
  final DashboardSummary summary;
  const _AnggaranCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = summary.totalAnggaran > 0
        ? (summary.totalRealisasi / summary.totalAnggaran * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'Total Anggaran Terrealisasi',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppUtils.formatCurrencyCompact(summary.totalRealisasi),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            'dari ${AppUtils.formatCurrency(summary.totalAnggaran)}',
            style: const TextStyle(fontSize: 11, color: AppColors.primaryMid),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFBFDBFE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pct.toStringAsFixed(1)}% terrealisasi',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BidangProgressCard extends StatelessWidget {
  final DashboardSummary summary;

  const _BidangProgressCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.bidangProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        children: summary.bidangProgress.map((b) {
          return AppProgressBar(
            label: b.nama,
            value: b.totalRealisasiFisik,
            target: b.totalTarget,
          );
        }).toList(),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingUndanganLoadingCard extends StatelessWidget {
  const _PendingUndanganLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Memuat undangan pending...',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DashboardPendingUndanganCard extends StatelessWidget {
  final UndanganModel undangan;
  final bool isUpdating;
  final VoidCallback onHadiri;
  final VoidCallback onTidakHadir;
  final VoidCallback onOpenAll;

  const _DashboardPendingUndanganCard({
    required this.undangan,
    required this.isUpdating,
    required this.onHadiri,
    required this.onTidakHadir,
    required this.onOpenAll,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = undangan.tanggal.isBefore(
      DateTime.now().subtract(const Duration(hours: 1)),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.mark_email_unread_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Undangan Pending Terdekat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    undangan.judul,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const _DashboardStatusBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardMetaRow(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${AppUtils.formatDate(undangan.tanggal)} . ${undangan.waktu} WIB',
                  highlight: isPast,
                  highlightColor: AppColors.danger,
                ),
                const SizedBox(height: 5),
                _DashboardMetaRow(
                  icon: Icons.location_on_outlined,
                  text: undangan.tempat,
                ),
                const SizedBox(height: 5),
                _DashboardMetaRow(
                  icon: Icons.business_rounded,
                  text: undangan.pihakMengundang,
                ),
                const SizedBox(height: 8),
                _DashboardPihakTerkaitRow(pihakList: undangan.pihakTerkait),
                const SizedBox(height: 8),
                const Divider(height: 0),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 13),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUpdating ? null : onHadiri,
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('Hadir', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUpdating ? null : onTidakHadir,
                    icon: const Icon(Icons.close_rounded, size: 15),
                    label: const Text(
                      'Tidak Hadir',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
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

class _DashboardMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  final Color? highlightColor;

  const _DashboardMetaRow({
    required this.icon,
    required this.text,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        highlight ? (highlightColor ?? AppColors.danger) : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: highlight ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardPihakTerkaitRow extends StatelessWidget {
  final List<String> pihakList;
  const _DashboardPihakTerkaitRow({required this.pihakList});

  @override
  Widget build(BuildContext context) {
    if (pihakList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.groups_rounded, size: 13, color: AppColors.textMuted),
            SizedBox(width: 6),
            Text(
              'Pihak yang diundang:',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children:
              pihakList.map((p) => _DashboardPihakChip(label: p)).toList(),
        ),
      ],
    );
  }
}

class _DashboardPihakChip extends StatelessWidget {
  final String label;
  const _DashboardPihakChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _DashboardStatusBadge extends StatelessWidget {
  const _DashboardStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 11, color: Color(0xFF92400E)),
          SizedBox(width: 4),
          Text(
            'Pending',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardDialogInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardDialogInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 0.75),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
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
