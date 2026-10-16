// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_meeting_controller/helper/loading_page.dart';
import 'package:smart_meeting_controller/pages/dashboard.dart';
import 'package:smart_meeting_controller/services/room_service.dart';

class RoomTokenFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll('-', '').toUpperCase();

    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i == 4) buffer.write('-');
      buffer.write(raw[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class LoginRoom extends StatefulWidget {
  const LoginRoom({
    super.key,
    this.message,
  });

  /// Pesan awal, mis. saat token dicabut admin.
  final String? message;

  @override
  State<LoginRoom> createState() => _LoginRoomState();
}

class _LoginRoomState extends State<LoginRoom> {
  final controller = TextEditingController();
  late String? errorMessage = widget.message;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/Logo-Onesia.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Masukkan kode setup ruangan',
                ),
                const SizedBox(
                  height: 8,
                ),
                TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    RoomTokenFormatter(),
                    LengthLimitingTextInputFormatter(9),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) {
                    if (errorMessage != null) {
                      setState(() => errorMessage = null);
                    }
                  },
                  onSubmitted: (_) => _onNext(),
                  decoration: InputDecoration(
                    hintText: 'XXXX-XXXX',
                    errorText: errorMessage,
                    errorMaxLines: 3,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    // Kode lengkap: XXXX-XXXX (9 karakter).
                    final hasValue = value.text.trim().length == 9;
                    return ElevatedButton(
                      onPressed: hasValue ? _onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.red.shade100,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Next'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    final code = controller.text.trim();
    if (code.length != 9) return;

    FocusScope.of(context).unfocus();
    showLoadingDialog(context, 'Menghubungkan ruangan...');

    final result = await RoomService.pair(code);

    if (!mounted) return;
    hideLoadingDialog(context);

    if (!result.success) {
      setState(() => errorMessage = result.message);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }
}
