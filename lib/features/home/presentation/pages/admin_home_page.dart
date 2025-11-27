// lib/features/home/presentation/pages/admin_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static const routeName = '/admin-home';


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 24),
              const _WelcomeSection(),
              const SizedBox(height: 16),
              const _AdminStatsGrid(),
              const SizedBox(height: 32),
              _PrimaryButton(
                label: 'New Submissions',
                onPressed: () {
                  // TODO navigate to new-submissions list
                },
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                label: 'Analytics and Reports',
                backgroundColor: const Color(0xFF4F5756),
                onPressed: () {
                  // TODO: analytics page
                },
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                label: 'Feedback Review',
                backgroundColor: const Color(0xFFF5F5F5),
                textColor: Colors.black87,
                onPressed: () {
                  // TODO: feedback review page
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {


    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/images/JUEcho_BGR.svg',
              height: 90,
            ),
            const SizedBox(width: 8),
          ],
        ),
        IconButton(
          onPressed: () {
            // TODO: open admin menu / drawer
          },
          icon: Icon(Icons.menu, color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AuthRepository.fetchCurrentUserFullName(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Admin';
        return Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Welcome $name',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminStatsGrid extends StatelessWidget {
  const _AdminStatsGrid();

  @override
  Widget build(BuildContext context) {
    // TODO: wire real numbers later
    const submissionsReceived = '100';
    const topService = 'Library';
    const bottomService = 'Food';
    const resolvedIssues = '5';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _AdminStatCard(
          title: 'Submissions received',
          value: submissionsReceived,
        ),
        _AdminStatCard(
          title: 'Top rated service',
          value: topService,
        ),
        _AdminStatCard(
          title: 'bottom rated service',
          value: bottomService,
        ),
        _AdminStatCard(
          title: 'numbers of resolved issues',
          value: resolvedIssues,
        ),
      ],
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 8) / 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 2),
              color: Colors.black12,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF006A3A),
    this.textColor = Colors.white,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: backgroundColor == const Color(0xFFF5F5F5) ? 2 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
