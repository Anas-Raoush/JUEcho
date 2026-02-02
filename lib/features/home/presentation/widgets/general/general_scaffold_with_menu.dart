import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/juecho_header.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_hamburger_menu.dart';

/// GeneralScaffoldWithMenu
///
/// Base scaffold wrapper for GENERAL user pages.
///
/// Provides:
/// - SafeArea + consistent padding
/// - Shared app header (JuechoHeader)
/// - Slide-down overlay menu (GeneralHamburgerMenu)
///
/// Design:
/// - The menu is rendered in a Stack above the content.
/// - The overlay includes a dimmed background and a SlideTransition.
/// - Menu visibility and animation are driven by a single AnimationController.
class GeneralScaffoldWithMenu extends StatefulWidget {
  const GeneralScaffoldWithMenu({
    super.key,
    required this.body,
  });

  /// Page-specific content rendered below the shared header.
  final Widget body;

  @override
  State<GeneralScaffoldWithMenu> createState() =>
      _GeneralScaffoldWithMenuState();
}

class _GeneralScaffoldWithMenuState extends State<GeneralScaffoldWithMenu>
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

  /// Toggles menu open/close based on current animation status.
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
      backgroundColor: AppColors.white,
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

                return Container(
                  color: AppColors.black.withValues(alpha: 0.12),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SlideTransition(
                      position: _menuSlide,
                      child: child,
                    ),
                  ),
                );
              },
              child: GeneralHamburgerMenu(closeMenu: _toggleMenu),
            ),
          ],
        ),
      ),
    );
  }
}