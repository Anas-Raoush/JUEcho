import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/home/presentation/pages/general_home_page.dart';
import 'package:juecho/features/splash/presentation/widgets/logo_with_echo.dart';

/// Splash page:
/// - Shows the animated logo
/// - Checks connectivity BEFORE calling auth.bootstrap()
/// - If offline: shows a small offline UI + Retry
/// - If online: proceeds with the existing navigation logic
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  bool _checking = true;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();

    // Keep the splash visible for your original delay,
    // then run connectivity + navigation.
    _timer = Timer(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      await _checkInternetAndNavigate();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// An internet check.
  /// Uses DNS lookup to confirm actual connectivity.
  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkInternetAndNavigate() async {
    setState(() {
      _checking = true;
      _hasInternet = true;
    });

    final ok = await _hasRealInternet();
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _checking = false;
        _hasInternet = false;
      });
      return;
    }

    // Internet OK → proceed to original logic
    await _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.bootstrap();

      if (!mounted) return;

      if (!auth.isSignedIn) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          LoginPage.routeName,
              (_) => false,
        );
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        auth.isAdmin ? AdminHomePage.routeName : GeneralHomePage.routeName,
            (_) => false,
      );
    } catch (_) {
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: _checking
            ? const LogoWithEcho()
            : (!_hasInternet)
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 52),
              const SizedBox(height: 14),
              const Text(
                'No internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gray),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _checkInternetAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        )
            : const LogoWithEcho(),
      ),
    );
  }
}