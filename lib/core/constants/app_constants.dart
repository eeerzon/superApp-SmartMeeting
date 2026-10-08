abstract final class AppConstants {
  /// Delay before a slider/stepper change is sent to the device.
  static const commandDebounce = Duration(milliseconds: 700);

  /// Simulated round-trip of the mock repositories.
  static const mockCommandLatency = Duration(milliseconds: 650);
  static const mockLoginLatency = Duration(milliseconds: 800);
}
