import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/about_section.dart';
import '../widgets/connection_section.dart';
import '../widgets/display_section.dart';
import '../widgets/room_binding_section.dart';
import '../widgets/security_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppLayout.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pengaturan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          SizedBox(height: 4),
          Text(
            'Konfigurasi tablet ini dan koneksinya ke sistem IoT',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RoomBindingSection(),
                    SizedBox(height: AppLayout.gap),
                    ConnectionSection(),
                  ],
                ),
              ),
              SizedBox(width: AppLayout.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DisplaySection(),
                    SizedBox(height: AppLayout.gap),
                    SecuritySection(),
                    SizedBox(height: AppLayout.gap),
                    AboutSection(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
