import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  /// Primary buttons, active toggles, selected nav item.
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.red600, AppColors.red400],
  );

  /// Login brand panel & room header accent.
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.red900, AppColors.red600, AppColors.red400],
  );

  /// Soft background for selected chips / active device cards.
  static const soft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.red50, AppColors.surface],
  );
}
