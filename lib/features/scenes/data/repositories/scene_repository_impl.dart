import '../../../devices/data/datasources/mock_device_datasource.dart';
import '../../../devices/domain/entities/device.dart';
import '../../../devices/domain/entities/device_options.dart';
import '../../domain/entities/scene.dart';
import '../../domain/repositories/scene_repository.dart';

/// Built-in presets. TODO: load room-specific scenes from the backend.
class SceneRepositoryImpl implements SceneRepository {
  @override
  List<Scene> presets() => [
        Scene(
          id: 'meeting',
          label: 'Mulai Meeting',
          description: 'AC 22°, lampu 80%, IFP HDMI 1',
          actions: {
            DeviceIds.ac1: (d) => (d as AcDevice).copyWith(power: true, temperature: 22, mode: AcMode.cool),
            DeviceIds.light1: (d) => (d as LightDevice).copyWith(power: true, brightness: 80, color: LightColor.natural),
            DeviceIds.audio1: (d) => (d as AudioDevice)
                .copyWith(power: true, volume: 60, micLevel: 80, micMuted: false, preset: AudioPreset.meeting),
            DeviceIds.ifp1: (d) => (d as IfpDevice).copyWith(power: IfpPower.on, input: InputSource.hdmi1),
          },
        ),
        Scene(
          id: 'presentation',
          label: 'Presentasi',
          description: 'Lampu redup 40%, layar cerah',
          actions: {
            DeviceIds.light1: (d) => (d as LightDevice).copyWith(power: true, brightness: 40, color: LightColor.warm),
            DeviceIds.ifp1: (d) => (d as IfpDevice).copyWith(power: IfpPower.on, displayMode: DisplayMode.bright),
            DeviceIds.audio1: (d) => (d as AudioDevice).copyWith(power: true, volume: 55, preset: AudioPreset.presentation),
          },
        ),
        Scene(
          id: 'video',
          label: 'Video Call',
          description: 'Kamera & mic aktif, lampu 75%',
          actions: {
            DeviceIds.camera1: (d) => (d as CameraDevice).copyWith(power: true, mode: CameraMode.autoFraming),
            DeviceIds.audio1: (d) => (d as AudioDevice)
                .copyWith(power: true, volume: 60, micLevel: 85, micMuted: false, preset: AudioPreset.videoCall),
            DeviceIds.light1: (d) => (d as LightDevice).copyWith(power: true, brightness: 75, color: LightColor.natural),
            DeviceIds.ifp1: (d) => (d as IfpDevice).copyWith(power: IfpPower.on, input: InputSource.wireless),
          },
        ),
        Scene(
          id: 'end',
          label: 'Selesai',
          description: 'Matikan semua & kunci pintu',
          requiresConfirmation: true,
          endsMeeting: true,
          actions: {
            DeviceIds.ac1: (d) => (d as AcDevice).copyWith(power: false),
            DeviceIds.light1: (d) => (d as LightDevice).copyWith(power: false),
            DeviceIds.audio1: (d) => (d as AudioDevice).copyWith(power: false),
            DeviceIds.ifp1: (d) => (d as IfpDevice).copyWith(power: IfpPower.off),
            DeviceIds.camera1: (d) => (d as CameraDevice).copyWith(power: false),
            DeviceIds.door1: (d) => (d as DoorDevice).copyWith(locked: true),
          },
        ),
      ];
}
