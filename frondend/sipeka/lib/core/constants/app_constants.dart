// lib/core/constants/app_constants.dart

class AppRoutes {
  AppRoutes._();
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String kegiatan = '/kegiatan';
  static const String detailKegiatan = '/kegiatan/detail';
  static const String inputRealisasi = '/kegiatan/input-realisasi';
  static const String undangan = '/undangan';
  static const String tentang = '/tentang';

  // Admin routes
  static const String adminKegiatan = '/admin/kegiatan';
  static const String adminUndangan = '/admin/undangan';
  static const String adminBidang = '/admin/bidang';
}

class AppStrings {
  AppStrings._();
  static const String appName = 'SIGARDU';
  static const String appSubtitle =
      'Sistem Informasi Pelaporan\nKinerja dan Anggaran Kegiatan';
  static const String dashboard = 'Dashboard';
  static const String kegiatan = 'Kegiatan';
  static const String undangan = 'Undangan';
  static const String tentang = 'Tentang Aplikasi';
  static const String logout = 'Keluar';
  static const String inputRealisasi = 'Input Realisasi';
  static const String detailKegiatan = 'Detail Kegiatan';
}

class AppMonths {
  AppMonths._();
  static const List<String> list = [
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
}
