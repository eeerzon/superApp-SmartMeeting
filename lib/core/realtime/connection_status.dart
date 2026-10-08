import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the tablet can reach the backend / MQTT broker.
/// TODO: drive this from RealtimeClient connection events.
class ServerConnectionController extends Notifier<bool> {
  @override
  bool build() => true;

  /// Used by the "simulate offline" toggle in Settings.
  void setOnline(bool online) => state = online;

  Future<bool> reconnect() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    state = true;
    return state;
  }
}

final serverConnectionProvider =
    NotifierProvider<ServerConnectionController, bool>(ServerConnectionController.new);
