import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/managed_user.dart';

/// "Kelola User": search, list, active toggle and edit.
class UserManagementCard extends StatefulWidget {
  const UserManagementCard({
    super.key,
    required this.users,
    required this.currentUserId,
    required this.onAdd,
    required this.onEdit,
    required this.onToggleActive,
  });

  final List<ManagedUser> users;
  final String? currentUserId;
  final VoidCallback onAdd;
  final ValueChanged<ManagedUser> onEdit;
  final void Function(ManagedUser user, bool active) onToggleActive;

  @override
  State<UserManagementCard> createState() => _UserManagementCardState();
}

class _UserManagementCardState extends State<UserManagementCard> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = widget.users
        .where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();
    final activeCount = widget.users.where((u) => u.active).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.group_outlined, size: 20, color: AppColors.red600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kelola User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      '${widget.users.length} pengguna terdaftar · $activeCount aktif',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _AddButton(onTap: widget.onAdd),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Cari nama atau email',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 6),
          const _HeaderRow(),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'Tidak ada user yang cocok dengan "$_query".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            for (var i = 0; i < filtered.length; i++) ...[
              if (i > 0) const Divider(),
              _UserRow(
                user: filtered[i],
                isSelf: filtered[i].id == widget.currentUserId,
                onEdit: () => widget.onEdit(filtered[i]),
                onToggle: (v) => widget.onToggleActive(filtered[i], v),
              ),
            ],
        ],
      ),
    );
  }
}

const _colRole = 110.0;
const _colRooms = 170.0;
const _colActive = 72.0;
const _colAction = 52.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  static const _style = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: const Row(
        children: [
          Expanded(child: Text('NAMA', style: _style)),
          SizedBox(width: _colRole, child: Text('PERAN', style: _style)),
          SizedBox(width: _colRooms, child: Text('AKSES RUANGAN', style: _style)),
          SizedBox(width: _colActive, child: Text('AKTIF', style: _style)),
          SizedBox(width: _colAction),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.isSelf, required this.onEdit, required this.onToggle});

  final ManagedUser user;
  final bool isSelf;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final muted = !user.active;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: user.name,
                          children: [
                            if (isSelf)
                              const TextSpan(
                                text: ' (Anda)',
                                style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: muted ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: _colRole, child: Align(alignment: Alignment.centerLeft, child: _RoleBadge(role: user.role))),
          SizedBox(
            width: _colRooms,
            child: Text(
              user.roomAccess,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: muted ? AppColors.textSecondary : AppColors.textPrimary),
            ),
          ),
          SizedBox(
            width: _colActive,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: isSelf ? 'Tidak dapat menonaktifkan akun sendiri' : (user.active ? 'Nonaktifkan' : 'Aktifkan'),
                child: Switch(value: user.active, onChanged: isSelf ? null : onToggle),
              ),
            ),
          ),
          SizedBox(
            width: _colAction,
            child: IconButton(
              tooltip: 'Ubah ${user.name}',
              onPressed: onEdit,
              style: IconButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.5),
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, gradient) = switch (role) {
      UserRole.admin => (null, Colors.white, AppGradients.primary),
      UserRole.operator => (AppColors.red50, AppColors.red700, null),
      UserRole.guest => (AppColors.background, AppColors.textSecondary, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, gradient: gradient, borderRadius: BorderRadius.circular(999)),
      child: Text(role.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: AppColors.redShadow, blurRadius: 16, spreadRadius: -8, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: const SizedBox(
            height: 44,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1_outlined, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Tambah User', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
