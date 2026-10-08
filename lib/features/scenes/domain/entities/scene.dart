import '../../../devices/domain/entities/device.dart';

typedef DeviceAction = Device Function(Device current);

/// A preset that sets several devices at once ("Mulai Meeting", ...).
class Scene {
  const Scene({
    required this.id,
    required this.label,
    required this.description,
    required this.actions,
    this.requiresConfirmation = false,
    this.endsMeeting = false,
  });

  final String id;
  final String label;
  final String description;

  /// Device id -> desired state.
  final Map<String, DeviceAction> actions;

  /// Ask before running (e.g. turning everything off).
  final bool requiresConfirmation;

  /// After running, no scene is marked active.
  final bool endsMeeting;
}
