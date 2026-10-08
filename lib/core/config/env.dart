/// Build-time configuration, passed with `--dart-define`.
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ruangmeeting.local/v1',
  );
  static const mqttHost = String.fromEnvironment(
    'MQTT_HOST',
    defaultValue: 'mqtt://10.10.1.5:1883',
  );
  static const roomId = String.fromEnvironment('ROOM_ID', defaultValue: 'inovasi');
}
