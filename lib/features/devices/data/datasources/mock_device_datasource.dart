import '../../domain/entities/device.dart';
import '../../domain/entities/device_options.dart';

/// Device ids of the demo room. Also used by scene presets.
abstract final class DeviceIds {
  static const ifp1 = 'IFP-01';
  static const ifp2 = 'IFP-02';
  static const ac1 = 'AC-01';
  static const light1 = 'LMP-01';
  static const audio1 = 'AUD-01';
  static const camera1 = 'CAM-01';
  static const door1 = 'DR-01';
}

/// Seed data for the prototype. Order = display order; the first unit of
/// each type is the one shown on the dashboard.
List<Device> mockRoomDevices() => const [
      IfpDevice(id: DeviceIds.ifp1, name: 'IFP 001', location: 'Dinding depan', volume: 48),
      IfpDevice(
        id: DeviceIds.ifp2,
        name: 'IFP 002',
        location: 'Dinding samping',
        online: false,
        lastSeen: '08:12',
        power: IfpPower.off,
        volume: 30,
        brightness: 60,
      ),
      AcDevice(id: DeviceIds.ac1, name: 'AC 001', location: 'Plafon tengah'),
      LightDevice(id: DeviceIds.light1, name: 'Lampu Utama', location: 'Seluruh ruangan'),
      AudioDevice(id: DeviceIds.audio1, name: 'Speaker Ruangan', location: 'Plafon'),
      CameraDevice(id: DeviceIds.camera1, name: 'Kamera Utama', location: 'Atas IFP 001'),
      DoorDevice(id: DeviceIds.door1, name: 'Pintu Utama', location: 'Pintu masuk'),
    ];
