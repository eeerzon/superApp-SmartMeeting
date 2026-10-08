import 'device_options.dart';
import 'device_type.dart';

/// A controllable device in the meeting room. Each subtype is immutable and
/// exposes `copyWith`; commands are expressed as "current -> desired state".
sealed class Device {
  const Device({
    required this.id,
    required this.name,
    required this.location,
    this.online = true,
    this.lastSeen,
  });

  final String id;
  final String name;
  final String location;
  final bool online;

  /// Last heartbeat (HH:mm) when the device is offline.
  final String? lastSeen;

  DeviceType get type;

  /// Powered on. Doors have no power state and are always "active".
  bool get isOn;
}

final class IfpDevice extends Device {
  const IfpDevice({
    required super.id,
    required super.name,
    required super.location,
    super.online,
    super.lastSeen,
    this.power = IfpPower.on,
    this.volume = 50,
    this.displayMode = DisplayMode.standard,
    this.brightness = 70,
    this.input = InputSource.hdmi1,
  });

  final IfpPower power;
  final int volume;
  final DisplayMode displayMode;
  final int brightness;
  final InputSource input;

  @override
  DeviceType get type => DeviceType.ifp;

  @override
  bool get isOn => power == IfpPower.on;

  IfpDevice copyWith({
    bool? online,
    IfpPower? power,
    int? volume,
    DisplayMode? displayMode,
    int? brightness,
    InputSource? input,
  }) {
    return IfpDevice(
      id: id,
      name: name,
      location: location,
      lastSeen: lastSeen,
      online: online ?? this.online,
      power: power ?? this.power,
      volume: volume ?? this.volume,
      displayMode: displayMode ?? this.displayMode,
      brightness: brightness ?? this.brightness,
      input: input ?? this.input,
    );
  }
}

final class AcDevice extends Device {
  const AcDevice({
    required super.id,
    required super.name,
    required super.location,
    super.online,
    super.lastSeen,
    this.power = true,
    this.temperature = 22,
    this.mode = AcMode.cool,
    this.fanSpeed = FanSpeed.auto,
    this.swing = true,
    this.autoOff = AutoOffTimer.meetingEnd,
  });

  static const minTemperature = 16;
  static const maxTemperature = 30;

  final bool power;
  final int temperature;
  final AcMode mode;
  final FanSpeed fanSpeed;
  final bool swing;
  final AutoOffTimer autoOff;

  @override
  DeviceType get type => DeviceType.ac;

  @override
  bool get isOn => power;

  AcDevice copyWith({
    bool? online,
    bool? power,
    int? temperature,
    AcMode? mode,
    FanSpeed? fanSpeed,
    bool? swing,
    AutoOffTimer? autoOff,
  }) {
    return AcDevice(
      id: id,
      name: name,
      location: location,
      lastSeen: lastSeen,
      online: online ?? this.online,
      power: power ?? this.power,
      temperature: temperature ?? this.temperature,
      mode: mode ?? this.mode,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      swing: swing ?? this.swing,
      autoOff: autoOff ?? this.autoOff,
    );
  }
}

final class LightDevice extends Device {
  const LightDevice({
    required super.id,
    required super.name,
    required super.location,
    super.online,
    super.lastSeen,
    this.power = true,
    this.brightness = 70,
    this.color = LightColor.warm,
    this.zones = const {LightZone.front, LightZone.middle, LightZone.back},
  });

  final bool power;
  final int brightness;
  final LightColor color;
  final Set<LightZone> zones;

  @override
  DeviceType get type => DeviceType.light;

  @override
  bool get isOn => power;

  LightDevice copyWith({
    bool? online,
    bool? power,
    int? brightness,
    LightColor? color,
    Set<LightZone>? zones,
  }) {
    return LightDevice(
      id: id,
      name: name,
      location: location,
      lastSeen: lastSeen,
      online: online ?? this.online,
      power: power ?? this.power,
      brightness: brightness ?? this.brightness,
      color: color ?? this.color,
      zones: zones ?? this.zones,
    );
  }
}

final class AudioDevice extends Device {
  const AudioDevice({
    required super.id,
    required super.name,
    required super.location,
    super.online,
    super.lastSeen,
    this.power = true,
    this.volume = 65,
    this.micLevel = 80,
    this.micMuted = false,
    this.preset = AudioPreset.meeting,
  });

  final bool power;
  final int volume;
  final int micLevel;
  final bool micMuted;
  final AudioPreset preset;

  @override
  DeviceType get type => DeviceType.audio;

  @override
  bool get isOn => power;

  AudioDevice copyWith({
    bool? online,
    bool? power,
    int? volume,
    int? micLevel,
    bool? micMuted,
    AudioPreset? preset,
  }) {
    return AudioDevice(
      id: id,
      name: name,
      location: location,
      lastSeen: lastSeen,
      online: online ?? this.online,
      power: power ?? this.power,
      volume: volume ?? this.volume,
      micLevel: micLevel ?? this.micLevel,
      micMuted: micMuted ?? this.micMuted,
      preset: preset ?? this.preset,
    );
  }
}

final class CameraDevice extends Device {
  const CameraDevice({
    required super.id,
    required super.name,
    required super.location,
    super.online,
    super.lastSeen,
    this.power = false,
    this.mode = CameraMode.autoFraming,
    this.preset = CameraPreset.room,
    this.zoom = 1,
  });

  static const minZoom = 1;
  static const maxZoom = 5;

  final bool power;
  final CameraMode mode;
  final CameraPreset preset;
  final int zoom;

  @override
  DeviceType get type => DeviceType.camera;

  @override
  bool get isOn => power;

  CameraDevice copyWith({
    bool? online,
    bool? power,
    CameraMode? mode,
    CameraPreset? preset,
    int? zoom,
  }) {
    return CameraDevice(
      id: id,
      name: name,
      location: location,
      lastSeen: lastSeen,
      online: online ?? this.online,
      power: power ?? this.power,
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
      zoom: zoom ?? this.zoom,
    );
  }
}

final class DoorDevice extends Device {
  const DoorDevice({
    required super.id,
    required super.name,
    required super.location,
    super.online,
    super.lastSeen,
    this.locked = true,
    this.autoLock = true,
    this.autoLockDelay = AutoLockDelay.s30,
    this.accessMethod = DoorAccessMethod.card,
  });

  final bool locked;
  final bool autoLock;
  final AutoLockDelay autoLockDelay;
  final DoorAccessMethod accessMethod;

  @override
  DeviceType get type => DeviceType.door;

  @override
  bool get isOn => true;

  DoorDevice copyWith({
    bool? online,
    bool? locked,
    bool? autoLock,
    AutoLockDelay? autoLockDelay,
    DoorAccessMethod? accessMethod,
  }) {
    return DoorDevice(
      id: id,
      name: name,
      location: location,
      lastSeen: lastSeen,
      online: online ?? this.online,
      locked: locked ?? this.locked,
      autoLock: autoLock ?? this.autoLock,
      autoLockDelay: autoLockDelay ?? this.autoLockDelay,
      accessMethod: accessMethod ?? this.accessMethod,
    );
  }
}
