import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'dart:convert';
import 'package:juecho/core/config/amplify_outputs.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/feedback/presentation/pages/my_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/pages/single_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/pages/submit_feedback_page.dart';
import 'package:juecho/features/profile/presentation/pages/profile_page.dart';
import 'package:juecho/features/splash/presentation/pages/splash_page.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/auth/presentation/pages/signup_page.dart';
import 'package:juecho/features/auth/presentation/pages/confirm_code_page.dart';
import 'package:juecho/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:juecho/features/Home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/Home/presentation/pages/general_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Amplify.addPlugins([
    AmplifyAuthCognito(),
    AmplifyAPI(),
    AmplifyStorageS3(),
  ]);

  try {
    await Amplify.configure(jsonEncode(amplifyOutputs) );
  } on AmplifyAlreadyConfiguredException {
    safePrint('Amplify already configured');
  }

  runApp(const JUEchoApp());
}

class JUEchoApp extends StatelessWidget {
  const JUEchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JUEcho',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.gray,
        ),
      ),
      initialRoute: SplashPage.routeName,
      routes: {
        SplashPage.routeName: (context) => const SplashPage(),
        LoginPage.routeName: (context) => const LoginPage(),
        SignupPage.routeName: (context) => const SignupPage(),
        ConfirmCodePage.routeName: (context) => const ConfirmCodePage(),
        ForgotPasswordPage.routeName: (context) => const ForgotPasswordPage(),
        AdminHomePage.routeName: (context) => const AdminHomePage(),
        GeneralHomePage.routeName: (context) => const GeneralHomePage(),
        SubmitFeedbackPage.routeName: (context) => const SubmitFeedbackPage(),
        ProfilePage.routeName: (context) => const ProfilePage(),
        MyFeedbackPage.routeName: (context) => const MyFeedbackPage(),
        SingleFeedbackPage.routeName: (context) => const SingleFeedbackPage(),
      },
    );
  }
}