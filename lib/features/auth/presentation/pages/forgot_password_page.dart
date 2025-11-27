import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/helper/validators.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/features/auth/presentation/widgets/auth_logo_header.dart';


/// Screen allowing users to reset their password using AWS Cognito.
///
/// Flow handled by this page:
/// -----------------------------------------------------------
/// 1) User enters their email and taps **"Send code"**
///    -> Calls `AuthRepository.startForgotPassword()`
///    -> Cognito emails a 6-digit reset code
///
/// 2) UI switches to the second step (controlled by `_codeSent`)
///    -> User enters the 6-digit code + new password
///
/// 3) User taps **"Update password"**
///    -> Calls `AuthRepository.confirmForgotPassword()`
///    -> On success: pops back to login page
///
/// All Cognito exceptions are mapped to user-friendly messages.
/// -----------------------------------------------------------
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  /// Named route used when pushing this page.
  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  /// Controllers for form fields.
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  /// A single form key handling both steps of the flow.
  final _formKey = GlobalKey<FormState>();

  /// Tracks whether the reset code has been sent.
  ///
  /// - FALSE -> Show “email only” UI
  /// - TRUE -> Show “code + new password” UI
  bool _codeSent = false;

  /// Indicates network activity; used to disable buttons and show spinners.
  bool _isLoading = false;

  /// Holds a user-facing error message displayed in the UI.
  String? _error;

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks.
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  /// Step 1: Request Cognito to send a password reset code to the email.
  ///
  /// Validates only the email, NOT the entire form.
  /// The UI switches to the next step if the operation succeeds.
  Future<void> _sendCode() async {
    // Perform JU email validation using custom validator.
    final emailError = validateJUEmail(_emailCtrl.text.trim());
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      // Triggers Cognito to send a reset code email.
      await AuthRepository.startForgotPassword(_emailCtrl.text.trim());

      if (!mounted) return;

      // Successfully sent -> Show the second stage inputs.
      setState(() => _codeSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If this email is registered, a code has been sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (_) {
      // Cognito-level failure (network issue, throttling, etc.)
      setState(() {
        _error = 'Could not send reset code. Please try again in a moment.';
      });
    } catch (_) {
      // Unexpected non-Cognito error.
      setState(() {
        _error = 'Could not send reset code. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Step 2: Confirms the new password using the verification code.
  ///
  /// - Validates the entire form (email + code + new password)
  /// - Calls Cognito's `confirmResetPassword`
  /// - Returns user to LoginPage on success
  Future<void> _confirmReset() async {
    // Validate entire form (uses validators defined in TextFormFields).
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _error = null;
      _isLoading = true;
    });

    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;

    try {
      // Attempt to reset password in Cognito backend.
      await AuthRepository.confirmForgotPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (!mounted) return;

      // Success -> Return to previous screen (Login)
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully. Please sign in.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (e) {
      // Handle specific Cognito errors for better UX.
      if (e is CodeMismatchException) {
        setState(() {
          _error = 'The verification code is incorrect or has expired.\n'
              'Please check the latest email or tap "Send code" again.';
        });
      } else if (e is LimitExceededException) {
        setState(() {
          _error =
          'Too many attempts. Please wait a little while and try again.';
        });
      } else {
        // Weak password
        setState(() {
          _error =
          'Password must be at least 8 characters and include an uppercase letter, '
              'a lowercase letter, a number, and a special character.';
        });
      }
    } catch (_) {
      // Unexpected error.
      setState(() {
        _error = 'Could not update password. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Utility: Checks if the password meets password policy requirements.
  ///
  /// Must contain:
  /// - uppercase letter
  /// - lowercase letter
  /// - number
  /// - special character
  /// - minimum length 8
  bool _isStrongPassword(String value) {
    final regex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)'
      r'(?=.*[!@#\$%^&*()_\-+=\[{\]};:"\\|,.<>/?]).{8,}$',
    );
    return regex.hasMatch(value);
  }

  /// Utility: Ensures the verification code is exactly 6 digits.
  bool _isNumericCode(String value) {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    /// Dynamic subtitle depending on which step the user is in.
    final subtitle = _codeSent
        ? 'Enter the code sent to your email and your new password.'
        : 'Enter your email and we\'ll send you a reset code.';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Reusable header widget to show logo + title.
                AuthLogoHeader(
                  title: 'Reset your password',
                  subtitle: subtitle,
                  spacingBelowLogo: 16,
                  spacingBelowTitle: 24,
                ),

                /// Shows any error message produced by _sendCode or _confirmReset
                ErrorMessage(error: _error),

                /// Holds email, code (conditionally), and new password fields
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// Email field (disabled on step 2)
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !_codeSent,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('Enter your Email'),
                        validator: validateJUEmail,
                      ),
                      const SizedBox(height: 16),

                      /// Step 2 UI (verification code + new password fields)
                      if (_codeSent) ...[
                        TextFormField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            'Verification code from email',
                          ),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) {
                              return 'Please enter the code';
                            }
                            if (!_isNumericCode(v)) {
                              return 'This code is not valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordCtrl,
                          obscureText: true,
                          decoration: _inputDecoration(
                            'Enter your new password',
                          ),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (!_isStrongPassword(v)) {
                              return 'Password must be at least 8 characters and include '
                                  'an uppercase letter, a lowercase letter, a number, and a special character.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      /// Main button:
                      /// - Step 1 -> "Send code"
                      /// - Step 2 -> "Update password"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _codeSent
                              ? _confirmReset
                              : _sendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.primary,
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
                              : Text(_codeSent ? 'Update password' : 'Send code'),
                        ),
                      ),

                      /// Optional "Resend" button shown only after step 1
                      if (_codeSent) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Didn't get a code?"),
                            TextButton(
                              onPressed: _isLoading ? null : _sendCode,
                              child: Text(
                                "Resend",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Common decoration builder for all text fields on this page.
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      label: Text(label),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      errorMaxLines: 3,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 1.7,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
