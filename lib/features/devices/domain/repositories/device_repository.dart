import '../entities/device.dart';

class DeviceCommandException implements Exception {
  const DeviceCommandException(this.message);
  final String message;
}

abstract interface class DeviceRepository {
  Future<List<Device>> fetchRoomDevices(String roomId);

  /// Sends the desired state of [device]. Throws [DeviceCommandException].
  Future<void> sendCommand(Device device);

  /// Returns true when the device answers a heartbeat.
  Future<bool> ping(String deviceId);
}
