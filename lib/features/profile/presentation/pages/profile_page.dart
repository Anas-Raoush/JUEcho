import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';
import 'package:juecho/features/profile/presentation/widgets/change_password_dialog.dart';
import 'package:juecho/features/profile/presentation/widgets/labeled_field.dart';

/// General user profile page for viewing/updating basic personal information.
///
/// What it shows:
/// - First name (editable)
/// - Last name (editable)
/// - Email (read-only)
/// - Buttons:
///   - Save Changes (updates DB + local provider cache)
///   - Change Password (opens ChangePasswordDialog)
///
/// Data source:
/// - AuthProvider.profile (cached ProfileData)
///
/// Save flow:
/// 1) Validate form
/// 2) ProfileRepository.updateNames(...) updates backend record
/// 3) AuthProvider.updateLocalNames(...) updates cached profile to instantly refresh UI
/// 4) Show success SnackBar
///
/// Responsive behavior:
/// - Uses LayoutBuilder + maxWidth constraint to avoid stretched UI on wide screens.
/// - First/Last name become:
///   - stacked on small widths (< 520)
///   - two columns on normal widths
/// - Buttons become full-width on small screens.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const routeName = '/general-profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _didPrefill = false;

  bool _isSaving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Prefill only once when profile becomes available.
    if (_didPrefill) return;

    final p = context.read<AuthProvider>().profile;
    if (p == null) return;

    _firstNameCtrl.text = p.firstName;
    _lastNameCtrl.text = p.lastName;
    _emailCtrl.text = p.email;

    _didPrefill = true;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Width clamp to keep form readable on tablet/web.
  double _maxWidthFor(double w) {
    if (w >= 1200) return 900;
    if (w >= 900) return 820;
    if (w >= 700) return 650;
    return double.infinity;
  }

  /// Slight padding reduction on very small screens.
  EdgeInsets _paddingFor(double w) {
    final horizontal = w < 380 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 8);
  }

  /// Saves updated names.
  ///
  /// Steps:
  /// 1) Validate inputs
  /// 2) Update backend (source of truth) via ProfileRepository.updateNames
  /// 3) Update AuthProvider cached profile via updateLocalNames for instant UI refresh
  /// 4) Show a success SnackBar
  Future<void> _saveNames() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    try {
      await ProfileRepository.updateNames(
        firstName: firstName,
        lastName: lastName,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateLocalNames(
        firstName: firstName,
        lastName: lastName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not save profile. Please try again later.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Opens the change password dialog.
  Future<void> _onChangePasswordPressed() async {
    await showDialog(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    // If profile is null -> auth bootstrap not finished yet.
    final isLoading = profile == null;

    return GeneralScaffoldWithMenu(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final maxWidth = _maxWidthFor(w);

          final isSmall = w < 520;
          final buttonWidth = isSmall ? double.infinity : 220.0;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: _paddingFor(w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageTitle(title: 'Personal Information'),

                    // Prefer provider error, fallback to local.
                    ErrorMessage(error: auth.error ?? _error),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (isSmall) ...[
                            LabeledField(
                              label: 'First Name',
                              controller: _firstNameCtrl,
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            LabeledField(
                              label: 'Last Name',
                              controller: _lastNameCtrl,
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: LabeledField(
                                    label: 'First Name',
                                    controller: _firstNameCtrl,
                                    validator: (v) => (v ?? '')
                                        .trim()
                                        .isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: LabeledField(
                                    label: 'Last Name',
                                    controller: _lastNameCtrl,
                                    validator: (v) => (v ?? '')
                                        .trim()
                                        .isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          LabeledField(
                            label: 'Email',
                            controller: _emailCtrl,
                            enabled: false,
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveNames,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                                  : const Text('Save Changes'),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : _onChangePasswordPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Change Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}