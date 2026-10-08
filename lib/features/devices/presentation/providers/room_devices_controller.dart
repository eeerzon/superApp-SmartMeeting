import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/realtime/connection_status.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../scenes/domain/entities/scene.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../domain/entities/activity_entry.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/device_type.dart';
import '../../domain/repositories/device_repository.dart';
import 'activity_log_provider.dart';

enum DeviceLinkStatus { online, pending, syncing, offline }

class CommandResult {
  const CommandResult.ok(this.message) : success = true;
  const CommandResult.failed(this.message) : success = false;

  final bool success;
  final String message;
}

class SceneProgress {
  const SceneProgress({required this.sceneId, required this.done, required this.total});

  final String sceneId;
  final int done;
  final int total;
}

class RoomDevicesState {
  const RoomDevicesState({
    this.devices = const {},
    this.pending = const {},
    this.syncing = const {},
    this.isLoading = true,
    this.serverOnline = true,
    this.activeSceneId,
    this.sceneProgress,
  });

  final Map<String, Device> devices;

  /// Discrete commands waiting for acknowledgement (UI is locked).
  final Set<String> pending;

  /// Optimistic slider/stepper changes not yet sent.
  final Set<String> syncing;

  final bool isLoading;
  final bool serverOnline;
  final String? activeSceneId;
  final SceneProgress? sceneProgress;

  Device device(String id) => devices[id]!;

  List<Device> ofType(DeviceType type) => devices.values.where((d) => d.type == type).toList();

  /// First unit of a type: the one shown on the dashboard.
  T primary<T extends Device>() => devices.values.whereType<T>().first;

  bool isReachable(String id) => serverOnline && (devices[id]?.online ?? false);

  DeviceLinkStatus statusOf(String id) {
    if (!isReachable(id)) return DeviceLinkStatus.offline;
    if (pending.contains(id)) return DeviceLinkStatus.pending;
    if (syncing.contains(id)) return DeviceLinkStatus.syncing;
    return DeviceLinkStatus.online;
  }

  RoomDevicesState copyWith({
    Map<String, Device>? devices,
    Set<String>? pending,
    Set<String>? syncing,
    bool? isLoading,
    bool? serverOnline,
    String? activeSceneId,
    bool clearActiveScene = false,
    SceneProgress? sceneProgress,
    bool clearSceneProgress = false,
  }) {
    return RoomDevicesState(
      devices: devices ?? this.devices,
      pending: pending ?? this.pending,
      syncing: syncing ?? this.syncing,
      isLoading: isLoading ?? this.isLoading,
      serverOnline: serverOnline ?? this.serverOnline,
      activeSceneId: clearActiveScene ? null : (activeSceneId ?? this.activeSceneId),
      sceneProgress: clearSceneProgress ? null : (sceneProgress ?? this.sceneProgress),
    );
  }
}

class RoomDevicesController extends Notifier<RoomDevicesState> {
  final Map<String, Timer> _debounce = {};

  DeviceRepository get _repo => ref.read(deviceRepositoryProvider);

  @override
  RoomDevicesState build() {
    ref.onDispose(() {
      for (final timer in _debounce.values) {
        timer.cancel();
      }
    });
    ref.listen<bool>(serverConnectionProvider, (_, online) {
      state = state.copyWith(serverOnline: online);
    });
    Future.microtask(_load);
    return RoomDevicesState(
      serverOnline: ref.read(serverConnectionProvider),
      activeSceneId: 'meeting',
    );
  }

  Future<void> _load() async {
    final roomId = ref.read(settingsControllerProvider).roomId;
    final list = await _repo.fetchRoomDevices(roomId);
    state = state.copyWith(devices: {for (final d in list) d.id: d}, isLoading: false);
  }

  String? _blockReason(Device device) {
    if (!state.serverOnline) return 'Perintah gagal: koneksi ke server terputus';
    if (!device.online) return '${device.name} sedang offline';
    return null;
  }

