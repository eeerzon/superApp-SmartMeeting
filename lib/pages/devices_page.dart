import 'package:flutter/material.dart';
import 'package:smart_meeting_controller/helper/command_dialogs.dart';
import 'package:smart_meeting_controller/services/room_service.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key, this.initialDeviceId, this.onBack});

  /// Perangkat yang langsung dibuka (mis. dari klik card di dashboard).
  /// Null = perangkat pertama.
  final String? initialDeviceId;

  /// Kembali ke halaman sebelumnya. Tombol back disembunyikan kalau null.
  final VoidCallback? onBack;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  // Data dari GET /api/v1/remote/room
  Map<String, dynamic>? _room;
  bool _kendaliTersedia = true;
  String? _kendaliPesan;
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;
  String? _error;

  // Data dari GET /api/v1/remote/devices/state, per id_perangkat.
  Map<String, Map<String, dynamic>> _states = {};
  DateTime? _statesUpdatedAt;
  bool _loadingStates = false;

  /// Pesan kalau status gagal dimuat (mis. mini PC tidak terhubung).
  String? _stateError;

  /// Tab = kategori perangkat (mis. "Display", "Keamanan").
  String? _tab;

  /// id_perangkat yang sedang dibuka di panel.
  String? _selectedId;

  /// id_perangkat yang sedang menunggu balasan perintah → label perintahnya.
  final Map<String, String> _pending = {};

  /// Nilai slider yang sedang digeser / dikirim, per "id_perangkat:kode".
  final Map<String, double> _sliderDrafts = {};

  /// Alur hit API:
  /// 1. Halaman dibuka → GET /remote/room (daftar perangkat → tab), lalu
  ///    GET /remote/devices/state untuk detail tab yang terbuka.
  /// 2. Tab diklik → GET /remote/devices/state lagi (detail terbaru).
  /// 3. Tombol "Segarkan status" / tarik layar → muat ulang.
  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? const Color(0xFFD6322C) : null,
          behavior: SnackBarBehavior.floating,
          width: 380,
          duration: Duration(milliseconds: error ? 3600 : 2400),
        ),
      );
  }

  // ---------------- LOAD DATA ----------------

  Future<void> _loadRoom() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await RoomService.fetchRoom();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (!result.success) {
        _error = result.message;
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

      // Pilih perangkat awal: dari dashboard, yang sedang dibuka, atau yang pertama.
      final wanted = _selectedId ?? widget.initialDeviceId;
      final initial =
          _devices.where((d) => d['id_perangkat'] == wanted).firstOrNull ??
              _devices.firstOrNull;
      _selectedId = initial?['id_perangkat'] as String?;
      _tab = initial == null ? null : _kategori(initial);
    });

    // Detail status untuk tab yang terbuka.
    if (_error == null) _loadStates();
  }

  Future<void> _loadStates() async {
    if (_devices.isEmpty || _loadingStates) return;
    setState(() => _loadingStates = true);

    final result = await RoomService.fetchDeviceStates();
    if (!mounted) return;

    setState(() {
      _loadingStates = false;
      if (!result.success) {
        // Mis. MINIPC_TIDAK_TERHUBUNG (503): perangkat tetap tampil, status tidak diketahui.
        _states = {};
        _statesUpdatedAt = null;
        _stateError = result.message;
        return;
      }
      _stateError = null;
      final list = (result.data?['devices'] as List? ?? [])
          .whereType<Map<String, dynamic>>();
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

  // ---------------- HELPER DATA ----------------

  String _kategori(Map<String, dynamic> d) =>
      d['kategori']?.toString() ?? 'Lainnya';

  /// Daftar tab sesuai urutan perangkat dari API (sudah urut per kategori).
  List<String> get _tabs {
    final tabs = <String>[];
    for (final d in _devices) {
      final k = _kategori(d);
      if (!tabs.contains(k)) tabs.add(k);
    }
    return tabs;
  }

  List<Map<String, dynamic>> get _tabDevices =>
      _devices.where((d) => _kategori(d) == _tab).toList();

  Map<String, dynamic>? get _selected =>
      _devices.where((d) => d['id_perangkat'] == _selectedId).firstOrNull;

  bool _isOffline(Map<String, dynamic> d) {
    final state = _states[d['id_perangkat']];
    return state != null &&
        state['dipantau'] != false &&
        state['online'] != true;
  }

  IconData _kategoriIcon(String kategori) {
    final k = kategori.toLowerCase();
    if (k.contains('display')) return Icons.cast_rounded;
    if (k.contains('keamanan')) return Icons.sensor_door_outlined;
    if (k.contains('audio')) return Icons.speaker_outlined;
    if (k.contains('kamera')) return Icons.videocam_outlined;
    if (k.contains('ac') || k.contains('pendingin')) {
      return Icons.ac_unit_rounded;
    }
    if (k.contains('lampu') || k.contains('cahaya')) {
      return Icons.lightbulb_outline_rounded;
    }
    return Icons.devices_other_outlined;
  }

  IconData _deviceIcon(Map<String, dynamic> d) {
    switch (d['jenis_kontrol']) {
      case 'ifp':
        return Icons.cast_rounded;
      case 'pintu':
        return Icons.sensor_door_outlined;
    }
    return _kategoriIcon(_kategori(d));
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

  /// Klik tab → tampilkan perangkat kategori itu & ambil detail statusnya.
  void _selectTab(String tab) {
    setState(() {
      _tab = tab;
      _selectedId = _tabDevices.firstOrNull?['id_perangkat'] as String?;
    });
    _loadStates();
  }

  // ---------------- KIRIM PERINTAH ----------------

  /// Tombol di panel selalu milik perangkat yang sedang dibuka.
  void _onCommandTap(Map<String, dynamic> perintah) {
    final device = _selected;
    if (device != null) _runCommand(device, perintah);
  }

  /// POST /remote/devices/{id}/commands: konfirmasi (kalau diminta), isian
  /// parameter (kalau ada & belum diisi), kirim, lalu tunggu hasilnya.
  /// [parameter] diisi langsung oleh slider, jadi dialog isian dilewati.
  Future<bool> _runCommand(
    Map<String, dynamic> device,
    Map<String, dynamic> perintah, {
    Map<String, dynamic>? parameter,
  }) async {
    final id = device['id_perangkat'] as String;
    final kode = perintah['kode'] as String;
    final label = perintah['label']?.toString() ?? kode;
    if (_pending.containsKey(id)) return false;

    if (perintah['konfirmasi'] == true) {
      final ok = await showConfirmDialog(
        context,
        title: '$label ${device['nama']}?',
        message: 'Perintah akan langsung dikirim ke perangkat.',
        confirmLabel: label,
      );
      if (!ok || !mounted) return false;
    }

    final paramSpec = perintah['parameter'];
    if (parameter == null &&
        paramSpec is Map<String, dynamic> &&
        paramSpec.isNotEmpty) {
      parameter = await showParameterDialog(
        context,
        label,
        paramSpec,
        state: _states[id],
      );
      if (parameter == null || !mounted) return false;
    }

    // Selama menunggu (bisa sampai 40 detik), tombol perangkat ini dikunci.
    setState(() => _pending[id] = label);
    final result =
        await RoomService.sendCommand(id, kode, parameter: parameter);
    if (!mounted) return false;
    setState(() => _pending.remove(id));

    if (result.success) {
      _toast(result.message ?? '${device['nama']}: $label berhasil');
      // Status setelah perintah (kalau dikirim mini PC), lalu muat ulang sekali.
      final newState = result.data?['state'];
      if (newState is Map<String, dynamic>) {
        setState(() => _states[id] = {...?_states[id], ...newState});
      }
      _loadStates();
      return true;
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
    return false;
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFFD6322C),
      onRefresh: _loadRoom,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.onBack != null) ...[
                  Tooltip(
                    message: 'Kembali',
                    child: _roundIconButton(
                      Icons.arrow_back_rounded,
                      onTap: widget.onBack!,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manajemen Perangkat',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _room == null
                            ? 'Detail setiap perangkat di ruangan ini'
                            : 'Detail setiap perangkat di ${_room!['nama_ruangan']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_statesUpdatedAt != null)
                  Text(
                    'Status diperbarui '
                    '${_statesUpdatedAt!.hour.toString().padLeft(2, '0')}:'
                    '${_statesUpdatedAt!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _devices.isEmpty) {
      return _placeholder(
        icon: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFFD6322C),
          ),
        ),
        text: 'Memuat data perangkat…',
      );
    }

    if (_error != null) {
      return _placeholder(
        icon: const Icon(
          Icons.cloud_off_rounded,
          size: 32,
          color: Color(0xFFD6322C),
        ),
        text: _error!,
        action: _ghostButton(Icons.refresh_rounded, 'Coba lagi', _loadRoom),
      );
    }

    final device = _selected;
    if (_devices.isEmpty || device == null) {
      return _placeholder(
        icon: Icon(
          Icons.devices_other_outlined,
          size: 32,
          color: Colors.grey.shade400,
        ),
        text: 'Belum ada perangkat aktif di ruangan ini',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabs(),
        const SizedBox(height: 16),
        if (!_kendaliTersedia) ...[
          _alert(
            icon: Icons.warning_amber_rounded,
            title: 'Kendali tidak tersedia',
            text: _kendaliPesan ?? 'Mini PC ruangan tidak bisa dihubungi.',
            warning: true,
          ),
          const SizedBox(height: 12),
        ],
        _buildPanel(device),
      ],
    );
  }

  // ---------------- TABS ----------------

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E8EC)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final tab in _tabs) _tabButton(tab)],
        ),
      ),
    );
  }

  Widget _tabButton(String tab) {
    final selected = _tab == tab;
    final color = selected ? Colors.white : Colors.grey.shade700;
    final devices = _devices.where((d) => _kategori(d) == tab);
    final hasOffline = devices.any(_isOffline);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => _selectTab(tab),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD6322C) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(_kategoriIcon(tab), size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                '$tab (${devices.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (hasOffline) ...[
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Daftar perangkat dalam satu kategori, sebagai baris tab di atas panel.
  Widget _buildUnitTabs() {
    final units = _tabDevices;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < units.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            SizedBox(width: 260, child: _unitTile(units[i])),
          ],
        ],
      ),
    );
  }

  Widget _unitTile(Map<String, dynamic> d) {
    final selected = d['id_perangkat'] == _selectedId;
    return InkWell(
      onTap: () => setState(() => _selectedId = d['id_perangkat'] as String),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4F4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFD6322C) : const Color(0xFFE7E8EC),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFF7F7F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _deviceIcon(d),
                size: 20,
                color:
                    selected ? const Color(0xFFD6322C) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d['nama']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'SN ${d['sn'] ?? '-'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            _statusBadge(d),
          ],
        ),
      ),
    );
  }

  /// Badge status dari /devices/state: Online, Offline, Mati, Hibernasi,
  /// Tidak dipantau, atau "?" kalau status belum diketahui.
  Widget _statusBadge(Map<String, dynamic> d) {
    final state = _states[d['id_perangkat']];
    var label = _loadingStates && state == null ? 'Memuat…' : 'Tidak diketahui';
    var icon = Icons.help_outline_rounded;
    var fg = Colors.grey.shade600;
    var bg = const Color(0xFFF7F7F8);
    final pendingLabel = _pending[d['id_perangkat']];

    if (pendingLabel != null) {
      return _badge(
        '$pendingLabel…',
        Icons.sync_rounded,
        const Color(0xFFB45309),
        const Color(0xFFFFFBEB),
      );
    }

    if (state != null && state['dipantau'] == false) {
      label = 'Tidak dipantau';
      icon = Icons.visibility_off_outlined;
    } else if (state != null && state['online'] != true) {
      label = 'Offline';
      icon = Icons.wifi_off_rounded;
      fg = const Color(0xFFD6322C);
      bg = const Color(0xFFFFF4F4);
    } else if (state != null) {
      switch (state['daya']) {
        case 'off':
          label = 'Mati';
          icon = Icons.power_settings_new_rounded;
        case 'hibernate':
          label = 'Hibernasi';
          icon = Icons.bedtime_outlined;
          fg = const Color(0xFFB45309);
          bg = const Color(0xFFFFFBEB);
        default:
          label = 'Online';
          icon = Icons.check_rounded;
          fg = const Color(0xFF16A34A);
          bg = const Color(0xFFEAF7EE);
      }
    }

    return _badge(label, icon, fg, bg);
  }

  Widget _badge(String label, IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PANEL DETAIL ----------------

  Widget _buildPanel(Map<String, dynamic> d) {
    final state = _states[d['id_perangkat']];
    final perintah = (d['perintah'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUnitTabs(),
          const SizedBox(height: 20),
          _panelHeader(d),
          const SizedBox(height: 16),
          ..._stateAlerts(d, state),
          ..._buildControls(d, perintah, state),
        ],
      ),
    );
  }

  Widget _panelHeader(Map<String, dynamic> d) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: d['bisa_dikontrol'] == true
                ? const Color(0xFFD6322C)
                : const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: _pending.containsKey(d['id_perangkat'])
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _deviceIcon(d),
                  color: d['bisa_dikontrol'] == true
                      ? Colors.white
                      : Colors.grey.shade500,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${d['nama']}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _statusBadge(d),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _kategori(d),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        _ghostButton(
          Icons.refresh_rounded,
          _loadingStates ? 'Memuat status…' : 'Segarkan status',
          _loadingStates ? null : _loadStates,
        ),
      ],
    );
  }

  /// Peringatan di atas panel sesuai status perangkat.
  List<Widget> _stateAlerts(
    Map<String, dynamic> d,
    Map<String, dynamic>? state,
  ) {
    Widget? alert;
    if (state == null && _stateError != null) {
      alert = _alert(
        icon: Icons.help_outline_rounded,
        title: 'Status tidak diketahui',
        text: _stateError!,
        warning: true,
      );
    } else if (state != null && state['dipantau'] == false) {
      alert = _alert(
        icon: Icons.visibility_off_outlined,
        title: 'Tidak dipantau',
        text: 'Perangkat ini tidak dikenali mini PC, jadi statusnya '
            'tidak bisa dibaca.',
        warning: true,
      );
    } else if (state != null && state['online'] != true) {
      alert = _alert(
        icon: Icons.wifi_off_rounded,
        title: '${d['nama']} tidak terhubung',
        text: 'Periksa daya dan kabel jaringan perangkat.',
      );
    }
    if (alert == null) return const [];
    return [alert, const SizedBox(height: 12)];
  }

  // ---------------- KONTROL ----------------

  /// Kelompok tampilan perintah, dari kode (lebih pasti) lalu `grup`.
  String _groupOf(Map<String, dynamic> p) {
    final kode = '${p['kode']}';
    if (kode.startsWith('power_') ||
        kode == 'wake' ||
        kode == 'hibernate' ||
        kode == 'restart') {
      return 'Daya';
    }
    if (kode.startsWith('volume') || kode == 'mute' || kode == 'unmute') {
      return 'Suara';
    }
    if (kode.startsWith('input_')) return 'Sumber input';
    if (kode.startsWith('picture_')) return 'Mode gambar';
    if (kode.startsWith('contrast_')) return 'Kontras';
    if (kode.startsWith('brightness_')) return 'Kecerahan';
    return p['grup']?.toString() ?? 'Kontrol';
  }

  bool _isOnline(Map<String, dynamic>? state) =>
      state != null && state['dipantau'] != false && state['online'] == true;

  List<Widget> _buildControls(
    Map<String, dynamic> d,
    List<Map<String, dynamic>> perintah,
    Map<String, dynamic>? state,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};
    if (d['bisa_dikontrol'] == true) {
      for (final p in perintah) {
        groups.putIfAbsent(_groupOf(p), () => []).add(p);
      }
    }

    final daya = groups.remove('Daya');
    final tiles = <Widget>[
      for (final entry in groups.entries)
        switch (entry.key) {
          'Suara' => _soundTile(entry.value, state),
          'Sumber input' => _inputTile(entry.value, state),
          'Mode gambar' => _pictureTile(entry.value),
          'Kontras' => _levelTile(
              'Kontras',
              Icons.contrast_rounded,
              'kontras',
              entry.value,
              state,
            ),
          'Kecerahan' => _levelTile(
              'Kecerahan',
              Icons.wb_sunny_outlined,
              'kecerahan',
              entry.value,
              state,
            ),
          _ => _genericTile(entry.key, entry.value, state),
        },
      _infoTile(d, state),
      if (d['bisa_dikontrol'] != true || perintah.isEmpty)
        _tile(
          icon: Icons.block_rounded,
          title: 'Kontrol',
          subtitle: d['bisa_dikontrol'] != true
              ? 'Perangkat belum bisa dikontrol dari aplikasi'
              : 'Tidak ada perintah untuk perangkat ini',
        ),
    ];

    // Selama perintah dikirim, semua kontrol perangkat ini dikunci & diredupkan.
    final pending = _pending.containsKey(d['id_perangkat']);
    return [
      IgnorePointer(
        ignoring: pending,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: pending ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (daya != null) ...[
                _powerCard(d, daya, state),
                const SizedBox(height: 14),
              ],
              _tileGrid(tiles),
            ],
          ),
        ),
      ),
    ];
  }

  /// Grid 2 kolom (1 kolom di layar sempit); tile satu baris sama tinggi.
  Widget _tileGrid(List<Widget> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 720 ? 2 : 1;
        return Column(
          children: [
            for (var i = 0; i < tiles.length; i += columns) ...[
              if (i > 0) const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: 14),
                      Expanded(
                        child: i + c < tiles.length
                            ? tiles[i + c]
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ---------------- DAYA ----------------

  Widget _powerCard(
    Map<String, dynamic> d,
    List<Map<String, dynamic>> perintah,
    Map<String, dynamic>? state,
  ) {
    final daya = _isOnline(state) ? state!['daya'] : null;
    final subtitle = switch (daya) {
      'on' => 'Menyala',
      'off' => 'Mati',
      'hibernate' => 'Hibernasi, layar mati dan bangun cepat',
      _ => _isOnline(state) ? 'Online' : 'Status tidak diketahui',
    };

    // Perintah yang mewakili status daya diurutkan dulu: Hidup, Hibernasi, Mati.
    const order = ['power_on', 'hibernate', 'power_off', 'wake', 'restart'];
    final sorted = [...perintah]..sort((a, b) {
        final ia = order.indexOf('${a['kode']}');
        final ib = order.indexOf('${b['kode']}');
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E8EC)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 14,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status ${d['nama']}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in sorted)
                _pill(
                  icon: switch ('${p['kode']}') {
                    'hibernate' => Icons.bedtime_outlined,
                    'wake' => Icons.wb_twilight_rounded,
                    'restart' => Icons.restart_alt_rounded,
                    _ => Icons.power_settings_new_rounded,
                  },
                  label: switch ('${p['kode']}') {
                    'power_on' => 'Hidup',
                    'power_off' => 'Mati',
                    _ => '${p['label']}',
                  },
                  selected: _isActive(p, state),
                  onTap: () => _onCommandTap(p),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- TILE GRUP ----------------

  Widget _soundTile(
    List<Map<String, dynamic>> perintah,
    Map<String, dynamic>? state,
  ) {
    final online = _isOnline(state);
    final volume = online ? state!['volume'] as num? : null;
    final bisu = online && state!['bisu'] == true;
    final slider = perintah.where(_hasParameter).firstOrNull;
    final buttons = perintah.where((p) => !_hasParameter(p)).toList();

    return _tile(
      icon: bisu ? Icons.volume_off_rounded : Icons.volume_up_rounded,
      title: 'Suara',
      subtitle: bisu ? 'Sedang dibisukan' : 'Volume speaker layar',
      trailing: _bigValue(volume == null ? '-' : '${volume.round()}', '/100'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (slider != null) _parameterSlider(slider, state),
          if (buttons.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in buttons)
                  _pill(
                    icon: p['kode'] == 'mute'
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    label: '${p['label']}',
                    selected: _isActive(p, state),
                    onTap: () => _onCommandTap(p),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _inputTile(
    List<Map<String, dynamic>> perintah,
    Map<String, dynamic>? state,
  ) {
    final active = perintah.where((p) => _isActive(p, state)).firstOrNull;
    return _tile(
      icon: Icons.settings_input_hdmi_rounded,
      title: 'Sumber Input',
      subtitle: active != null
          ? 'Aktif: ${active['label']}'
          : _isOnline(state) && state!['input'] != null
              ? 'Aktif: ${state['input']}'
              : 'Pilih sumber tampilan layar',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in perintah) _inputButton(p, selected: p == active),
        ],
      ),
    );
  }

  Widget _pictureTile(List<Map<String, dynamic>> perintah) {
    return _tile(
      icon: Icons.palette_outlined,
      title: 'Mode Gambar',
      subtitle: 'Preset warna & ketajaman layar',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in perintah)
            _pill(
              icon: switch ('${p['kode']}') {
                'picture_bright' => Icons.wb_sunny_outlined,
                'picture_clear' => Icons.contrast_rounded,
                'picture_custom' => Icons.tune_rounded,
                _ => Icons.adjust_rounded,
              },
              label: '${p['label']}',
              selected: false,
              onTap: () => _onCommandTap(p),
            ),
        ],
      ),
    );
  }

  /// Kontras / kecerahan: [−] bar nilai [+] dan tombol reset.
  Widget _levelTile(
    String title,
    IconData icon,
    String stateKey,
    List<Map<String, dynamic>> perintah,
    Map<String, dynamic>? state,
  ) {
    final value = _isOnline(state) ? state![stateKey] as num? : null;
    Map<String, dynamic>? find(String suffix) =>
        perintah.where((p) => '${p['kode']}'.endsWith(suffix)).firstOrNull;
    final down = find('_down');
    final up = find('_up');
    final reset = find('_reset');
    final others =
        perintah.where((p) => p != down && p != up && p != reset).toList();

    return _tile(
      icon: icon,
      title: title,
      subtitle: 'Atur bertahap, 0–100',
      trailing: _bigValue(value == null ? '-' : '${value.round()}', ''),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (down != null)
                _circleButton(Icons.remove_rounded, () => _onCommandTap(down)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value == null ? 0 : (value / 100).clamp(0, 1),
                    minHeight: 10,
                    color: const Color(0xFFD6322C),
                    backgroundColor: const Color(0xFFF2F3F5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (up != null)
                _circleButton(Icons.add_rounded, () => _onCommandTap(up)),
            ],
          ),
          if (reset != null || others.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in [if (reset != null) reset, ...others])
                  _pill(
                    icon: _hasParameter(p)
                        ? Icons.tune_rounded
                        : Icons.restart_alt_rounded,
                    label: '${p['label']}',
                    selected: false,
                    onTap: () => _onCommandTap(p),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Grup yang belum punya tampilan khusus: pill biasa.
  Widget _genericTile(
    String title,
    List<Map<String, dynamic>> perintah,
    Map<String, dynamic>? state,
  ) {
    return _tile(
      icon: Icons.tune_rounded,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in perintah.where((p) => !_hasParameter(p)))
                _pill(
                  icon: Icons.play_arrow_rounded,
                  label: '${p['label']}',
                  selected: _isActive(p, state),
                  onTap: () => _onCommandTap(p),
                ),
            ],
          ),
          for (final p in perintah.where(_hasParameter))
            _parameterSlider(p, state),
        ],
      ),
    );
  }

  Widget _infoTile(Map<String, dynamic> d, Map<String, dynamic>? state) {
    final kondisi = d['kondisi']?.toString() ?? '-';
    final suhu = _isOnline(state) ? state!['suhu'] : null;
    return _tile(
      icon: Icons.info_outline_rounded,
      title: 'Informasi Perangkat',
      subtitle: _kategori(d),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _infoChip(Icons.qr_code_2_rounded, 'Nomor seri', '${d['sn'] ?? '-'}'),
          _infoChip(Icons.lan_outlined, 'Alamat IP', '${d['ip'] ?? '-'}'),
          _infoChip(
            Icons.health_and_safety_outlined,
            'Kondisi',
            _capitalize(kondisi),
            color: switch (kondisi) {
              'baik' => const Color(0xFF16A34A),
              'maintenance' => const Color(0xFFB45309),
              'rusak' => const Color(0xFFD6322C),
              _ => null,
            },
          ),
          _infoChip(
            Icons.memory_rounded,
            'Jenis kontrol',
            '${d['jenis_kontrol'] ?? '-'}',
          ),
          if (suhu != null)
            _infoChip(Icons.thermostat_rounded, 'Suhu', '$suhu°C'),
        ],
      ),
    );
  }

  bool _hasParameter(Map<String, dynamic> p) =>
      p['parameter'] is Map && (p['parameter'] as Map).isNotEmpty;

  /// Tandai perintah yang sesuai status saat ini, mis. input aktif atau daya.
  bool _isActive(Map<String, dynamic> p, Map<String, dynamic>? state) {
    if (!_isOnline(state)) return false;
    final kode = '${p['kode']}';
    if (kode.startsWith('input_') && state!['input'] != null) {
      return _inputKey(kode) == _inputKey('${state['input']}');
    }
    return switch (kode) {
      'power_on' => state!['daya'] == 'on',
      'power_off' => state!['daya'] == 'off',
      'hibernate' => state!['daya'] == 'hibernate',
      'mute' => state!['bisu'] == true,
      'unmute' => state!['bisu'] == false,
      _ => false,
    };
  }

  /// Contoh: `input_hdmi1`, `HDMI1`, `HDMI 1` → `HDMI1`.
  String _inputKey(String value) => value
      .toLowerCase()
      .replaceFirst('input_', '')
      .replaceAll(RegExp('[^a-z0-9]'), '')
      .toUpperCase();

  /// Slider untuk perintah ber-parameter (mis. volume_set), mulai dari nilai
  /// status saat ini (`parameter.value.state`, mis. "volume").
  /// Nilai dikirim sekali saat slider dilepas.
  Widget _parameterSlider(
    Map<String, dynamic> p,
    Map<String, dynamic>? state,
  ) {
    final device = _selected;
    final spec = p['parameter'] as Map<String, dynamic>;
    final paramName = spec.keys.first;
    final param = spec[paramName] as Map<String, dynamic>;
    final min = (param['min'] as num? ?? 0).toDouble();
    final max = (param['max'] as num? ?? 100).toDouble();
    final current = _isOnline(state) ? state![param['state']] as num? : null;
    final key = '${device?['id_perangkat']}:${p['kode']}';
    final value = (_sliderDrafts[key] ?? current ?? min).toDouble();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        activeTrackColor: const Color(0xFFD6322C),
        inactiveTrackColor: const Color(0xFFF2F3F5),
        thumbColor: const Color(0xFFD6322C),
        disabledActiveTrackColor: const Color(0xFFD6322C),
        disabledInactiveTrackColor: const Color(0xFFF2F3F5),
        disabledThumbColor: const Color(0xFFD6322C),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: (max - min).round(),
        label: '${value.round()}',
        onChanged: device == null || !_isOnline(state)
            ? null
            : (v) => setState(() => _sliderDrafts[key] = v),
        onChangeEnd: device == null || !_isOnline(state)
            ? null
            : (v) async {
                await _runCommand(
                  device,
                  p,
                  parameter: {paramName: v.round()},
                );
                // Berhasil: nilai ikut status terbaru. Gagal: kembali ke nilai lama.
                if (mounted) setState(() => _sliderDrafts.remove(key));
              },
      ),
    );
  }

  // ---------------- KOMPONEN TILE ----------------

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFD6322C)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }

  Widget _bigValue(String value, String suffix) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text: suffix,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// Pill bulat dengan icon di lingkaran, seperti tombol Status IFP.
  Widget _pill({
    required IconData icon,
    required String label,
    required bool selected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 6, right: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4F4) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFD6322C) : const Color(0xFFE7E8EC),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFFD6322C), Color(0xFFEF5350)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : const Color(0xFFF2F3F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    selected ? const Color(0xFFD6322C) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _inputIcon(String kode) {
    if (kode.contains('android')) return Icons.android_rounded;
    if (kode.contains('vga')) return Icons.settings_input_component_rounded;
    if (kode.contains('wireless') || kode.contains('cast')) {
      return Icons.cast_rounded;
    }
    return Icons.settings_input_hdmi_rounded;
  }

  Widget _inputButton(Map<String, dynamic> p, {required bool selected}) {
    final color = selected ? const Color(0xFFD6322C) : Colors.grey.shade700;
    return InkWell(
      onTap: () => _onCommandTap(p),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 132,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4F4) : const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFD6322C) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(_inputIcon('${p['kode']}'), size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              '${p['label']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE7E8EC), width: 1.5),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- KOMPONEN ----------------

  Widget _alert({
    required IconData icon,
    required String title,
    required String text,
    bool warning = false,
  }) {
    final fg = warning ? const Color(0xFF92400E) : const Color(0xFFC20014);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFFBEB) : const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warning ? const Color(0xFFFDE68A) : const Color(0xFFFFE5E6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: TextStyle(fontSize: 13.5, color: fg, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder({
    required Widget icon,
    required String text,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }

  Widget _roundIconButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE7E8EC), width: 1.5),
        ),
        child: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
    );
  }

  Widget _ghostButton(IconData icon, String label, VoidCallback? onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        minimumSize: const Size(0, 44),
        side: const BorderSide(color: Color(0xFFE7E8EC), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
