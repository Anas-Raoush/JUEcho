import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/juecho_header.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_hamburger_menu.dart';

/// A reusable scaffold for GENERAL user pages that includes:
/// - App header with a hamburger menu button
/// - Slide-down hamburger menu overlay
/// - Page-specific body content
///
/// Why this widget exists:
/// - Centralizes the layout logic used across all general-user pages.
/// - Ensures consistent padding, background color, and header behavior.
/// - Encapsulates the hamburger menu animation and overlay handling
///   so individual pages stay clean and focused on content.
///
/// Typical usage:
/// ```dart
/// return GeneralScaffoldWithMenu(
///   body: MyPageContent(),
/// );
/// ```
class GeneralScaffoldWithMenu extends StatefulWidget {
  const GeneralScaffoldWithMenu({
    super.key,
    required this.body,
  });

  /// The page-specific content shown below the header.
  final Widget body;

  @override
  State<GeneralScaffoldWithMenu> createState() =>
      _GeneralScaffoldWithMenuState();
}

class _GeneralScaffoldWithMenuState extends State<GeneralScaffoldWithMenu>
    with SingleTickerProviderStateMixin {
  // ---------------- Animation fields ----------------

  /// Controls the open/close animation of the hamburger menu.
  ///
  /// Using a single controller allows us to:
  /// - play the animation forward (open)
  /// - reverse it (close)
  late final AnimationController _menuController;

  /// Slide animation for the menu.
  ///
  /// - Begins above the screen (Offset(0, -1))
  /// - Slides down into view (Offset(0, 0))
  late final Animation<Offset> _menuSlide;

  @override
  void initState() {
    super.initState();

    // Initialize the controller for the menu animation.
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // Define a slide-down animation with a smooth easing curve.
    _menuSlide =
        Tween<Offset>(
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
    // Always dispose animation controllers to avoid memory leaks.
    _menuController.dispose();
    super.dispose();
  }

  /// Toggles the hamburger menu open/closed.
  ///
  /// Logic:
  /// - If the menu is open or opening -> close it.
  /// - Otherwise -> open it.
  void _toggleMenu() {
    if (_menuController.status == AnimationStatus.completed ||
        _menuController.status == AnimationStatus.forward) {
      _menuController.reverse();
    } else {
      _menuController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Consistent app background.
      backgroundColor: AppColors.white,

      body: SafeArea(
        child: Stack(
          children: [
            // =========================================================
            // MAIN PAGE CONTENT (header + body)
            // =========================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App header with burger icon.
                  // The header does NOT manage state itself;
                  // it simply calls back when the menu button is tapped.
                  JuechoHeader(onMenuTap: _toggleMenu),

                  // Page-specific content fills the remaining space.
                  Expanded(child: widget.body),
                ],
              ),
            ),

            // =========================================================
            // HAMBURGER MENU OVERLAY (slides from the top)
            // =========================================================
            AnimatedBuilder(
              animation: _menuController,
              builder: (context, child) {
                // When the menu is fully closed,
                // return nothing so it doesn't intercept touches.
                if (_menuController.value == 0) {
                  return const SizedBox.shrink();
                }

                return Container(
                  // Semi-transparent backdrop to dim the page behind.
                  color: AppColors.black.withValues(alpha: 0.12),

                  child: Align(
                    alignment: Alignment.topCenter,

                    // SlideTransition animates the menu in/out vertically.
                    child: SlideTransition(
                      position: _menuSlide,
                      child: child,
                    ),
                  ),
                );
              },

              // The actual menu widget.
              //
              // It receives a callback so it can close itself
              // when an item is tapped.
              child: GeneralHamburgerMenu(closeMenu: _toggleMenu),
            ),
          ],
        ),
      ),
    );
  }
}