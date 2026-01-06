import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/features/auth/presentation/widgets/responsive_scaffold.dart';

import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/auth/presentation/widgets/auth_logo_header.dart';

/// Arguments object used when navigating to ConfirmCodePage.
class ConfirmCodeArgs {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;

  const ConfirmCodeArgs({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
  });
}

/// Screen responsible for:
/// - Entering the verification code sent by Cognito
/// - Confirming sign-up
/// - Creating the user profile in DB (Users table) via AuthProvider
/// - Redirecting to LoginPage on success
///
/// Note:
/// - Only layout changed to responsive.
/// - Verification logic is untouched.
class ConfirmCodePage extends StatefulWidget {
  const ConfirmCodePage({super.key});

  static const routeName = '/confirm-code';

  @override
  State<ConfirmCodePage> createState() => _ConfirmCodePageState();
}

class _ConfirmCodePageState extends State<ConfirmCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  late final ConfirmCodeArgs _args;
  bool _argsInitialized = false;

  bool _isLoading = false;
  bool _isResending = false;

  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsInitialized) return;

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is ConfirmCodeArgs) {
      _args = routeArgs;
    } else {
      _args = const ConfirmCodeArgs(
        email: '',
        password: '',
        firstName: '',
        lastName: '',
      );
    }

    _argsInitialized = true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Verify the confirmation code and create the user profile record.
  Future<void> _onVerify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().confirmAndCreateProfile(
        email: _args.email,
        code: _codeController.text.trim(),
        password: _args.password,
        firstName: _args.firstName ?? '',
        lastName: _args.lastName ?? '',
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginPage.routeName,
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account verified. Please sign in.')),
      );
    } on CodeMismatchException {
      setState(() {
        _error = 'Invalid verification code. Please check it and try again.';
      });
    } on ExpiredCodeException {
      setState(() {
        _error = 'This code has expired. Tap "Resend" to get a new code.';
      });
    } on LimitExceededException {
      setState(() {
        _error = 'Too many attempts. Please wait a few minutes and try again.';
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not verify the code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Ask Cognito to resend the confirmation code.
  Future<void> _onResend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().resendSignUpCode(_args.email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent to your email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on LimitExceededException {
      setState(() {
        _error =
        'You requested too many codes. Please wait a few minutes and try again.';
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not resend the code. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = 'Enter the verification code sent to\n${_args.email}';

    return ResponsiveScaffold(
      maxWidth: 520,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthLogoHeader(
            title: 'Confirm your email',
            subtitle: subtitle,
            spacingBelowLogo: 16,
            spacingBelowTitle: 24,
          ),

          ErrorMessage(error: _error),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Verification code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.7,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Please enter the code';
                    if (v.length < 4) return 'The code you entered is not valid';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                        : const Text('Verify'),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _isResending ? null : _onResend,
                  child: Text(
                    _isResending ? 'Resending...' : "Didn't get a code? Resend",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}