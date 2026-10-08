import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifier of this tablet as registered on the server.
const kTabletId = 'TAB-INV-01';

class MeetingRoom {
  const MeetingRoom({required this.id, required this.name, required this.floor});

  final String id;
  final String name;
  final String floor;
}

const kMeetingRooms = [
  MeetingRoom(id: 'inovasi', name: 'Ruang Inovasi', floor: 'Lantai 3'),
  MeetingRoom(id: 'kolaborasi', name: 'Ruang Kolaborasi', floor: 'Lantai 2'),
  MeetingRoom(id: 'direksi', name: 'Ruang Direksi', floor: 'Lantai 5'),
];

MeetingRoom roomById(String id) =>
    kMeetingRooms.firstWhere((r) => r.id == id, orElse: () => kMeetingRooms.first);

class MeetingInfo {
  const MeetingInfo({required this.title, required this.timeRange, required this.isLive});

  final String title;
  final String timeRange;
  final bool isLive;
}

/// TODO: replace with the room calendar from the backend.
final currentMeetingProvider = Provider<MeetingInfo>(
  (ref) => const MeetingInfo(
    title: 'Rapat Koordinasi Q4',
    timeRange: '09:00 – 11:00 WIB',
    isLive: true,
  ),
);
