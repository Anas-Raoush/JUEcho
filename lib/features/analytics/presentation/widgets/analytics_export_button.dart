import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/analytics/data/analytics_repository.dart';

/// Export button used on analytics screens.
///
/// Behavior
/// - On press, calls [AnalyticsRepository.exportServiceReportCsv].
/// - Shows an in-progress spinner while exporting.
/// - Displays a SnackBar with the exported path (or a failure message).
class AnalyticsExportButton extends StatefulWidget {
  const AnalyticsExportButton({super.key});

  @override
  State<AnalyticsExportButton> createState() => _AnalyticsExportButtonState();
}

class _AnalyticsExportButtonState extends State<AnalyticsExportButton> {
  bool _isExporting = false;

  /// Exports the aggregated service report to a CSV file.
  Future<void> _export() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final path = await AnalyticsRepository.exportServiceReportCsv();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analytics exported to:\n$path'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export analytics. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: _isExporting ? null : _export,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isExporting
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Excel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.insert_drive_file_outlined),
          ],
        ),
      ),
    );
  }
}