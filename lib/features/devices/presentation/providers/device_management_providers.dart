import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/device_type.dart';

/// Active tab in device management. Also set from the dashboard
/// (e.g. "Kontrol PTZ" opens the camera tab).
final selectedDeviceTypeProvider = StateProvider<DeviceType>((ref) => DeviceType.ifp);

/// Selected unit id per device type; falls back to the first unit.
final selectedUnitsProvider = StateProvider<Map<DeviceType, String>>((ref) => const {});
