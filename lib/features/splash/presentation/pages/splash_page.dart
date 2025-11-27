import 'dart:async';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/home/presentation/pages/general_home_page.dart';
import 'package:juecho/features/splash/presentation/widgets/logo_with_echo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _navigateAfterSplash();
      }
    });
  }

  Future<void> _navigateAfterSplash() async {
    try {
      final session =
      await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      if (!session.isSignedIn) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          LoginPage.routeName,
              (_) => false,
        );
        return;
      }

      final isAdmin = AuthRepository.isAdminFromSession(session);
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        isAdmin ? AdminHomePage.routeName : GeneralHomePage.routeName,
            (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginPage.routeName,
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: LogoWithEcho(),
      ),
    );
  }
}
