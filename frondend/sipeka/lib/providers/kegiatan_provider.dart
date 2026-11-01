// lib/providers/kegiatan_provider.dart

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/kegiatan_model.dart';
import '../providers/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoadState { idle, loading, loaded, error }

class KegiatanProvider extends ChangeNotifier {
  LoadState _loadState = LoadState.idle;
  List<KegiatanModel> _allKegiatan = [];
  KegiatanModel? _selected;
  List<String> _bidangOptions = [];
  String _searchQuery = '';
  String? _selectedBidang;
  DashboardSummary? _summary;
  bool _isSubmitting = false;
  bool _isLoadingMore = false;
  String? _submitMessage;
  String? _errorMessage;
  int _currentPage = 0;
  int _lastPage = 1;
  int _perPage = 20;
  int _totalItems = 0;
  Timer? _searchDebounce;

  // ── Getters ───────────────────────────────────────────────────────────────

  LoadState get loadState => _loadState;
  bool get isLoading => _loadState == LoadState.loading;
  bool get isLoaded => _loadState == LoadState.loaded;
  KegiatanModel? get selected => _selected;
  DashboardSummary? get summary => _summary;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreKegiatan => _currentPage < _lastPage;
  int get totalItems => _totalItems;
  String? get submitMessage => _submitMessage;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedBidang => _selectedBidang;

  List<String> get allBidang {
    if (_bidangOptions.isNotEmpty) {
      return List<String>.from(_bidangOptions)..sort();
    }

    final set = <String>{};
    for (final k in _allKegiatan) {
      if (k.bidang.trim().isNotEmpty) set.add(k.bidang.trim());
    }

    return set.toList()..sort();
  }

  List<KegiatanModel> get filteredKegiatan {
    var list = List<KegiatanModel>.from(_allKegiatan);
    // Filter bidang tetap lokal (instant, tidak butuh API call baru)
    // Search sudah ditangani server-side via setSearch() → loadKegiatan()
    if (_selectedBidang != null) {
      list = list.where((k) => k.bidang == _selectedBidang).toList();
    }
    return list;
  }

  // ── Load Dashboard ────────────────────────────────────────────────────────

  Future<void> loadDashboard() async {
    _loadState = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await DioProvider().getDashboardSummary();
      print('=== loadDashboard res: $res'); // ← lihat ini

      if (res != null && res.isNotEmpty) {
        _summary = DashboardSummary.fromJson(res);
        _loadState = LoadState.loaded;
      }
    } catch (e, st) {
      print('❌ Error: $e\n$st');
      _loadState = LoadState.error;
    }