  /// Discrete command (toggle, mode, input…). Locks the device UI until the
  /// device acknowledges.
  Future<CommandResult> execute(
    String id,
    Device Function(Device current) update, {
    required String message,
    bool keepScene = false,
  }) async {
    final current = state.device(id);
    final blocked = _blockReason(current);
    if (blocked != null) return CommandResult.failed(blocked);

    state = state.copyWith(pending: {...state.pending, id});
    final next = update(state.device(id));
    try {
      await _repo.sendCommand(next);
      state = state.copyWith(
        devices: {...state.devices, id: next},
        pending: _without(state.pending, id),
        clearActiveScene: !keepScene,
      );
      _log(message, current.type);
      return CommandResult.ok(message);
    } on DeviceCommandException catch (e) {
      state = state.copyWith(pending: _without(state.pending, id));
      return CommandResult.failed(e.message);
    }
  }

  /// Continuous change (slider, stepper). Applied to the UI immediately and
  /// sent after [AppConstants.commandDebounce]. Returns an error message when
  /// the device cannot be reached.
  String? adjust(
    String id,
    Device Function(Device current) update,
    String Function(Device updated) describe,
  ) {
    final current = state.device(id);
    final blocked = _blockReason(current);
    if (blocked != null) return blocked;

    state = state.copyWith(
      devices: {...state.devices, id: update(current)},
      syncing: {...state.syncing, id},
      clearActiveScene: true,
    );
    _debounce[id]?.cancel();
    _debounce[id] = Timer(AppConstants.commandDebounce, () async {
      final latest = state.device(id);
      try {
        await _repo.sendCommand(latest);
        _log(describe(latest), latest.type);
      } on DeviceCommandException {
        // TODO: revert to the last acknowledged state and surface the error.
      }
      state = state.copyWith(syncing: _without(state.syncing, id));
    });
    return null;
  }

  Future<CommandResult> refreshStatus(String id) async {
    if (!state.serverOnline) {
      return const CommandResult.failed('Tidak dapat memeriksa status: koneksi terputus');
    }
    final device = state.device(id);
    state = state.copyWith(pending: {...state.pending, id});
    final alive = await _repo.ping(id);
    state = state.copyWith(pending: _without(state.pending, id));
    return alive
        ? CommandResult.ok('Status ${device.name} diperbarui')
        : CommandResult.failed('${device.name} belum merespons. Periksa daya dan kabel jaringan.');
  }

  /// Applies every action of [scene] device by device, reporting progress.
  Future<CommandResult> applyScene(Scene scene) async {
    if (!state.serverOnline) {
      return const CommandResult.failed('Scene gagal: koneksi ke server terputus');
    }
    final targets = scene.actions.keys.where((id) => state.devices[id]?.online ?? false).toList();
    state = state.copyWith(sceneProgress: SceneProgress(sceneId: scene.id, done: 0, total: targets.length));

    for (var i = 0; i < targets.length; i++) {
      final id = targets[i];
      state = state.copyWith(pending: {...state.pending, id});
      final next = scene.actions[id]!(state.device(id));
      try {
        await _repo.sendCommand(next);
        state = state.copyWith(devices: {...state.devices, id: next});
      } on DeviceCommandException {
        // Skip devices that fail; the rest of the scene still applies.
      }
      state = state.copyWith(
        pending: _without(state.pending, id),
        sceneProgress: SceneProgress(sceneId: scene.id, done: i + 1, total: targets.length),
      );
    }

    state = state.copyWith(
      clearSceneProgress: true,
      activeSceneId: scene.id,
      clearActiveScene: scene.endsMeeting,
    );
    _log('Menjalankan scene ${scene.label}', null);
    return CommandResult.ok('Scene "${scene.label}" diterapkan ke ${targets.length} perangkat');
  }

  void _log(String message, DeviceType? type) {
    ref.read(activityLogProvider.notifier).add(
          ActivityEntry(
            time: DateTime.now(),
            actor: ref.read(authControllerProvider).user?.name ?? 'Sistem',
            message: message,
            deviceType: type,
          ),
        );
  }

  static Set<String> _without(Set<String> set, String id) => {...set}..remove(id);
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) => DeviceRepositoryImpl());

final roomDevicesProvider =
    NotifierProvider<RoomDevicesController, RoomDevicesState>(RoomDevicesController.new);
