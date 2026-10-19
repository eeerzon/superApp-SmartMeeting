import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meeting_controller/helper/command_dialogs.dart';
import 'package:smart_meeting_controller/pages/devices_page.dart';
import 'package:smart_meeting_controller/pages/login_room.dart';
import 'package:smart_meeting_controller/services/room_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  static const _sidebarWidth = 220.0;
  static const _sidebarCollapsedWidth = 12.0;
  static const _sidebarAnim = Duration(milliseconds: 250);
  static const _navCollapsedKey = 'navCollapsed';

  /// Sidebar ditutup = tinggal strip tipis + tab chevron. Disimpan antar sesi.
  bool _navCollapsed = false;
  String _menu = 'Dashboard';
  String _previousMenu = 'Dashboard';

  /// Perangkat yang dibuka di halaman Perangkat (null = yang pertama).
  String? _devicesDeviceId;

  // Data dari GET /api/v1/remote/room
  Map<String, dynamic>? _room;
  bool _kendaliTersedia = true;
  String? _kendaliPesan;
  List<Map<String, dynamic>> _devices = [];
  bool _loadingRoom = true;
  String? _roomError;

  /// ID perangkat / scene yang sedang menunggu balasan perintah,
  /// beserta label perintahnya untuk ditampilkan (mis. "Nyalakan").
  final Map<String, String> _pending = {};

  /// Quick Scene, dirakit di aplikasi dari perintah perangkat yang tersedia.
  /// [steps] = urutan kode perintah; perangkat yang tidak punya kode itu dilewati.
  static const _scenes = [
    (
      key: 'meeting',
      title: 'Mulai Meeting',
      icon: Icons.play_arrow_rounded,
      desc: 'IFP menyala, input HDMI 1, suara aktif',
      steps: ['power_on', 'input_hdmi1', 'unmute'],
    ),
    (
      key: 'present',
      title: 'Presentasi',
      icon: Icons.co_present_outlined,
      desc: 'IFP menyala, mode gambar cerah',
      steps: ['power_on', 'picture_bright'],
    ),
    (
      key: 'video',
      title: 'Video Call',
      icon: Icons.videocam_outlined,
      desc: 'IFP menyala, input Android, suara aktif',
      steps: ['power_on', 'input_android', 'unmute'],
    ),
    (
      key: 'end',
      title: 'Selesai',
      icon: Icons.power_settings_new_rounded,
      desc: 'Matikan semua perangkat',
      steps: ['power_off'],
    ),
  ];

  /// Scene yang terakhir diterapkan; hilang kalau perangkat diubah manual.
  String? _activeScene;

  /// Scene yang sedang dijalankan beserta progresnya ("Menerapkan 2/4…").
  ({String key, int done, int total})? _sceneRun;

  // Data dari GET /api/v1/remote/devices/state, per id_perangkat.
  // Kosong = status belum/tidak diketahui (mis. mini PC tidak terhubung).
  Map<String, Map<String, dynamic>> _states = {};

  /// `diperbarui_pada` dari respons status terakhir.
  DateTime? _statesUpdatedAt;

  /// True selama status pertama kali dimuat (sebelum ada data sama sekali).
  bool _loadingStates = false;

  // Data dari GET /api/v1/monitor/room-status (jadwal & status ruangan).
  Map<String, dynamic>? _roomStatus;
  Timer? _roomStatusPolling;

  /// Selisih jam server - jam perangkat, & zona waktu server (mis. +07:00).
  /// Jam di top bar mengikuti jam server, bukan jam perangkat.
  Duration _serverOffset = Duration.zero;
  Duration? _serverTimeZone;
  Timer? _clockTimer;
  String _clockText = '';
  Timer? _statePolling;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNavCollapsed();
    _loadRoom();
    _updateClock();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateClock(),
    );
    // Jadwal ruangan tiap 60 detik (saran API: 30–60 dtk).
    _roomStatusPolling = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_appActive) _loadRoomStatus();
    });
    // Polling status tiap 20 detik selama dashboard terbuka (saran API: 15–30 dtk).
    _statePolling = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_appActive && _menu == 'Dashboard' && _pending.isEmpty) {
        _loadStates();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statePolling?.cancel();
    _roomStatusPolling?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  /// Jangan polling saat aplikasi di latar belakang.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      _loadStates();
      _loadRoomStatus();
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? const Color(0xFFD6322C) : null,
          behavior: SnackBarBehavior.floating,
          width: 420,
          duration: Duration(milliseconds: error ? 4000 : 2400),
        ),
      );
  }

  // ---------------- DATA RUANGAN ----------------

  Future<void> _loadRoom() async {
    _loadRoomStatus();
    setState(() {
      _loadingRoom = true;
      _roomError = null;
    });

    final result = await RoomService.fetchRoom();
    if (!mounted) return;

    setState(() {
      _loadingRoom = false;
      if (!result.success) {
        _roomError = result.message;
        return;
      }
      final data = result.data!;
      final kendali = data['kendali'] as Map<String, dynamic>? ?? {};
      _room = data['room'] as Map<String, dynamic>?;
      _kendaliTersedia = kendali['tersedia'] != false;
      _kendaliPesan = kendali['pesan']?.toString();
      _devices = (data['devices'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
    });
    if (_roomError == null) _loadStates();
  }

  Future<void> _loadRoomStatus() async {
    final result = await RoomService.fetchRoomStatus();
    if (!mounted || !result.success) return;
    final data = result.data!;
    final serverTime = data['server_time']?.toString();
    setState(() {
      _roomStatus = data;
      final parsed = DateTime.tryParse(serverTime ?? '');
      if (parsed != null) {
        _serverOffset = parsed.difference(DateTime.now());
        _serverTimeZone = _parseTimeZone(serverTime!);
      }
    });
    _updateClock();
  }

  /// Ambil zona waktu dari string ISO 8601, mis. "...T15:17:00+07:00" → +7 jam.
  Duration? _parseTimeZone(String iso) {
    final m = RegExp(r'([+-])(\d{2}):?(\d{2})$').firstMatch(iso);
    if (m == null) return null;
    final d = Duration(
      hours: int.parse(m.group(2)!),
      minutes: int.parse(m.group(3)!),
    );
    return m.group(1) == '-' ? -d : d;
  }

  /// Label zona waktu Indonesia untuk jam dari API.
  String get _zoneLabel => switch (_serverTimeZone?.inHours) {
        7 => ' WIB',
        8 => ' WITA',
        9 => ' WIT',
        _ => '',
      };

  void _updateClock() {
    final now = DateTime.now().add(_serverOffset);
    // Tampilkan dalam zona waktu server kalau diketahui, kalau belum pakai jam perangkat.
    final shown =
        _serverTimeZone == null ? now : now.toUtc().add(_serverTimeZone!);
    final text = '${shown.hour.toString().padLeft(2, '0')}:'
        '${shown.minute.toString().padLeft(2, '0')}';
    if (text != _clockText && mounted) setState(() => _clockText = text);
  }

  Future<void> _loadStates() async {
    if (_devices.isEmpty) return;
    if (_states.isEmpty) setState(() => _loadingStates = true);
    final result = await RoomService.fetchDeviceStates();
    if (!mounted) return;
    setState(() => _loadingStates = false);
    if (!result.success) {
      // Mis. MINIPC_TIDAK_TERHUBUNG: perangkat tetap tampil, status "tidak diketahui".
      setState(() {
        _states = {};
        _statesUpdatedAt = null;
      });
      return;
    }
    final list = (result.data?['devices'] as List? ?? [])
        .whereType<Map<String, dynamic>>();
    setState(() {
      _states = {for (final s in list) s['id_perangkat'] as String: s};
      _statesUpdatedAt =
          DateTime.tryParse('${result.data?['diperbarui_pada']}')?.toLocal();
      // Respons status juga membawa daftar `perintah` terbaru.
      for (final d in _devices) {
        final perintah = _states[d['id_perangkat']]?['perintah'];
        if (perintah is List) d['perintah'] = perintah;
      }
    });
  }

  // ---------------- KIRIM PERINTAH ----------------

  /// Tombol perintah dari `perintah[]`: konfirmasi (kalau diminta),
  /// minta nilai parameter (kalau ada), kirim, lalu tunggu hasilnya.
  Future<void> _runCommand(
    Map<String, dynamic> device,
    Map<String, dynamic> perintah,
  ) async {
    final id = device['id_perangkat'] as String;
    final kode = perintah['kode'] as String;
    final label = perintah['label']?.toString() ?? kode;
    if (_pending.containsKey(id)) return;

    if (perintah['konfirmasi'] == true) {
      final ok = await showConfirmDialog(
        context,
        title: '$label ${device['nama']}?',
        message: 'Perintah akan langsung dikirim ke perangkat.',
        confirmLabel: label,
      );
      if (!ok || !mounted) return;
    }

    Map<String, dynamic>? parameter;
    final paramSpec = perintah['parameter'];
    if (paramSpec is Map<String, dynamic> && paramSpec.isNotEmpty) {
      parameter = await showParameterDialog(
        context,
        label,
        paramSpec,
        state: _states[id],
      );
      if (parameter == null || !mounted) return;
    }

    setState(() => _pending[id] = label);
    final result =
        await RoomService.sendCommand(id, kode, parameter: parameter);
    if (!mounted) return;
    setState(() => _pending.remove(id));

    if (result.success) {
      _toast(result.message ?? '${device['nama']}: $label berhasil');
      // Status setelah perintah (kalau dikirim mini PC), lalu muat ulang sekali.
      // Perangkat diubah manual → scene tidak lagi "Sedang aktif".
      final newState = result.data?['state'];
      setState(() {
        if (newState is Map<String, dynamic>) {
          _states[id] = {...?_states[id], ...newState};
        }
        _activeScene = null;
      });
      _loadStates();
      return;
    }

    switch (result.code) {
      case 'PERANGKAT_TIDAK_DITEMUKAN':
        _toast(result.message!, error: true);
        _loadRoom();
      case 'MINIPC_TIMEOUT':
        // Perintah mungkin tetap dijalankan, jangan langsung kirim ulang.
        _toast(
          '${result.message} Cek status perangkat sebelum mencoba lagi.',
          error: true,
        );
        _loadStates();
      default:
        _toast(result.message!, error: true);
    }
  }

  // ---------------- QUICK SCENE ----------------

  /// Perintah yang tidak perlu dikirim karena status perangkat sudah sesuai.
  bool _alreadyApplied(String kode, Map<String, dynamic>? state) {
    if (state == null || state['online'] != true) return false;
    if (kode.startsWith('input_') && state['input'] != null) {
      return _inputKey(kode) == _inputKey('${state['input']}');
    }
    return switch (kode) {
      'power_on' => state['daya'] == 'on',
      'power_off' => state['daya'] == 'off',
      'unmute' => state['bisu'] == false,
      'mute' => state['bisu'] == true,
      _ => false,
    };
  }

  /// Jalankan scene: kirim perintah satu per satu ke perangkat yang punya
  /// perintahnya (POST /remote/devices/{id}/commands), seperti di prototype.
  Future<void> _runScene(
    ({
      String key,
      String title,
      IconData icon,
      String desc,
      List<String> steps,
    }) scene,
  ) async {
    if (_sceneRun != null || _pending.isNotEmpty) return;

    if (scene.key == 'end') {
      final ok = await showConfirmDialog(
        context,
        title: 'Akhiri meeting?',
        message: 'Semua perangkat akan dimatikan. Pastikan tidak ada peserta '
            'yang masih menggunakan ruangan.',
        confirmLabel: 'Matikan semua',
      );
      if (!ok || !mounted) return;
    }

    // Susun langkah: perangkat yang bisa dikontrol & tidak offline, perintah
    // yang tersedia di `perintah` perangkat itu, dan yang belum sesuai status.
    final plan = <(Map<String, dynamic>, Map<String, dynamic>)>[];
    var matched = 0;
    for (final d in _devices) {
      if (d['bisa_dikontrol'] != true) continue;
      final state = _states[d['id_perangkat']];
      if (state != null &&
          (state['dipantau'] == false || state['online'] != true)) {
        continue;
      }
      var hasStep = false;
      for (final kode in scene.steps) {
        final p = _findPerintah(d, kode);
        if (p == null) continue;
        hasStep = true;
        if (!_alreadyApplied(kode, state)) plan.add((d, p));
      }
      if (hasStep) matched++;
    }

    if (plan.isEmpty) {
      if (matched > 0) {
        setState(() => _activeScene = scene.key == 'end' ? null : scene.key);
        _toast('Perangkat sudah sesuai scene "${scene.title}"');
      } else {
        _toast(
          'Tidak ada perangkat online yang bisa diatur untuk scene ini.',
          error: true,
        );
      }
      return;
    }

    setState(() => _sceneRun = (key: scene.key, done: 0, total: plan.length));
    final failures = <String>[];
    final failedDevices = <String>{};

    for (final (d, p) in plan) {
      final id = d['id_perangkat'] as String;
      // Kalau perintah sebelumnya ke perangkat ini gagal (mis. gagal menyala),
      // langkah berikutnya untuk perangkat itu dilewati.
      if (!failedDevices.contains(id)) {
        setState(() => _pending[id] = '${p['label']}');
        final result = await RoomService.sendCommand(id, '${p['kode']}');
        if (!mounted) return;
        setState(() {
          _pending.remove(id);
          final newState = result.data?['state'];
          if (result.success && newState is Map<String, dynamic>) {
            _states[id] = {...?_states[id], ...newState};
          }
        });
        if (!result.success) {
          failedDevices.add(id);
          failures.add(result.message ?? 'Perintah ${p['label']} gagal');
        }
      }
      setState(() {
        final run = _sceneRun!;
        _sceneRun = (key: run.key, done: run.done + 1, total: run.total);
      });
    }

    final deviceCount = plan.map((e) => e.$1['id_perangkat']).toSet().length;
    setState(() {
      _sceneRun = null;
      if (failures.isEmpty) {
        _activeScene = scene.key == 'end' ? null : scene.key;
      }
    });
    failures.isEmpty
        ? _toast('Scene "${scene.title}" diterapkan ke $deviceCount perangkat')
        : _toast(
            'Scene "${scene.title}": ${failures.length} perintah gagal. '
            '${failures.first}',
            error: true,
          );
    _loadStates();
  }

  // ---------------- NAVIGASI ----------------

  Future<void> _loadNavCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    final collapsed = prefs.getBool(_navCollapsedKey) ?? false;
    if (mounted && collapsed != _navCollapsed) {
      setState(() => _navCollapsed = collapsed);
    }
  }

  Future<void> _toggleSidebar() async {
    setState(() => _navCollapsed = !_navCollapsed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_navCollapsedKey, _navCollapsed);
  }

  void _goTo(String menu) {
    if (menu == _menu) return;
    setState(() {
      _previousMenu = _menu;
      _menu = menu;
    });
  }

  void _goBack() => _goTo(_previousMenu == _menu ? 'Dashboard' : _previousMenu);

  void _openDevices(String? deviceId) {
    setState(() {
      _devicesDeviceId = deviceId;
      _goTo('Perangkat');
    });
  }

  /// Keluar dari ruangan: hapus token, kembali ke halaman input kode.
  Future<void> _logout() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Keluar dari ruangan?',
      message: 'Perangkat di ruangan tetap berjalan. '
          'Anda perlu memasukkan kode setup lagi untuk mengendalikannya.',
      confirmLabel: 'Keluar',
    );
    if (!ok) return;

    await RoomService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginRoom()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tombol back Android: kalau sedang di halaman Perangkat, kembali ke
    // Dashboard dulu. Di Dashboard, back berjalan normal (keluar aplikasi).
    return PopScope(
      canPop: _menu == 'Dashboard',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo('Dashboard');
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebar(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: _menu == 'Perangkat'
                            ? DevicesPage(
                                initialDeviceId: _devicesDeviceId,
                                onBack: _goBack,
                              )
                            : _buildDashboardContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildSidebarToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final room = _room;
    final info = [
      if (room?['gedung'] != null) room!['gedung'],
      if (room?['lantai'] != null) room!['lantai'],
      if (room?['kapasitas'] != null) 'Kapasitas ${room!['kapasitas']} orang',
      if (!_loadingRoom && _roomError == null) '${_devices.length} perangkat',
    ].join(' · ');

    return RefreshIndicator(
      color: const Color(0xFFD6322C),
      onRefresh: _loadRoom,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room?['nama_ruangan']?.toString() ?? 'Memuat ruangan…',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              info,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildQuickSceneSection(),
            const SizedBox(height: 28),
            _buildPerangkatSection(),
          ],
        ),
      ),
    );
  }

  // ---------------- SIDEBAR ----------------

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: _sidebarAnim,
      curve: Curves.easeInOut,
      width: _navCollapsed ? _sidebarCollapsedWidth : _sidebarWidth,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE7E8EC))),
      ),
      child: OverflowBox(
        maxWidth: _sidebarWidth,
        alignment: Alignment.topLeft,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _navCollapsed ? 0 : 1,
          child: IgnorePointer(
            ignoring: _navCollapsed,
            child: SizedBox(
              width: _sidebarWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  _sidebarItem(Icons.grid_view_rounded, 'Dashboard'),
                  _sidebarItem(Icons.devices_other_outlined, 'Perangkat'),
                  // _sidebarItem(Icons.tune_rounded, 'Pengaturan'),
                  // _sidebarItem(Icons.person_outline_rounded, 'User'),
                  const Spacer(),
                  const Divider(height: 1),
                  _sidebarItem(Icons.logout_rounded, 'Keluar', onTap: _logout),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tab chevron di tengah tepi kanan sidebar untuk buka/tutup menu.
  Widget _buildSidebarToggle() {
    final label = _navCollapsed ? 'Tampilkan menu' : 'Sembunyikan menu';
    return AnimatedPositioned(
      duration: _sidebarAnim,
      curve: Curves.easeInOut,
      left: (_navCollapsed ? _sidebarCollapsedWidth : _sidebarWidth) - 1,
      top: 0,
      bottom: 0,
      child: Center(
        child: Tooltip(
          message: label,
          child: Semantics(
            button: true,
            label: label,
            child: Material(
              color: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.horizontal(right: Radius.circular(12)),
                side: BorderSide(color: Color(0xFFE7E8EC)),
              ),
              elevation: 3,
              shadowColor: const Color(0x2E101828),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _toggleSidebar,
                hoverColor: const Color(0xFFFFF4F4),
                highlightColor: const Color(0xFFFFE5E6),
                child: SizedBox(
                  width: 24,
                  height: 56,
                  child: AnimatedRotation(
                    duration: _sidebarAnim,
                    turns: _navCollapsed ? 0.5 : 0,
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: Color(0xFFD6322C),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [onTap] diisi untuk aksi khusus (mis. Keluar); default pindah menu.
  Widget _sidebarItem(IconData icon, String label, {VoidCallback? onTap}) {
    final selected = _menu == label;
    return InkWell(
      onTap: onTap ?? () => _goTo(label),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCEBEA) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? const Border(
                  left: BorderSide(color: Color(0xFFD6322C), width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? const Color(0xFFD6322C) : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color:
                    selected ? const Color(0xFFD6322C) : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TOP BAR ----------------

  Widget _buildTopBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7E8EC))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _pillBadge(
            icon: Icons.location_on_outlined,
            label: _room?['nama_ruangan']?.toString() ?? '…',
            bg: const Color(0xFFFCE9E8),
            fg: const Color(0xFFD6322C),
          ),
          const Spacer(),
          ..._buildMeetingBadges(),
          // Status kendali dari `kendali.tersedia` (mini PC bisa dihubungi).
          Row(
            children: [
              Icon(
                _kendaliTersedia ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                size: 16,
                color:
                    _kendaliTersedia ? Colors.green : const Color(0xFFD6322C),
              ),
              const SizedBox(width: 4),
              Text(
                _kendaliTersedia ? 'Terhubung' : 'Kendali tidak tersedia',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Text(
            _clockText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFD6322C),
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge status ruangan + jam meeting dari /monitor/room-status.
  /// in_use    → "Meeting Aktif" + jam meeting yang sedang berlangsung.
  /// available → "Tersedia" + jam meeting berikutnya hari ini (kalau ada).
  List<Widget> _buildMeetingBadges() {
    final status = _roomStatus;
    if (status == null) return const [];

    final current = status['current_meeting'] as Map<String, dynamic>?;
    final next = status['next_meeting'] as Map<String, dynamic>?;
    final inUse = status['status'] == 'in_use';

    String range(Map<String, dynamic> m) =>
        '${m['from_time']} - ${m['to_time']}$_zoneLabel';

    final String? timeLabel;
    if (inUse && current != null) {
      timeLabel = range(current);
    } else if (next != null) {
      timeLabel = 'Berikutnya ${range(next)}';
    } else {
      timeLabel = 'Kosong hingga akhir hari';
    }

    final meeting = inUse ? current : next;
    final tooltip = meeting == null
        ? ''
        : '${meeting['agenda_meeting']} · ${meeting['organizer']}';

    return [
      Tooltip(
        message: inUse ? tooltip : '',
        child: _pillBadge(
          dotColor: Colors.white,
          label: inUse ? 'Meeting Aktif' : 'Tersedia',
          bg: inUse ? const Color(0xFFD6322C) : const Color(0xFF16A34A),
          fg: Colors.white,
        ),
      ),
      const SizedBox(width: 10),
      Tooltip(
        message: tooltip,
        child: _pillBadge(
          icon: Icons.access_time_rounded,
          label: timeLabel,
          bg: const Color(0xFFF2F3F5),
          fg: Colors.black87,
        ),
      ),
      const SizedBox(width: 16),
    ];
  }

  Widget _pillBadge({
    IconData? icon,
    Color? dotColor,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- QUICK SCENE ----------------

  Widget _buildQuickSceneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Quick Scene',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              'Satu sentuhan untuk mengatur semua perangkat',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final cards = [
              for (final scene in _scenes) _quickSceneCard(scene),
            ];

            if (isWide) {
              return Row(
                children: cards
                    .map(
                      (c) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: c,
                        ),
                      ),
                    )
                    .toList()
                  ..last = Expanded(child: cards.last),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  cards.map((c) => SizedBox(width: 220, child: c)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _quickSceneCard(
    ({
      String key,
      String title,
      IconData icon,
      String desc,
      List<String> steps,
    }) scene,
  ) {
    final run = _sceneRun;
    final loading = run?.key == scene.key;
    // Kartu merah = scene yang sedang aktif (seperti prototype).
    final highlighted = _activeScene == scene.key && !loading;
    final icon = scene.icon;
    final title = scene.title;
    final subtitle = loading
        ? 'Menerapkan ${run!.done}/${run.total}…'
        : highlighted
            ? 'Sedang aktif'
            : scene.desc;
    return InkWell(
      // Selama scene berjalan, semua kartu scene dikunci.
      onTap: run != null ? null : () => _runScene(scene),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFD6322C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted ? Colors.transparent : const Color(0xFFE7E8EC),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: highlighted
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: highlighted
                            ? Colors.white
                            : const Color(0xFFD6322C),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 18,
                      color: highlighted ? Colors.white : Colors.black87,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: highlighted ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color:
                          highlighted ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- PERANGKAT RUANGAN ----------------

  Widget _buildPerangkatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Perangkat Ruangan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _loadingRoom ? null : _loadRoom,
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
            if (_statesUpdatedAt != null)
              Text(
                'Status diperbarui '
                '${_statesUpdatedAt!.hour.toString().padLeft(2, '0')}:'
                '${_statesUpdatedAt!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openDevices(null),
              icon: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFD6322C),
              ),
              label: const Text(
                'Kelola perangkat',
                style: TextStyle(
                  color: Color(0xFFD6322C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(iconAlignment: IconAlignment.end),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_kendaliTersedia) ...[
          _kendaliBanner(),
          const SizedBox(height: 12),
        ],
        _buildDeviceGrid(),
      ],
    );
  }

  Widget _kendaliBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _kendaliPesan ??
                  'Kendali perangkat sedang tidak tersedia. '
                      'Coba lagi beberapa saat lagi.',
              style: const TextStyle(color: Color(0xFF92400E), fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGrid() {
    if (_loadingRoom && _devices.isEmpty) {
      return _sectionMessage(
        icon: const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFFD6322C),
          ),
        ),
        text: 'Memuat perangkat ruangan…',
      );
    }

    if (_roomError != null) {
      return _sectionMessage(
        icon: const Icon(
          Icons.cloud_off_rounded,
          size: 30,
          color: Color(0xFFD6322C),
        ),
        text: _roomError!,
        action: OutlinedButton.icon(
          onPressed: _loadRoom,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Coba lagi'),
        ),
      );
    }

    if (_devices.isEmpty) {
      return _sectionMessage(
        icon: Icon(
          Icons.devices_other_outlined,
          size: 30,
          color: Colors.grey.shade400,
        ),
        text: 'Belum ada perangkat aktif di ruangan ini',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000
            ? 3
            : constraints.maxWidth > 650
                ? 2
                : 1;
        const spacing = 14.0;
        // Tinggi semua card = tinggi card yang paling tinggi.
        return _EqualHeightGrid(
          columns: crossAxisCount,
          spacing: spacing,
          children: [
            for (final device in _devices)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Klik area kosong card -> buka tab perangkat yang sesuai.
                onTap: () => _openDevices(device['id_perangkat'] as String),
                child: device['jenis_kontrol'] == 'ifp'
                    ? _ifpCard(device)
                    : _deviceCard(device),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionMessage({
    required Widget icon,
    required String text,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E8EC)),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action,
          ],
        ],
      ),
    );
  }

  // ---------------- CARD PERANGKAT ----------------

  IconData _deviceIcon(Map<String, dynamic> d) {
    switch (d['jenis_kontrol']) {
      case 'ifp':
        return Icons.cast_rounded;
      case 'pintu':
        return Icons.sensor_door_outlined;
    }
    final kategori = d['kategori']?.toString().toLowerCase() ?? '';
    if (kategori.contains('display')) return Icons.cast_rounded;
    if (kategori.contains('keamanan')) return Icons.sensor_door_outlined;
    if (kategori.contains('audio')) return Icons.speaker_outlined;
    if (kategori.contains('kamera')) return Icons.videocam_outlined;
    if (kategori.contains('ac') || kategori.contains('pendingin')) {
      return Icons.ac_unit_rounded;
    }
    if (kategori.contains('lampu') || kategori.contains('cahaya')) {
      return Icons.lightbulb_outline_rounded;
    }
    return Icons.devices_other_outlined;
  }

  /// Label status di bawah nama perangkat, dari `/devices/state`.
  String _statusText(Map<String, dynamic> d) {
    final state = _states[d['id_perangkat']];
    if (state == null && _loadingStates) return 'Memuat status…';
    if (state == null || state['dipantau'] == false) {
      return '${d['kategori'] ?? '-'} · Status tidak diketahui';
    }
    if (state['online'] != true) return 'Offline';
    return switch (state['daya']) {
      'on' => 'Aktif',
      'off' => 'Mati',
      'hibernate' => 'Hibernasi',
      _ => 'Online',
    };
  }

  Color _statusColor(Map<String, dynamic> d) {
    final state = _states[d['id_perangkat']];
    if (state == null || state['dipantau'] == false) return Colors.grey;
    if (state['online'] != true) return const Color(0xFFD6322C);
    if (state['daya'] == 'off') return Colors.grey;
    if (state['daya'] == 'hibernate') return Colors.orange;
    return Colors.green;
  }

  List<Map<String, dynamic>> _perintahOf(Map<String, dynamic> d) {
    return (d['perintah'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Map<String, dynamic>? _findPerintah(Map<String, dynamic> d, String kode) {
    for (final p in _perintahOf(d)) {
      if (p['kode'] == kode) return p;
    }
    return null;
  }

  /// Header card: icon (jadi loading saat menunggu perintah), nama, status.
  Widget _cardHeader(
    Map<String, dynamic> d, {
    required String status,
    required Color statusColor,
    Widget? trailing,
  }) {
    final pendingLabel = _pending[d['id_perangkat']];
    final loading = pendingLabel != null;
    final aktif = d['bisa_dikontrol'] == true;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: aktif ? const Color(0xFFD6322C) : const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _deviceIcon(d),
                  size: 17,
                  color: aktif ? Colors.white : Colors.grey.shade500,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${d['nama']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: loading ? Colors.orange : statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      loading ? '$pendingLabel… menunggu perangkat' : status,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _cardFrame({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E8EC)),
      ),
      child: child,
    );
  }

  // ---------------- CARD IFP ----------------

  /// Kode perintah input → nama input di status, mis. `input_hdmi1` → `HDMI1`.
  /// Contoh: `input_hdmi1`, `HDMI1`, `HDMI 1`, `hdmi-1` → `HDMI1`.
  String _inputKey(String value) => value
      .toLowerCase()
      .replaceFirst('input_', '')
      .replaceAll(RegExp('[^a-z0-9]'), '')
      .toUpperCase();

  IconData _inputIcon(String kode) {
    if (kode.contains('android')) return Icons.android_rounded;
    if (kode.contains('vga')) return Icons.settings_input_component_rounded;
    if (kode.contains('wireless') || kode.contains('cast')) {
      return Icons.cast_rounded;
    }
    return Icons.settings_input_hdmi_rounded;
  }

  Widget _ifpCard(Map<String, dynamic> d) {
    // Status IFP ini dari GET /remote/devices/state, dicocokkan lewat id_perangkat.
    final id = d['id_perangkat'] as String;
    final state = _states[id];
    final loading = _pending.containsKey(id);
    final daya = state?['daya'];
    final online = state?['online'] == true;
    final powerOn = _findPerintah(d, 'power_on');
    final powerOff = _findPerintah(d, 'power_off');

    // Daftar perintah terbaru dari status; kalau status belum ada, dari /remote/room.
    final perintah = state?['perintah'] is List
        ? (state!['perintah'] as List).whereType<Map<String, dynamic>>()
        : _perintahOf(d);
    final inputs = perintah
        .where(
          (p) =>
              p['grup'] == 'Sumber input' ||
              p['kode'].toString().startsWith('input_'),
        )
        .toList();

    // Input aktif dari status, dicocokkan ke perintah input, mis. HDMI1 → "HDMI 1".
    final activeInput = state?['input'] == null
        ? null
        : inputs
            .where(
              (p) =>
                  _inputKey('${p['kode']}') ==
                  _inputKey(state!['input'].toString()),
            )
            .firstOrNull;
    var status = _statusText(d);
    if (daya == 'on' && state?['online'] == true) {
      status = 'Aktif · ${activeInput?['label'] ?? state?['input'] ?? '-'}';
    }

    return _cardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            d,
            status: status,
            statusColor: _statusColor(d),
            trailing: powerOn == null || powerOff == null
                ? null
                : Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: daya == 'on',
                      // Status tidak diketahui → tetap bisa dinyalakan.
                      onChanged: loading
                          ? null
                          : (v) => _runCommand(d, v ? powerOn : powerOff),
                      activeTrackColor: const Color(0xFFD6322C),
                      activeThumbColor: Colors.white,
                    ),
                  ),
          ),
          if (online) ...[
            const SizedBox(height: 10),
            _ifpInfoRow(state!),
          ],
          const SizedBox(height: 12),
          const Text(
            'Sumber input',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: inputs.isEmpty
                ? _cardInfo('Tidak ada sumber input untuk perangkat ini')
                : IgnorePointer(
                    ignoring: loading || daya == 'off',
                    child: Opacity(
                      opacity: loading || daya == 'off' ? 0.45 : 1,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Column(
                          children: [
                            for (var i = 0; i < inputs.length; i += 2) ...[
                              if (i > 0) const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _inputButton(
                                      d,
                                      inputs[i],
                                      selected: inputs[i] == activeInput,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: i + 1 < inputs.length
                                        ? _inputButton(
                                            d,
                                            inputs[i + 1],
                                            selected:
                                                inputs[i + 1] == activeInput,
                                          )
                                        : const SizedBox(),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Info dari key status lain: volume (+ bisu), kontras, kecerahan, suhu.
  /// Key bernilai null tidak ditampilkan.
  Widget _ifpInfoRow(Map<String, dynamic> state) {
    // `bisu` & `volume` dari status; volume tetap ditampilkan walau bisu.
    final bisu = state['bisu'] == true ||
        state['bisu'] == 1 ||
        state['bisu'].toString() == 'true';
    final items = [
      if (state['volume'] != null)
        (
          bisu ? Icons.volume_off_rounded : Icons.volume_up_outlined,
          bisu ? 'Vol ${state['volume']} · Bisu' : 'Vol ${state['volume']}',
        )
      else if (bisu)
        (Icons.volume_off_rounded, 'Bisu'),
      if (state['kontras'] != null)
        (Icons.contrast_rounded, 'Kontras ${state['kontras']}'),
      if (state['kecerahan'] != null)
        (Icons.wb_sunny_outlined, 'Cerah ${state['kecerahan']}'),
      if (state['suhu'] != null)
        (Icons.thermostat_rounded, '${state['suhu']}°C'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (icon, label) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _inputButton(
    Map<String, dynamic> d,
    Map<String, dynamic> p, {
    required bool selected,
  }) {
    final color = selected ? const Color(0xFFD6322C) : Colors.grey.shade700;
    return InkWell(
      onTap: selected ? null : () => _runCommand(d, p),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCEBEA) : const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFD6322C) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_inputIcon('${p['kode']}'), size: 16, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                p['label']?.toString() ?? '${p['kode']}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- CARD PERANGKAT LAIN ----------------

  Widget _deviceCard(Map<String, dynamic> d) {
    final loading = _pending.containsKey(d['id_perangkat']);
    final bisaDikontrol = d['bisa_dikontrol'] == true;
    // Tombol utama di card; perintah `lanjutan` ada di halaman Perangkat.
    final utama = _perintahOf(d).where((p) => p['lanjutan'] != true).toList();

    final kondisi = d['kondisi']?.toString() ?? '-';
    final kondisiLabel = kondisi.isEmpty
        ? '-'
        : '${kondisi[0].toUpperCase()}${kondisi.substring(1)}';
    final hasState = _states[d['id_perangkat']] != null;

    return _cardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            d,
            status: hasState
                ? _statusText(d)
                : '${d['kategori'] ?? '-'} · $kondisiLabel',
            statusColor: hasState
                ? _statusColor(d)
                : switch (kondisi) {
                    'baik' => Colors.green,
                    'maintenance' => Colors.orange,
                    'rusak' => const Color(0xFFD6322C),
                    _ => Colors.grey,
                  },
          ),
          const SizedBox(height: 14),
          Expanded(
            child: !bisaDikontrol || utama.isEmpty
                ? _cardInfo(
                    !bisaDikontrol
                        ? 'Perangkat belum bisa dikontrol dari aplikasi'
                        : !_kendaliTersedia
                            ? 'Kendali sedang tidak tersedia'
                            : 'Tidak ada perintah untuk perangkat ini',
                  )
                : IgnorePointer(
                    ignoring: loading,
                    child: Opacity(
                      opacity: loading ? 0.5 : 1,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in utama) _commandButton(d, p),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _commandButton(Map<String, dynamic> d, Map<String, dynamic> p) {
    return OutlinedButton(
      onPressed: () => _runCommand(d, p),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: const Color(0xFFF7F7F8),
        side: const BorderSide(color: Color(0xFFE7E8EC)),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      child: Text(p['label']?.toString() ?? '${p['kode']}'),
    );
  }

  Widget _cardInfo(String text) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
      ),
    );
  }
}

/// Grid card dengan tinggi seragam: semua anak diukur tinggi aslinya
/// (intrinsic height), lalu yang tertinggi dipakai untuk semua anak.
class _EqualHeightGrid extends MultiChildRenderObjectWidget {
  const _EqualHeightGrid({
    required this.columns,
    required this.spacing,
    required super.children,
  });

  final int columns;
  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualHeightGrid(columns: columns, spacing: spacing);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEqualHeightGrid renderObject,
  ) {
    renderObject
      ..columns = columns
      ..spacing = spacing;
  }
}

class _GridParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualHeightGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GridParentData> {
  _RenderEqualHeightGrid({required int columns, required double spacing})
      : _columns = columns,
        _spacing = spacing;

  int _columns;
  set columns(int value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GridParentData) {
      child.parentData = _GridParentData();
    }
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final cellWidth = (width - _spacing * (_columns - 1)) / _columns;

    // 1. Cari tinggi card tertinggi.
    var maxHeight = 0.0;
    var child = firstChild;
    while (child != null) {
      final h = child.getMaxIntrinsicHeight(cellWidth);
      if (h > maxHeight) maxHeight = h;
      child = childAfter(child);
    }

    // 2. Layout semua card dengan tinggi itu, susun per baris.
    var index = 0;
    child = firstChild;
    while (child != null) {
      child.layout(
        BoxConstraints.tightFor(width: cellWidth, height: maxHeight),
      );
      final col = index % _columns;
      final row = index ~/ _columns;
      (child.parentData! as _GridParentData).offset = Offset(
        col * (cellWidth + _spacing),
        row * (maxHeight + _spacing),
      );
      index++;
      child = childAfter(child);
    }

    final rows = (index / _columns).ceil();
    size = constraints.constrain(
      Size(width, rows == 0 ? 0 : rows * maxHeight + (rows - 1) * _spacing),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
