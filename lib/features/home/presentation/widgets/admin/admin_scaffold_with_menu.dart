import 'package:flutter/material.dart';

import 'package:juecho/common/widgets/juecho_header.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_hamburger_menu.dart';

/// A reusable scaffold wrapper for all ADMIN pages.
///
/// What it provides:
/// - Standard page padding
/// - The app header (JuechoHeader)
/// - A slide-down hamburger overlay menu (AdminHamburgerMenu)
///
/// Why it exists:
/// - Keeps every admin page consistent
/// - Prevents copying the same header/menu animation code everywhere
class AdminScaffoldWithMenu extends StatefulWidget {
  const AdminScaffoldWithMenu({
    super.key,
    required this.body,
  });

  /// The page content below the header.
  final Widget body;

  @override
  State<AdminScaffoldWithMenu> createState() => _AdminScaffoldWithMenuState();
}

class _AdminScaffoldWithMenuState extends State<AdminScaffoldWithMenu>
    with SingleTickerProviderStateMixin {
  /// Controls opening/closing the top overlay menu animation.
  late final AnimationController _menuController;

  /// Moves the menu from off-screen (top) into view.
  late final Animation<Offset> _menuSlide;

  @override
  void initState() {
    super.initState();

    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _menuSlide = Tween<Offset>(
      begin: const Offset(0, -1), // off-screen
      end: const Offset(0, 0),    // in-place
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

  /// Toggles the menu open/close.
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
            // ---------- MAIN CONTENT ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Header includes the burger icon
                  JuechoHeader(onMenuTap: _toggleMenu),

                  /// Page-specific body
                  Expanded(child: widget.body),
                ],
              ),
            ),

            // ---------- SLIDE-DOWN MENU OVERLAY ----------
            AnimatedBuilder(
              animation: _menuController,
              builder: (context, child) {
                // Fully closed -> don't render overlay at all.
                if (_menuController.value == 0) return const SizedBox.shrink();

                return IgnorePointer(
                  ignoring: _menuController.value == 0,
                  child: Container(
                    // Dimmed background
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