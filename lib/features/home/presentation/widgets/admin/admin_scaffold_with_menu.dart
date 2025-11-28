import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import 'package:juecho/common/widgets/juecho_header.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_hamburger_menu.dart';

class AdminScaffoldWithMenu extends StatefulWidget {
  const AdminScaffoldWithMenu({
    super.key,
    required this.body,
  });

  final Widget body;

  @override
  State<AdminScaffoldWithMenu> createState() => _AdminScaffoldWithMenuState();
}

class _AdminScaffoldWithMenuState extends State<AdminScaffoldWithMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  late final Animation<Offset> _menuSlide;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _menuController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_menuController.status == AnimationStatus.completed ||
        _menuController.status == AnimationStatus.forward) {
      _menuController.reverse();
    } else {
      _menuController.forward();
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await AuthRepository.signOut();
    } catch (e) {
      safePrint('Sign-out failed: $e');
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ---------- MAIN CONTENT ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // This is your existing header widget
                  JuechoHeader(onMenuTap: _toggleMenu),
                  const SizedBox(height: 8),
                  Expanded(child: widget.body),
                ],
              ),
            ),

            // ---------- SLIDE-DOWN MENU OVERLAY ----------
            AnimatedBuilder(
              animation: _menuController,
              builder: (context, child) {
                if (_menuController.value == 0) {
                  return const SizedBox.shrink();
                }
                return IgnorePointer(
                  ignoring: _menuController.value == 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.12),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SlideTransition(
                        position: _menuSlide,
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: AdminHamburgerMenu(
                  closeMenu: _toggleMenu,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}