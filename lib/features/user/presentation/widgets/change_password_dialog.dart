import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/repositories/user_repository.dart';

/// Returns true when the password was changed.
Future<bool> showChangePasswordDialog(BuildContext context, {required UserRepository repository}) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => _ChangePasswordDialog(repository: repository),
  );
  return changed ?? false;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.repository});

  final UserRepository repository;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  static const _minLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.changePassword(current: _current.text, next: _next.text);
      if (mounted) Navigator.of(context).pop(true);
    } on UserException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  Widget _field(String label, TextEditingController controller, String? Function(String?) validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(controller: controller, obscureText: true, validator: validator),
        ],
      ),
    );
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
                    child: const Icon(Icons.key_rounded, size: 26, color: AppColors.red600),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Ubah Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                _field('Password saat ini', _current, (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                _field(
                  'Password baru',
                  _next,
                  (v) => (v == null || v.length < _minLength) ? 'Minimal $_minLength karakter' : null,
                ),
                _field(
                  'Ulangi password baru',
                  _confirm,
                  (v) => v != _next.text ? 'Konfirmasi password tidak sama' : null,
                ),
                if (_error != null)
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red700),
                      const SizedBox(width: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.red700, fontSize: 13)),
                    ],
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Simpan'),
                      ),
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
