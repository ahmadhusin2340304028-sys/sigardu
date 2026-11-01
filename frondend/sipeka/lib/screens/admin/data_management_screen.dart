import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/data_management_provider.dart';
import '../../widgets/custom_drawer.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final _tahunCtrl =
      TextEditingController(text: DateTime.now().year.toString());
  final _retensiCtrl = TextEditingController(text: '3');

  @override
  void dispose() {
    _tahunCtrl.dispose();
    _retensiCtrl.dispose();
    super.dispose();
  }

  Future<void> _backup() async {
    final provider = context.read<DataManagementProvider>();
    final bytes = await provider.backup();
    if (!mounted) return;
    if (bytes == null) return _showError(provider.error);

    final file = await _saveFile(bytes,
        'sipeka-backup-${DateTime.now().toIso8601String().replaceAll(':', '-')}.sql');
    if (!mounted) return;
    if (file == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup SQL berhasil disimpan.')));
  }

  Future<void> _import() async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    if (!mounted || selected == null || selected.files.isEmpty) return;
    final file = selected.files.single;
    if (file.bytes == null)
      return _showError('File tidak dapat dibaca dari perangkat.');
    if (file.size > 10 * 1024 * 1024)
      return _showError('Ukuran file maksimal 10 MB.');

    final accepted = await _confirm(
      'Impor kegiatan',
      'Semua baris pada ${file.name} akan diperiksa terlebih dahulu. Data hanya disimpan bila seluruh baris valid.',
      action: 'Impor',
    );
    if (accepted != true || !mounted) return;
    final result = await context.read<DataManagementProvider>().importKegiatan(
          bytes: file.bytes!,
          filename: file.name,
        );
    if (!mounted) return;
    if (result == null)
      return _showError(context.read<DataManagementProvider>().error);
    final count = (result['data'] as Map?)?['imported'] ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count kegiatan berhasil diimpor.')));
  }

  Future<void> _hapusKegiatan() async {
    final tahun = int.tryParse(_tahunCtrl.text);
    if (tahun == null || tahun < 2020 || tahun > 2099)
      return _showError('Masukkan tahun yang valid.');
    final provider = context.read<DataManagementProvider>();
    final preview = await provider.previewKegiatan(tahun);
    if (!mounted) return;
    if (preview == null) return _showError(provider.error);
    final data = Map<String, dynamic>.from(preview['data'] as Map);
    final proceed = await _confirm(
      'Hapus kegiatan tahun $tahun?',
      '${data['kegiatan']} kegiatan akan dihapus bersama ${data['realisasi_fisik']} realisasi fisik, ${data['realisasi_anggaran']} realisasi anggaran, ${data['keterangan_kegiatan']} keterangan, dan ${data['bukti_kegiatan']} bukti. Bidang dan akun pengguna tetap aman.',
      action: 'Hapus permanen',
      danger: true,
    );
    if (proceed != true || !mounted) return;
    final result = await provider.hapusKegiatan(tahun);
    if (!mounted) return;
    if (result == null) return _showError(provider.error);
    _showSuccess(result['message']?.toString());
  }

  Future<void> _hapusUndangan() async {
    final years = int.tryParse(_retensiCtrl.text);
    if (years == null || years < 1 || years > 50)
      return _showError('Masa simpan harus antara 1 sampai 50 tahun.');
    final provider = context.read<DataManagementProvider>();
    final preview = await provider.previewUndangan(years);
    if (!mounted) return;
    if (preview == null) return _showError(provider.error);
    final data = Map<String, dynamic>.from(preview['data'] as Map);
    final proceed = await _confirm(
      'Hapus undangan lama?',
      '${data['undangan']} undangan sebelum ${data['cutoff']} akan dihapus, termasuk ${data['bukti']} file bukti. Masa simpan dapat diubah pada kolom di bawah.',
      action: 'Hapus permanen',
      danger: true,
    );
    if (proceed != true || !mounted) return;
    final result = await provider.hapusUndangan(years);
    if (!mounted) return;
    if (result == null) return _showError(provider.error);
    _showSuccess(result['message']?.toString());
  }

  Future<File?> _saveFile(Uint8List bytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path, type: 'application/sql');
    return file;
  }

  Future<bool?> _confirm(String title, String message,
      {required String action, bool danger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _showError(String? message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message ?? 'Terjadi kesalahan.'),
            backgroundColor: AppColors.danger),
      );
  void _showSuccess(String? message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Berhasil diproses.')),
      );

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<DataManagementProvider>().isBusy;
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Data')),
      drawer: const CustomDrawer(),
      body: AbsorbPointer(
        absorbing: busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (busy) const LinearProgressIndicator(),
            _section(
                'Backup database',
                'Unduh salinan lengkap database dalam format .sql.',
                Icons.backup_outlined,
                ElevatedButton.icon(
                    onPressed: _backup,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Buat backup SQL'))),
            const SizedBox(height: 14),
            _section(
                'Impor kegiatan',
                'Gunakan file .xlsx dengan kolom sesuai template kegiatan.',
                Icons.upload_file_rounded,
                ElevatedButton.icon(
                    onPressed: _import,
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Pilih file Excel'))),
            const SizedBox(height: 14),
            _section(
                'Hapus kegiatan berdasarkan tahun',
                'Data realisasi, keterangan, dan bukti ikut dihapus. Master bidang tetap dipertahankan.',
                Icons.event_busy_rounded,
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                          controller: _tahunCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Tahun kegiatan')),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                          onPressed: _hapusKegiatan,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Tinjau dan hapus')),
                    ]),
                danger: true),
            const SizedBox(height: 14),
            _section(
                'Hapus undangan lama',
                'Undangan dan file buktinya yang melewati masa simpan akan dihapus.',
                Icons.auto_delete_outlined,
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                          controller: _retensiCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Masa simpan (tahun)')),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                          onPressed: _hapusUndangan,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: const Text('Tinjau dan hapus')),
                    ]),
                danger: true),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String subtitle, IconData icon, Widget action,
          {bool danger = false}) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: danger ? AppColors.danger : AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)))
            ]),
            const SizedBox(height: 8),
            Text(subtitle,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 14),
            action,
          ]),
        ),
      );
}
