import 'package:flutter/material.dart';

// const String baseUrl = 'https://smartmeeting.onesia.id';
const String baseUrl = 'http://192.168.69.196:8090';

/// Navigator global, dipakai untuk pindah halaman dari luar widget
/// (mis. token dicabut → kembali ke halaman input kode).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
