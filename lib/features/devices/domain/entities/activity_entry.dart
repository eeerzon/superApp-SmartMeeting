import 'device_type.dart';

/// One line in the activity log (commands, scenes, system events).
class ActivityEntry {
  const ActivityEntry({
    required this.time,
    required this.actor,
    required this.message,
    this.deviceType,
  });

  final DateTime time;
  final String actor;
  final String message;

  /// Null for room-wide events such as scenes.
  final DeviceType? deviceType;
}
