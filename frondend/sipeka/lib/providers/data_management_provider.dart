import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dio_provider.dart';

class DataManagementProvider extends ChangeNotifier {
  bool _isBusy = false;
  String? _error;

  bool get isBusy => _isBusy;
  String? get error => _error;

  Future<Uint8List?> backup() async {
    return _requestBytes('admin/data/backup');
  }

  Future<Map<String, dynamic>?> previewKegiatan(int tahun) async {
    return _requestJson('admin/data/kegiatan-cleanup-preview',
        query: {'tahun': tahun});
  }

  Future<Map<String, dynamic>?> hapusKegiatan(int tahun) async {
    return _requestJson('admin/data/kegiatan-by-year',
        method: 'DELETE', query: {'tahun': tahun});
  }

  Future<Map<String, dynamic>?> previewUndangan(int years) async {
    return _requestJson('admin/data/undangan-cleanup-preview',
        query: {'years': years});
  }

  Future<Map<String, dynamic>?> hapusUndangan(int years) async {
    return _requestJson('admin/data/old-undangan',
        method: 'DELETE', query: {'years': years});
  }

  Future<Map<String, dynamic>?> importKegiatan({
    required Uint8List bytes,
    required String filename,
  }) async {
    _setBusy(true);
    try {
      final response = await Dio().post(
        '${DioProvider.baseApiUrl}/admin/data/kegiatan-import',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: filename),
        }),
        options: await _options(),
      );
      return _finishJson(response.data);
    } on DioException catch (e) {
      _error = _message(e.response?.data) ?? 'Impor gagal dilakukan.';
      return null;
    } catch (_) {
      _error = 'Impor gagal dilakukan.';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<Map<String, dynamic>?> _requestJson(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? query,
  }) async {
    _setBusy(true);
    try {
      final response = await Dio().request(
        '${DioProvider.baseApiUrl}/$path',
        queryParameters: query,
        options: await _options(method: method),
      );
      return _finishJson(response.data);
    } on DioException catch (e) {
      _error = _message(e.response?.data) ?? 'Permintaan gagal dilakukan.';
      return null;
    } catch (_) {
      _error = 'Permintaan gagal dilakukan.';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<Uint8List?> _requestBytes(String path) async {
    _setBusy(true);
    try {
      final response = await Dio().get(
        '${DioProvider.baseApiUrl}/$path',
        options: await _options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data is List<int>) return Uint8List.fromList(data);
      _error = 'File backup tidak valid.';
      return null;
    } on DioException catch (e) {
      _error = _message(e.response?.data) ?? 'Backup gagal dibuat.';
      return null;
    } catch (_) {
      _error = 'Backup gagal dibuat.';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<Options> _options(
      {String method = 'GET', ResponseType? responseType}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return Options(
      method: method,
      responseType: responseType,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      validateStatus: (status) => status != null && status < 500,
    );
  }

  Map<String, dynamic>? _finishJson(dynamic data) {
    if (data is Map && data['success'] == true) {
      return Map<String, dynamic>.from(data);
    }
    _error = _message(data) ?? 'Permintaan tidak dapat diproses.';
    return null;
  }

  String? _message(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map && first['messages'] is List) {
        return 'Baris ${first['row']}: ${(first['messages'] as List).join(', ')}';
      }
    }
    if (data['message'] != null) return data['message'].toString();
    return null;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    if (value) _error = null;
    notifyListeners();
  }
}
