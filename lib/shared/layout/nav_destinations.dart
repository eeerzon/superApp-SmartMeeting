import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Order must match the branches in app_router.dart.
const navDestinations = [
  NavDestination('Dashboard', Icons.grid_view_outlined, Icons.grid_view_rounded),
  NavDestination('Perangkat', Icons.devices_other_outlined, Icons.devices_other_rounded),
  NavDestination('Pengaturan', Icons.tune_outlined, Icons.tune_rounded),
  NavDestination('User', Icons.person_outline_rounded, Icons.person_rounded),
];
