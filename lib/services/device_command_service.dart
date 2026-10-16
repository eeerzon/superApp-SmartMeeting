import 'dart:async';

import 'package:smart_meeting_controller/services/api_services.dart';
import 'package:smart_meeting_controller/services/storage_services.dart';

/// ID perangkat di ruangan. Sesuaikan dengan ID dari backend.
abstract final class DeviceIds {
  static const ac = 'AC-01';
  static const light = 'LMP-01';
  static const audio = 'AUD-01';
  static const panel = 'IFP-01';
  static const door = 'DR-01';
  static const camera = 'CAM-01';
}

/// Daftar perintah yang dikirim ke backend. [code] adalah nilai `command` di body request.
enum DeviceCommand {
  // AC
  turnOnAc('turn_on_ac'),
  turnOffAc('turn_off_ac'),
  tempUp('temp_up'),
  tempDown('temp_down'),
  setAcModeCool('set_ac_mode_cool'),
  setAcModeHeat('set_ac_mode_heat'),
  setAcModeFan('set_ac_mode_fan'),
  setAcModeAuto('set_ac_mode_auto'),
  setAcModeDry('set_ac_mode_dry'),
  setFanSpeed('set_fan_speed'), // value: low | med | high | auto
  setAcSwing('set_ac_swing'), // value: true | false
  setAcTimer('set_ac_timer'), // value: off | 30 | 60 | end

  // Lampu
  turnOnLight('turn_on_light'),
  turnOffLight('turn_off_light'),
  setBrightness('set_brightness'), // value: 0-100
  setLightColor(
    'set_light_color',
  ), // value: warm | natural | cool | teal | violet
  setLightZone(
    'set_light_zone',
  ), // value: {zone: depan | tengah | belakang, on: bool}

  // Audio
  turnOnAudio('turn_on_audio'),
  turnOffAudio('turn_off_audio'),
  setVolume('set_volume'), // value: 0-100
  setMicLevel('set_mic_level'), // value: 0-100
  muteMic('mute_mic'),
  unmuteMic('unmute_mic'),
  setAudioPreset(
    'set_audio_preset',
  ), // value: rapat | presentasi | video | musik
  testSound('test_sound'),

  // Interactive Flat Panel
  turnOnPanel('turn_on_panel'),
  turnOffPanel('turn_off_panel'),
  hibernatePanel('hibernate_panel'),
  setPanelSource('set_panel_source'), // value: hdmi_1 | hdmi_2 | vga | wireless
  setPanelVolume('set_panel_volume'), // value: 0-100
  setPanelMode('set_panel_mode'), // value: standar | jelas | cerah | custom
  setPanelBrightness('set_panel_brightness'), // value: 0-100

  // Pintu
  lockDoor('lock_door'),
  unlockDoor('unlock_door'),
  setAutoLock('set_auto_lock'), // value: true | false
  setAutoLockDelay('set_auto_lock_delay'), // value: 10 | 30 | 60 (detik)
  setAccessMethod('set_access_method'), // value: kartu | pin | both

  // Kamera
  turnOnCamera('turn_on_camera'),
  turnOffCamera('turn_off_camera'),
  setCameraMode('set_camera_mode'), // value: auto | speaker | manual
  moveCamera('move_camera'), // value: up | down | left | right | home
  setCameraZoom('set_camera_zoom'), // value: 1-5
  setCameraPreset(
    'set_camera_preset',
  ), // value: ruangan | presenter | whiteboard

  // Scene
  sceneStartMeeting('scene_start_meeting'),
  scenePresentation('scene_presentation'),
  sceneVideoCall('scene_video_call'),
  sceneEndMeeting('scene_end_meeting'),

  // Lainnya
  refreshStatus('refresh_status');

  const DeviceCommand(this.code);

  final String code;
}

class CommandResult {
  const CommandResult.ok([this.message = 'Berhasil']) : success = true;
  const CommandResult.failed(this.message) : success = false;

  final bool success;
  final String message;
}

class DeviceCommandService {
  /// `true` selama endpoint backend belum siap: perintah hanya disimulasikan.
  static bool useMock = true;

  // TODO: sesuaikan path & format body dengan endpoint dari tim backend.
  static const _endpoint = '/api/devices/command';

  static const _mockDelay = Duration(milliseconds: 650);

  /// Kirim satu perintah ke perangkat dan tunggu balasan (ack) dari backend.
  static Future<CommandResult> send(
    String deviceId,
    DeviceCommand command, {
    Object? value,
  }) async {
    if (useMock) {
      await Future.delayed(_mockDelay);
      return const CommandResult.ok();
    }

    final response = await ApiService.post(
      _endpoint,
      token: await StorageService.getToken(),
      body: {
        'device_id': deviceId,
        'command': command.code,
        if (value != null) 'value': value,
      },
    );

    if (response?['success'] == true) {
      return CommandResult.ok(response?['message']?.toString() ?? 'Berhasil');
    }
    return CommandResult.failed(
      response?['message']?.toString() ?? 'Perintah gagal dikirim',
    );
  }

  static final Map<String, Timer> _debounceTimers = {};

  /// Untuk kontrol yang bisa ditekan beruntun (stepper): hanya nilai terakhir
  /// yang dikirim setelah [delay] tanpa perubahan.
  static void sendDebounced(
    String deviceId,
    DeviceCommand command, {
    required Object value,
    Duration delay = const Duration(milliseconds: 500),
    void Function(CommandResult result)? onResult,
  }) {
    final key = '$deviceId:${command.code}';
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, () async {
      _debounceTimers.remove(key);
      final result = await send(deviceId, command, value: value);
      onResult?.call(result);
    });
  }
}
