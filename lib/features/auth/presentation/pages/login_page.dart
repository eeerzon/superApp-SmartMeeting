import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/login_brand_panel.dart';
import '../widgets/login_form.dart';

/// Landscape split: red brand panel (left) + email/password form (right).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 21, child: LoginBrandPanel()),
          Expanded(
            flex: 20,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: LoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
