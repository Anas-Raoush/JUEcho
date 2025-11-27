import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}
class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String value) {
    final regex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)'
      r'(?=.*[!@#\$%^&*()_\-+=\[{\]};:"\\|,.<>/?]).{8,}$',
    );
    return regex.hasMatch(value);
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final oldPassword = _oldCtrl.text.trim();
    final newPassword = _newCtrl.text.trim();

    try {
      await ProfileRepository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthNotAuthorizedException {
      setState(() {
        _error = 'Your current password is incorrect.';
      });
    } on InvalidPasswordException {
      setState(() {
        _error =
        'Password must be at least 8 characters and include an uppercase letter,\n'
            'a lowercase letter, a number, and a special character.';
      });
    } on LimitExceededException {
      setState(() {
        _error = 'Too many attempts. Please wait a little while and try again.';
      });
    } catch (_) {
      setState(() {
        _error = 'Could not change password. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      backgroundColor: AppColors.white,
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 420),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Center(
        child: const Text(
          'Change Your password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.red, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            _passwordField(
              controller: _oldCtrl,
              label: 'Enter your old password',
              validator: (v) {
                if ((v ?? '').isEmpty) {
                  return 'Please enter your old password';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _newCtrl,
              label: 'Enter your new password',
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) {
                  return 'Please enter a new password';
                }
                if (!_isStrongPassword(value)) {
                  return 'Weak password';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _confirmCtrl,
              label: 'Confirm your new password',
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newCtrl.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
              : const Text('Change'),
        ),],),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}