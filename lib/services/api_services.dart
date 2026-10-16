import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_meeting_controller/helper/global_var.dart';

class ApiService {
  /// Dipanggil saat endpoint ber-token membalas 401 (token dicabut admin).
  /// Diisi di main.dart: hapus token & kembali ke halaman input kode.
  static void Function()? onUnauthorized;

  static const _defaultTimeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>?> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
    Duration timeout = _defaultTimeout,
  }) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response, withToken: token != null);
    } on TimeoutException {
      return _error('Server tidak merespons. Coba lagi.', 'TIMEOUT');
    } catch (e) {
      return _error(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        'NETWORK_ERROR',
      );
    }
  }

  static Future<Map<String, dynamic>?> get(
    String endpoint, {
    String? token,
    Duration timeout = _defaultTimeout,
  }) async {
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.get(url, headers: headers).timeout(timeout);

      return _handleResponse(response, withToken: token != null);
    } on TimeoutException {
      return _error('Server tidak merespons. Coba lagi.', 'TIMEOUT');
    } catch (e) {
      return _error(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        'NETWORK_ERROR',
      );
    }
  }

  /// Format respons API: { success, data } atau { success: false, message, code }.
  /// Status HTTP ikut disimpan di 'http_status'.
  static Map<String, dynamic> _handleResponse(
    http.Response response, {
    required bool withToken,
  }) {
    if (response.statusCode == 401 && withToken) {
      onUnauthorized?.call();
    }

    Map<String, dynamic> result;
    try {
      result = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      result = _error('Terjadi kesalahan pada server.', 'INVALID_RESPONSE');
    }
    result['http_status'] = response.statusCode;
    return result;
  }

  static Map<String, dynamic> _error(String message, String code) {
    return {
      'success': false,
      'message': message,
      'code': code,
      'data': null,
    };
  }
}
