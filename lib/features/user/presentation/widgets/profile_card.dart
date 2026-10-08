import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/time_format.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
    required this.roomName,
    required this.onChangePassword,
    required this.onLogout,
  });

  final User user;
  final String roomName;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 130,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(height: 88, decoration: const BoxDecoration(gradient: AppGradients.brand)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surface, width: 4),
                      boxShadow: const [
                        BoxShadow(color: AppColors.redShadow, blurRadius: 20, spreadRadius: -8, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Center(child: _RoleChip(role: user.role)),
                const SizedBox(height: 14),
                _InfoRow(label: 'Ruangan', value: roomName),
                _InfoRow(label: 'Masuk sejak', value: 'Hari ini, ${formatHm(user.signedInAt)}'),
                const _InfoRow(label: 'Metode masuk', value: 'Email & password'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onChangePassword,
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: const Text('Ubah Password'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red700,
                    backgroundColor: AppColors.red50,
                    side: const BorderSide(color: AppColors.red100, width: 1.5),
                  ),
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(999)),
      child: Text(role.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
