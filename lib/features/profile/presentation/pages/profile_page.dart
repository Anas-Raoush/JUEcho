import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
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

  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    safePrint("ProfilePage initState");
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _error = null;
    });

    try {
      final profile = await AuthRepository.fetchCurrentProfileData();

      _firstNameCtrl.text = profile.firstName;
      _lastNameCtrl.text = profile.lastName;
      _emailCtrl.text = profile.email;
    } catch (e) {
      setState(() {
        _error = 'Could not load profile. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _saveNames() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSavingProfile = true;
      _error = null;
    });

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    try {
      await ProfileRepository.updateNames(
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
      );


      AuthRepository.updateCachedName(
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
      setState(() {
        _error = 'Could not save profile. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _onChangePasswordPressed() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GeneralScaffoldWithMenu(
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTitle(title: 'Personal Information'),
            ErrorMessage(error: _error),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'First Name',
                          controller: _firstNameCtrl,
                          validator: (v) {
                            if ((v ?? '')
                                .trim()
                                .isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'Last Name',
                          controller: _lastNameCtrl,
                          validator: (v) {
                            if ((v ?? '')
                                .trim()
                                .isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  LabeledField(
                    label: 'Email',
                    controller: _emailCtrl,
                    enabled: false,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isSavingProfile ? null : _saveNames,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isSavingProfile
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

                  const SizedBox(height: 24),

                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isSavingProfile
                          ? null
                          : _onChangePasswordPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}