    notifyListeners();
  }
  // ── Load Kegiatan ─────────────────────────────────────────────────────────

  Future<void> loadKegiatan() async {
    _loadState = LoadState.loading;
    _currentPage = 0;
    _lastPage = 1;
    _totalItems = 0;
    _isLoadingMore = false;
    notifyListeners();
    await _fetchKegiatan(page: 1, reset: true);
  }

  Future<void> loadMoreKegiatan() async {
    if (_isLoadingMore || isLoading || !hasMoreKegiatan) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _fetchKegiatan(page: _currentPage + 1, reset: false);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshKegiatan() async {
    await loadKegiatan();
  }

  Future<void> _fetchKegiatan({required int page, required bool reset}) async {
    try {
      final pageData = await DioProvider().getKegiatan(
        page: page,
        perPage: _perPage,
        bidang: _selectedBidang,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
      print('Fetched kegiatan page $page: $pageData');

      if (pageData != null) {
        try {
          final data = pageData['items'] as List<dynamic>? ?? [];
          final bidangOptions = pageData['bidang_options'];
          if (bidangOptions is List) {
            _bidangOptions = bidangOptions
                .map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
          }

          final parsed = data
              .map((e) => KegiatanModel.fromJson(e as Map<String, dynamic>))
              .toList();

          if (reset) {
            _allKegiatan = parsed;
          } else {
            final existingIds = _allKegiatan.map((k) => k.id).toSet();
            _allKegiatan.addAll(
              parsed.where((k) => !existingIds.contains(k.id)),
            );
          }

          _currentPage = _asInt(pageData['current_page'], page);
          _lastPage = _asInt(pageData['last_page'], page);
          _perPage = _asInt(pageData['per_page'], _perPage);
          _totalItems = _asInt(pageData['total'], _allKegiatan.length);
          _loadState = LoadState.loaded;
          _errorMessage = null;
          _summary ??= DashboardSummary.fromList(_allKegiatan);
        } catch (parseError, stackTrace) {
          // ✅ Print detail error parsing agar mudah di-debug
          print('❌ Error parsing kegiatan: $parseError');
          print('Stack: $stackTrace');
          _loadState = LoadState.error;
          _errorMessage = 'Gagal memproses data: $parseError';
        }
      } else {
        _loadState = LoadState.error;
        _errorMessage = 'Gagal memuat data kegiatan';
      }
    } catch (e, stackTrace) {
      print('❌ Error fetch kegiatan: $e');
      print('Stack: $stackTrace');
      _loadState = LoadState.error;
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    print('Kegiatan list count: ${_allKegiatan.length}');
    if (reset) notifyListeners();
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> loadKegiatanDetail(int id) async {
    try {
      final response = await DioProvider().getKegiatanDetail(id);

      if (response != null) {
        final detail = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'] as Map)
            : response;
        _selected = KegiatanModel.fromJson(detail);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error load detail: $e');
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void selectKegiatan(KegiatanModel kegiatan) {
    _selected = kegiatan;
    notifyListeners();
  }

  // ── Search & Filter ───────────────────────────────────────────────────────

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners(); // update UI field langsung

    // Debounce 500ms — baru hit API setelah user berhenti mengetik
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      loadKegiatan();
    });
  }

  void setBidangFilter(String? bidang) {
    if (_selectedBidang == bidang) return;

    _selectedBidang = bidang;
    loadKegiatan();
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    final shouldReload = _selectedBidang != null || _searchQuery.isNotEmpty;

    _searchQuery = '';
    _selectedBidang = null;

    if (shouldReload) {
      loadKegiatan();
    } else {
      notifyListeners();
    }
  }

  /// Mengembalikan daftar kegiatan ke kondisi awal saat halaman dibuka kembali.
  ///
  /// Provider hidup lebih lama daripada [KegiatanScreen], sehingga query lama
  /// tidak boleh terbawa ketika kolom pencarian pada screen baru masih kosong.
  Future<void> resetFiltersAndLoad() async {
    _searchDebounce?.cancel();
    _searchQuery = '';
    _selectedBidang = null;
    await loadKegiatan();
  }

  // ── Submit Realisasi ──────────────────────────────────────────────────────

  Future<bool> submitRealisasi({
    required int kegiatanId,
    required String bulan,
    required double realisasiFisik,
    required double realisasiAnggaran,
    String? catatan,
    String? namaFile,
    String? filePath,
  }) async {
    _isSubmitting = true;
    _submitMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Cari index bulan dari nama bulan
      const bulanList = [
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
      final bulanIndex = bulanList.indexOf(bulan) + 1;

      final response = await Dio().post(
        '${DioProvider.baseApiUrl}/realisasi',
        data: {
          'kegiatan_id': kegiatanId,
          'bulan': bulanIndex,
          'realisasi_fisik': realisasiFisik,
          'realisasi_anggaran': realisasiAnggaran,
          if (catatan != null) 'keterangan': catatan,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _submitMessage = 'Realisasi bulan $bulan berhasil disimpan.';
        _isSubmitting = false;
        notifyListeners();

        // Refresh data kegiatan
        await _fetchKegiatan(page: 1, reset: true);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Gagal menyimpan realisasi';
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  void clearSubmitMessage() {
    _submitMessage = null;
    notifyListeners();
  }
}
