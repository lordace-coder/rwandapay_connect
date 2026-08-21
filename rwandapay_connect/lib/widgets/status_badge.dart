import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'sent':
        bgColor = const Color(0xFFDBEAFF);
        textColor = AppColors.info;
        label = 'Sent';
        icon = Icons.arrow_upward_rounded;
        break;
      case 'received':
        bgColor = const Color(0xFFD1FAE5);
        textColor = AppColors.success;
        label = 'Received';
        icon = Icons.arrow_downward_rounded;
        break;
      case 'sent_to_momo':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB8860B);
        label = 'Sent to MoMo';
        icon = Icons.phone_android_rounded;
        break;
      case 'verified':
        bgColor = const Color(0xFFD1FAE5);
        textColor = AppColors.success;
        label = 'Verified';
        icon = Icons.verified_rounded;
        break;
      default:
        bgColor = AppColors.surface;
        textColor = AppColors.mutedGrey;
        label = status;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
