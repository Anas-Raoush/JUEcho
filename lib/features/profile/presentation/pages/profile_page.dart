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

  double _maxWidthFor(double w) {
    if (w >= 1200) return 900;
    if (w >= 900) return 820;
    if (w >= 700) return 650;
    return double.infinity;
  }

  EdgeInsets _paddingFor(double w) {
    final horizontal = w < 380 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 8);
  }

  Future<void> _saveNames() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    try {
      // 1) DB update (source of truth)
      await ProfileRepository.updateNames(
        firstName: firstName,
        lastName: lastName,
      );

      // 2) Update Provider (instant UI update across app)
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not save profile. Please try again later.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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

    final isLoading = profile == null;

    return GeneralScaffoldWithMenu(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final maxWidth = _maxWidthFor(w);

          // breakpoint: when very small, stack first/last name
          final isSmall = w < 520;

          // buttons full width on small screens
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

                    // show provider error first, then local
                    ErrorMessage(error: auth.error ?? _error),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (isSmall) ...[
                            // small screen: stack fields vertically
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
                            // normal: two columns
                            Row(
                              children: [
                                Expanded(
                                  child: LabeledField(
                                    label: 'First Name',
                                    controller: _firstNameCtrl,
                                    validator: (v) =>
                                    (v ?? '').trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: LabeledField(
                                    label: 'Last Name',
                                    controller: _lastNameCtrl,
                                    validator: (v) =>
                                    (v ?? '').trim().isEmpty
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
                                    vertical: 12),
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
                                    vertical: 12),
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