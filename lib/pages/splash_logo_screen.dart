import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smart_meeting_controller/pages/dashboard.dart';
import 'package:smart_meeting_controller/pages/login_room.dart';
import 'package:smart_meeting_controller/services/storage_services.dart';

class SplashLogoPage extends StatefulWidget {
  const SplashLogoPage({super.key});

  @override
  State<SplashLogoPage> createState() => _SplashLogoPageState();
}

class _SplashLogoPageState extends State<SplashLogoPage> {
  String appVersion = '';
  String? langCode;
  String? token;
  Map<String, dynamic>? getUserData;
  bool isTokenValid = false;
  Map<String, dynamic>? bahasa;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadVersion();

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _navigate();
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      appVersion = 'v${info.version}';
    });
  }

  /// Sudah punya token ruangan → dashboard. Belum → halaman input kode.
  Future<void> _navigate() async {
    final token = await StorageService.getToken();
    if (!mounted) return;
    bool hasToken = token != null && token.isNotEmpty;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasToken ? const DashboardPage() : const LoginRoom(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/Logo-Onesia.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 20,
            child: Text(
              appVersion.isNotEmpty ? appVersion : '',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
