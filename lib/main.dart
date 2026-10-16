import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_meeting_controller/helper/global_var.dart';
import 'package:smart_meeting_controller/pages/login_room.dart';
import 'package:smart_meeting_controller/pages/splash_logo_screen.dart';
import 'package:smart_meeting_controller/services/api_services.dart';
import 'package:smart_meeting_controller/services/storage_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  ApiService.onUnauthorized = _handleUnauthorized;
  runApp(const MyApp());
}

bool _isLoggingOut = false;

/// Token ruangan dicabut admin: hapus token, kembali ke halaman input kode.
Future<void> _handleUnauthorized() async {
  if (_isLoggingOut) return;
  _isLoggingOut = true;
  await StorageService.removeToken();
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const LoginRoom(
        message: 'Akses ruangan sudah dicabut. Masukkan kode setup terbaru.',
      ),
    ),
    (_) => false,
  );
  _isLoggingOut = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.orange,
          selectionColor: Color(0x33FFA500),
          selectionHandleColor: Colors.orange,
        ),
      ),
      locale: const Locale('id'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      debugShowCheckedModeBanner: false,
      home: const SplashLogoPage(),
    );
  }
}
