import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/juecho_header.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_hamburger_menu.dart';

class GeneralScaffoldWithMenu extends StatefulWidget {
  const GeneralScaffoldWithMenu({
    super.key,
    required this.body,
  });

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
    _menuSlide =
        Tween<Offset>(
          begin: const Offset(0, -1),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(parent: _menuController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() async {
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ------------ MAIN CONTENT ------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with burger menu
                  JuechoHeader(onMenuTap: _toggleMenu),
                  // Page-specific body
                  Expanded(child: widget.body),
                ],
              ),
            ),

            // ------------ TOP HAMBURGER OVERLAY ------------
            AnimatedBuilder(
              animation: _menuController,
              builder: (context, child) {
                if (_menuController.value == 0) {
                  // fully closed → nothing visible/clickable
                  return const SizedBox.shrink();
                }
                return Container(
                  color: AppColors.black.withValues(alpha: 0.12),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SlideTransition(position: _menuSlide, child: child),
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
