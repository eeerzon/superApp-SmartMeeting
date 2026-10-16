import 'package:smart_meeting_controller/services/api_services.dart';
import 'package:smart_meeting_controller/services/storage_services.dart';

class ApiResult {
  const ApiResult({
    required this.success,
    this.data,
    this.message,
    this.code,
  });

  final bool success;
  final Map<String, dynamic>? data;

  /// Pesan dari API, sudah Bahasa Indonesia & aman ditampilkan ke pengguna.
  final String? message;

  /// Kode galat dari API, untuk logika aplikasi.
  final String? code;

  factory ApiResult.from(Map<String, dynamic>? response) {
    final success = response?['success'] == true;
    final data = response?['data'];
    return ApiResult(
      success: success,
      data: data is Map<String, dynamic> ? data : null,
      message: response?['message']?.toString() ??
          (success ? null : 'Terjadi kesalahan. Coba lagi.'),
      code: response?['code']?.toString(),
    );
  }
}

/// Pairing ruangan & data ruangan. Satu token = satu ruangan.
class RoomService {
  /// Tukar kode setup (XXXX-XXXX) dengan token, lalu simpan token di
  /// penyimpanan aman (Keychain / Keystore). Kode tidak disimpan.
  static Future<ApiResult> pair(String pairingCode) async {
    final response = await ApiService.post(
      '/api/v1/monitor/pair',
      body: {'pairing_code': pairingCode},
    );

    final result = ApiResult.from(response);
    final token = result.data?['token']?.toString() ?? '';

    if (!result.success || token.isEmpty) {
      return ApiResult(
        success: false,
        message: response?['http_status'] == 401
            ? 'Kode salah atau sudah diganti admin. Masukkan kode terbaru.'
            : result.message ?? 'Gagal menghubungkan ruangan.',
        code: result.code,
      );
    }

    await StorageService.setToken(token);
    return result;
  }

  /// Data ruangan + daftar perangkat.
  /// data = { room: {...}, kendali: { tersedia }, devices: [...] }
  static Future<ApiResult> fetchRoom() async {
    final response = await ApiService.get(
      '/api/v1/remote/room',
      token: await StorageService.getToken(),
    );
    return ApiResult.from(response);
  }

  /// Status ruangan + agenda meeting hari ini.
  /// data = { status: available | in_use, available_until, current_meeting,
  /// next_meeting, schedule, server_time, ... }
  static Future<ApiResult> fetchRoomStatus() async {
    final response = await ApiService.get(
      '/api/v1/monitor/room-status',
      token: await StorageService.getToken(),
    );
    return ApiResult.from(response);
  }

  /// Status semua perangkat di ruangan, ditanyakan langsung ke mini PC
  /// (server menunggu sampai 5 detik).
  /// data = { diperbarui_pada, devices: [{ id_perangkat, online, daya, volume,
  /// bisu, input, kontras, kecerahan, dipantau, perintah }] }
  /// Mini PC mati → gagal dengan code `MINIPC_TIDAK_TERHUBUNG` (503).
  static Future<ApiResult> fetchDeviceStates() async {
    final response = await ApiService.get(
      '/api/v1/remote/devices/state',
      token: await StorageService.getToken(),
    );
    return ApiResult.from(response);
  }

  /// Kirim perintah ke satu perangkat dan tunggu hasilnya.
  /// Server menunggu mini PC sampai 30 detik, jadi batas waktu di app 40 detik.
  /// [kode] dari `perintah[].kode` di data ruangan, mis. `power_on`, `volume_set`.
  static Future<ApiResult> sendCommand(
    String idPerangkat,
    String kode, {
    Map<String, dynamic>? parameter,
  }) async {
    final response = await ApiService.post(
      '/api/v1/remote/devices/$idPerangkat/commands',
      token: await StorageService.getToken(),
      timeout: const Duration(seconds: 40),
      body: {
        'perintah': kode,
        if (parameter != null) 'parameter': parameter,
      },
    );
    return ApiResult.from(response);
  }

  /// Hapus token tersimpan (keluar dari ruangan).
  static Future<void> logout() => StorageService.removeToken();
}
