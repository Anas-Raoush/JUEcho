import 'package:flutter/material.dart';

import 'package:juecho/common/widgets/juecho_header.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_hamburger_menu.dart';

/// AdminScaffoldWithMenu
///
/// Base scaffold wrapper for ADMIN pages.
///
/// Provides:
/// - SafeArea + consistent padding
/// - Shared app header (JuechoHeader)
/// - Slide-down overlay menu (AdminHamburgerMenu)
///
/// Design:
/// - The menu is rendered in a Stack above the content.
/// - The overlay includes a dimmed background and a SlideTransition.
/// - Menu visibility and animation are driven by a single AnimationController.
class AdminScaffoldWithMenu extends StatefulWidget {
  const AdminScaffoldWithMenu({
    super.key,
    required this.body,
  });

  /// Page-specific content rendered below the shared header.
  final Widget body;

  @override
  State<AdminScaffoldWithMenu> createState() => _AdminScaffoldWithMenuState();
}

class _AdminScaffoldWithMenuState extends State<AdminScaffoldWithMenu>
    with SingleTickerProviderStateMixin {
  /// Drives the open/close animation for the overlay menu.
  late final AnimationController _menuController;

  /// Slide animation that moves the menu from above the screen into view.
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

  /// Toggles the overlay menu.
  ///
  /// Open states:
  /// - AnimationStatus.forward
  /// - AnimationStatus.completed
  ///
  /// Close state:
  /// - AnimationStatus.dismissed
  void _toggleMenu() {
    final isOpen = _menuController.status == AnimationStatus.completed ||
        _menuController.status == AnimationStatus.forward;

    if (isOpen) {
      _menuController.reverse();
    } else {
      _menuController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JuechoHeader(onMenuTap: _toggleMenu),
                  Expanded(child: widget.body),
                ],
              ),
            ),

            AnimatedBuilder(
              animation: _menuController,
              builder: (context, child) {
                if (_menuController.value == 0) return const SizedBox.shrink();

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
                child: AdminHamburgerMenu(closeMenu: _toggleMenu),
              ),
            ),
          ],
        ),
      ),
    );
  }
}