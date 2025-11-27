import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:juecho/common/constants/app_colors.dart';

class JuechoHeader extends StatelessWidget {
  const JuechoHeader({
    super.key,
    required this.onMenuTap,
  });
  
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset('assets/images/JUEcho_BGR.svg', height: 90),
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu, color: AppColors.primary, size: 30),
            ),
          ],
        ),
      ],
    );
  }
}
