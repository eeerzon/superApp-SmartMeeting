import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/mock_device_datasource.dart';

/// Mock implementation with simulated latency.
/// TODO: REST snapshot via DeviceRemoteDataSource + commands/state over
/// DeviceRealtimeDataSource (MQTT/WebSocket).
class DeviceRepositoryImpl implements DeviceRepository {
  final Map<String, Device> _store = {for (final d in mockRoomDevices()) d.id: d};

  @override
  Future<List<Device>> fetchRoomDevices(String roomId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _store.values.toList();
  }

  @override
  Future<void> sendCommand(Device device) async {
    await Future<void>.delayed(AppConstants.mockCommandLatency);
    final known = _store[device.id];
    if (known == null || !known.online) {
      throw DeviceCommandException('${device.name} tidak merespons');
    }
    _store[device.id] = device;
  }

  @override
  Future<bool> ping(String deviceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    return _store[deviceId]?.online ?? false;
  }
}
