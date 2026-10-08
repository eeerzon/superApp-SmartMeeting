const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _two(int v) => v.toString().padLeft(2, '0');

/// 09:05
String formatHm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// Kamis, 8 Oktober 2026
String formatLongDate(DateTime t) =>
    '${_days[t.weekday - 1]}, ${t.day} ${_months[t.month - 1]} ${t.year}';

/// pagi / siang / sore / malam
String greetingFor(DateTime t) {
  final h = t.hour;
  if (h < 11) return 'pagi';
  if (h < 15) return 'siang';
  if (h < 18) return 'sore';
  return 'malam';
}
