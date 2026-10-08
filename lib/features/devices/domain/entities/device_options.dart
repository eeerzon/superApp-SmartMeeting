// Selectable options per device. Labels are shown as-is in the UI.

enum AcMode {
  cool('Cool'),
  heat('Heat'),
  fan('Fan'),
  auto('Auto'),
  dry('Dry');

  const AcMode(this.label);
  final String label;
}

enum FanSpeed {
  low('Rendah'),
  medium('Sedang'),
  high('Tinggi'),
  auto('Otomatis');

  const FanSpeed(this.label);
  final String label;
}

enum AutoOffTimer {
  off('Tidak'),
  min30('30 menit'),
  hour1('1 jam'),
  meetingEnd('Akhir meeting');

  const AutoOffTimer(this.label);
  final String label;
}

enum IfpPower {
  on('Hidup'),
  hibernate('Hibernasi'),
  off('Mati');

  const IfpPower(this.label);
  final String label;
}

enum DisplayMode {
  standard('Standar'),
  clear('Jelas'),
  bright('Cerah'),
  custom('Custom');

  const DisplayMode(this.label);
  final String label;
}

enum InputSource {
  hdmi1('HDMI 1'),
  hdmi2('HDMI 2'),
  vga('VGA'),
  wireless('Wireless');

  const InputSource(this.label);
  final String label;
}

enum LightColor {
  warm('Warm White', 0xFFFFD9A8),
  natural('Natural', 0xFFFFF3DC),
  cool('Cool White', 0xFFDCEBFF),
  teal('Teal', 0xFF5EEAD4),
  violet('Violet', 0xFFC4B5FD);

  const LightColor(this.label, this.argb);
  final String label;

  /// Swatch color as ARGB int (domain stays Flutter-free).
  final int argb;
}

enum LightZone {
  front('Depan'),
  middle('Tengah'),
  back('Belakang');

  const LightZone(this.label);
  final String label;
}

enum AudioPreset {
  meeting('Rapat'),
  presentation('Presentasi'),
  videoCall('Video Call'),
  music('Musik');

  const AudioPreset(this.label);
  final String label;
}

enum CameraMode {
  autoFraming('Auto framing'),
  speakerTracking('Speaker tracking'),
  manual('Manual');

  const CameraMode(this.label);
  final String label;
}

enum CameraPreset {
  room('Seluruh ruangan'),
  presenter('Presenter'),
  whiteboard('Whiteboard');

  const CameraPreset(this.label);
  final String label;
}

enum DoorAccessMethod {
  card('Kartu akses'),
  pin('PIN'),
  cardAndPin('Kartu + PIN');

  const DoorAccessMethod(this.label);
  final String label;
}

enum AutoLockDelay {
  s10('10 detik', 10),
  s30('30 detik', 30),
  s60('60 detik', 60);

  const AutoLockDelay(this.label, this.seconds);
  final String label;
  final int seconds;
}
