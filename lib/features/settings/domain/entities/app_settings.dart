import '../../../../core/config/env.dart';

enum ScreenDimTimeout {
  min1('1 mnt'),
  min5('5 mnt'),
  min10('10 mnt'),
  never('Tidak');

  const ScreenDimTimeout(this.label);
  final String label;
}

enum AutoLogout {
  min5('5 mnt'),
  min15('15 mnt'),
  min30('30 mnt');

  const AutoLogout(this.label);
  final String label;
}

enum AppLanguage {
  id('Indonesia'),
  en('English');

  const AppLanguage(this.label);
  final String label;
}

class AppSettings {
  const AppSettings({
    this.roomId = Env.roomId,
    this.screenDim = ScreenDimTimeout.min5,
    this.kioskMode = true,
    this.screenBrightness = 80,
    this.confirmCriticalActions = true,
    this.autoLogout = AutoLogout.min15,
    this.touchSound = true,
    this.language = AppLanguage.id,
    this.apiBaseUrl = Env.apiBaseUrl,
    this.mqttBrokerUrl = Env.mqttHost,
  });

  final String roomId;
  final ScreenDimTimeout screenDim;
  final bool kioskMode;
  final int screenBrightness;
  final bool confirmCriticalActions;
  final AutoLogout autoLogout;
  final bool touchSound;
  final AppLanguage language;
  final String apiBaseUrl;
  final String mqttBrokerUrl;

  AppSettings copyWith({
    String? roomId,
    ScreenDimTimeout? screenDim,
    bool? kioskMode,
    int? screenBrightness,
    bool? confirmCriticalActions,
    AutoLogout? autoLogout,
    bool? touchSound,
    AppLanguage? language,
    String? apiBaseUrl,
    String? mqttBrokerUrl,
  }) {
    return AppSettings(
      roomId: roomId ?? this.roomId,
      screenDim: screenDim ?? this.screenDim,
      kioskMode: kioskMode ?? this.kioskMode,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      confirmCriticalActions: confirmCriticalActions ?? this.confirmCriticalActions,
      autoLogout: autoLogout ?? this.autoLogout,
      touchSound: touchSound ?? this.touchSound,
      language: language ?? this.language,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      mqttBrokerUrl: mqttBrokerUrl ?? this.mqttBrokerUrl,
    );
  }
}
