import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/managed_user.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Add (when [initial] is null) or edit a user. Returns the result or null.
Future<ManagedUser?> showUserFormDialog(
  BuildContext context, {
  ManagedUser? initial,
  required Set<String> takenEmails,
  required String defaultRoomAccess,
}) {
  return showDialog<ManagedUser>(
    context: context,
    builder: (_) => _UserFormDialog(initial: initial, takenEmails: takenEmails, defaultRoomAccess: defaultRoomAccess),
  );
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({required this.initial, required this.takenEmails, required this.defaultRoomAccess});

  final ManagedUser? initial;
  final Set<String> takenEmails;
  final String defaultRoomAccess;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _email = TextEditingController(text: widget.initial?.email);
  late UserRole _role = widget.initial?.role ?? UserRole.operator;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final base = widget.initial ??
        ManagedUser(
          id: 'u-${DateTime.now().millisecondsSinceEpoch}',
          name: '',
          email: '',
          role: _role,
          roomAccess: widget.defaultRoomAccess,
        );
    Navigator.of(context).pop(base.copyWith(name: _name.text.trim(), email: _email.text.trim(), role: _role));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(16)),
                    child: Icon(
                      _editing ? Icons.edit_outlined : Icons.person_add_alt_1_outlined,
                      size: 26,
                      color: AppColors.red600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _editing ? 'Ubah User' : 'Tambah User',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                const _Label('Nama lengkap'),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'mis. Dewi Lestari'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                const _Label('Email'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: 'nama@perusahaan.com'),
                  validator: (v) {
                    final value = v?.trim().toLowerCase() ?? '';
                    if (value.isEmpty) return 'Email wajib diisi';
                    if (!_emailPattern.hasMatch(value)) return 'Format email tidak valid';
                    if (widget.takenEmails.contains(value)) return 'Email sudah dipakai';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const _Label('Peran'),
                // Three fixed roles: segmented buttons are faster to tap than a dropdown.
                _RoleSegment(selected: _role, onChanged: (r) => setState(() => _role = r)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(onPressed: _submit, child: Text(_editing ? 'Simpan' : 'Tambah')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSegment extends StatelessWidget {
  const _RoleSegment({required this.selected, required this.onChanged});

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final role in UserRole.values)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: role == selected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: role == selected
                      ? const [BoxShadow(color: Color(0x1F101828), blurRadius: 3, offset: Offset(0, 1))]
                      : const [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => onChanged(role),
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          role.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: role == selected ? AppColors.red700 : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}
