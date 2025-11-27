import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/features/auth/presentation/widgets/auth_logo_header.dart';


/// Arguments object used when navigating to [ConfirmCodePage].
///
/// This is passed via:
///   Navigator.pushNamed(
///     context,
///     ConfirmCodePage.routeName,
///     arguments: ConfirmCodeArgs(...),
///   );
///
/// It carries:
/// - [email]: the Cognito username (email) to confirm
/// - [password]: the password used at sign-up (needed for profile creation)
/// - [firstName] / [lastName]: optional; provided when coming directly from sign-up
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
/// - Letting the user enter the verification code sent by Cognito
/// - Confirming the sign-up with Cognito
/// - Creating the User profile in DynamoDB (via [AuthRepository])
/// - Redirecting back to [LoginPage] on success
class ConfirmCodePage extends StatefulWidget {
  const ConfirmCodePage({super.key});

  /// Named route for this page, used with [Navigator.pushNamed].
  static const routeName = '/confirm-code';

  @override
  State<ConfirmCodePage> createState() => _ConfirmCodePageState();
}

class _ConfirmCodePageState extends State<ConfirmCodePage> {
  /// Key used for validating the single TextFormField (verification code).
  final _formKey = GlobalKey<FormState>();

  /// Controller for the verification code input.
  final _codeController = TextEditingController();

  /// Arguments passed from the previous screen (Sign up or Login).
  ///
  /// Marked as `late` because it is initialized inside [didChangeDependencies],
  /// when [ModalRoute.of(context)] becomes available.
  late final ConfirmCodeArgs _args;

  /// Flag to ensure that `_args` is only initialized once,
  /// even if [didChangeDependencies] is called multiple times.
  bool _argsInitialized = false;

  /// Whether the "Verify" action is currently in progress.
  ///
  /// Controls the state of the primary button and loading spinner.
  bool _isLoading = false;

  /// Whether the "Resend code" action is currently in progress.
  ///
  /// Controls the label and enabled state of the resend button.
  bool _isResending = false;

  /// Holds any user-facing error message displayed above the form.
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsInitialized) return;

    // Retrieve route arguments passed via Navigator.pushNamed(..., arguments: ...)
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is ConfirmCodeArgs) {
      _args = routeArgs;
    } else {
      // Fallback to empty values if arguments were not provided or of wrong type.
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
    // Dispose controllers to avoid memory leaks.
    _codeController.dispose();
    super.dispose();
  }

  /// Handles the "Verify" button press.
  ///
  /// Flow:
  /// 1. Validate the verification code input.
  /// 2. Call [AuthRepository.confirmSignUp] to confirm the Cognito user.
  /// 3. Call [AuthRepository.createProfileAfterConfirmation] to:
  ///    - ensure a Cognito session
  ///    - create the User record in DynamoDB
  ///    - clean up PendingUser table and sign out
  /// 4. On success -> navigate back to [LoginPage] and show a success SnackBar.
  ///
  /// Various Cognito exceptions are caught individually to provide
  /// user-friendly error messages.
  Future<void> _onVerify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Step 1: Confirm sign-up in Cognito using the provided code.
      await AuthRepository.confirmSignUp(
        email: _args.email,
        code: _codeController.text.trim(),
      );
      // Step 2: Create the user profile in DynamoDB and perform related tasks.
      await AuthRepository.createProfileAfterConfirmation(
        email: _args.email,
        password: _args.password,
        firstName: _args.firstName ?? '',
        lastName: _args.lastName ?? '',
      );

      if (!mounted) return;
      // Step 3: Clear the navigation stack and go back to LoginPage.
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginPage.routeName,
            (route) => false,
      );
      // Step 4: Show success message at the bottom of the screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account verified. Please sign in.')),
      );
    } on CodeMismatchException {
      // User entered a wrong/invalid code.
      setState(() {
        _error = 'Invalid verification code. Please check it and try again.';
      });
    } on ExpiredCodeException {
      // Code expired; user should request a new one.
      setState(() {
        _error =
        'This code has expired. Tap "Resend" to get a new verification code.';
      });
    } on LimitExceededException {
      // Too many attempts in a short time.
      setState(() {
        _error =
        'Too many attempts. Please wait a few minutes and then try again.';
      });
    } on AuthException catch (e) {
      // Generic Cognito authentication error fallback.
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      // Non-Cognito unexpected error.
      setState(() {
        _error = 'Could not verify the code. Please try again.';
      });
    } finally {
      // Ensure we hide the loading state in all cases.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handles the "Resend code" link/button press.
  ///
  /// Flow:
  /// 1. Set `_isResending` to true to show a loading state on the button.
  /// 2. Call [AuthRepository.resendSignUpCode] to ask Cognito to send a fresh code.
  /// 3. Show a SnackBar on success.
  /// 4. Handle specific exceptions like [LimitExceededException] for throttling.
  Future<void> _onResend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      // Ask Cognito to resend a confirmation code to the user's email.
      await AuthRepository.resendSignUpCode(_args.email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent to your email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on LimitExceededException {
      // Cognito throttling: too many resend requests.
      setState(() {
        _error =
        'You have requested too many codes. Please wait a few minutes and try again.';
      });
    } on AuthException catch (e) {
      // Other known Cognito errors (e.g., user not found).
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      // Generic unexpected failure.
      setState(() {
        _error = 'Could not resend the code. Please try again.';
      });
    } finally {
      // Ensure the "Resend" button returns to normal state.
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic subtitle that shows the email address being verified.
    final subtitle = 'Enter the verification code sent to\n${_args.email}';

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
                  title: 'Confirm your email',
                  subtitle: subtitle,
                  spacingBelowLogo: 16,
                  spacingBelowTitle: 24,
                ),

                // Displays any error message coming from _onVerify or _onResend.
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
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.7,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Please enter the code';
                          if (v.length < 4) {
                            return 'The code you entered is not valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onVerify,
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
                              : const Text('Verify'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: _isResending ? null : _onResend,
                        child: Text(
                          _isResending
                              ? 'Resending...'
                              : "Didn't get a code? Resend",
                          style: TextStyle(
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
          ),
        ),
      ),
    );
  }
}