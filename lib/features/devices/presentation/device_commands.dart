import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../settings/presentation/providers/settings_controller.dart';
import '../domain/entities/device.dart';
import 'providers/room_devices_controller.dart';

// Glue between widgets and RoomDevicesController: send + show feedback.

void showCommandResult(BuildContext context, CommandResult result, {bool silentSuccess = false}) {
  if (!context.mounted || (result.success && silentSuccess)) return;
  showAppToast(context, result.message, kind: result.success ? ToastKind.success : ToastKind.error);
}

/// Discrete command with success/error toast.
Future<void> sendDeviceCommand(
  BuildContext context,
  WidgetRef ref, {
  required String deviceId,
  required Device Function(Device current) update,
  required String message,
}) async {
  final result = await ref.read(roomDevicesProvider.notifier).execute(deviceId, update, message: message);
  if (context.mounted) showCommandResult(context, result);
}

/// Continuous change (slider/stepper): error toast only.
void adjustDevice(
  BuildContext context,
  WidgetRef ref, {
  required String deviceId,
  required Device Function(Device current) update,
  required String Function(Device updated) describe,
}) {
  final error = ref.read(roomDevicesProvider.notifier).adjust(deviceId, update, describe);
  if (error != null) showAppToast(context, error, kind: ToastKind.error);
}

/// Lock/unlock with confirmation (when enabled in Settings).
Future<void> setDoorLocked(BuildContext context, WidgetRef ref, DoorDevice door, {required bool lock}) async {
  if (door.locked == lock) return;
  if (ref.read(settingsControllerProvider).confirmCriticalActions) {
    final confirmed = await showConfirmDialog(
      context,
      title: lock ? 'Kunci pintu?' : 'Buka kunci pintu?',
      message: lock
          ? 'Peserta dari luar tidak dapat masuk tanpa kartu akses.'
          : 'Pintu akan terbuka dan ruangan dapat diakses siapa saja.'
              '${door.autoLock ? ' Pintu terkunci lagi otomatis ${door.autoLockDelay.seconds} detik setelah tertutup.' : ''}',
      confirmLabel: lock ? 'Kunci Pintu' : 'Buka Pintu',
      icon: lock ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
      destructive: !lock,
    );
    if (!confirmed || !context.mounted) return;
  }
  final result = await ref.read(roomDevicesProvider.notifier).execute(
        door.id,
        (d) => (d as DoorDevice).copyWith(locked: lock),
        message: '${door.name} ${lock ? 'dikunci' : 'dibuka'}',
        keepScene: true,
      );
  if (context.mounted) showCommandResult(context, result);
}
