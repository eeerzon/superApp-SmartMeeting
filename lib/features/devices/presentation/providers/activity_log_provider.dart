import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/activity_entry.dart';
import '../../domain/entities/device_type.dart';

DateTime _today(int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

class ActivityLogController extends Notifier<List<ActivityEntry>> {
  static const _maxEntries = 50;

  @override
  List<ActivityEntry> build() => [
        ActivityEntry(time: _today(8, 55), actor: 'Administrator', message: 'Menjalankan scene Mulai Meeting'),
        ActivityEntry(time: _today(8, 52), actor: 'Rina Kartika', message: 'Pintu Utama dibuka dengan kartu', deviceType: DeviceType.door),
        ActivityEntry(time: _today(8, 41), actor: 'Sistem', message: 'Pintu Utama dikunci otomatis', deviceType: DeviceType.door),
        ActivityEntry(time: _today(8, 30), actor: 'Rina Kartika', message: 'AC 001 diatur ke 22°C', deviceType: DeviceType.ac),
        ActivityEntry(time: _today(8, 12), actor: 'Sistem', message: 'IFP 002 terputus dari jaringan', deviceType: DeviceType.ifp),
      ];

  void add(ActivityEntry entry) => state = [entry, ...state].take(_maxEntries).toList();
}

final activityLogProvider =
    NotifierProvider<ActivityLogController, List<ActivityEntry>>(ActivityLogController.new);
