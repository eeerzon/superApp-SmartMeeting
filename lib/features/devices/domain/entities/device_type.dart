enum DeviceType {
  ifp('IFP', 'Interactive Flat Panel'),
  ac('AC', 'Air Conditioner'),
  light('Lampu', 'Pencahayaan'),
  audio('Audio', 'Sistem Audio'),
  camera('Kamera', 'Kamera Video Conference'),
  door('Pintu', 'Akses Pintu');

  const DeviceType(this.shortLabel, this.title);

  /// Tab label in device management.
  final String shortLabel;

  /// Card title on the dashboard.
  final String title;
}
