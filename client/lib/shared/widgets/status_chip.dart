import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/member_model.dart';

class PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;
  const PaymentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case PaymentStatus.paid:
        color = AppColors.primaryContainer;
        label = 'PAID';
        icon = Icons.check_circle;
        break;
      case PaymentStatus.overdue:
        color = AppColors.secondary;
        label = 'OVERDUE';
        icon = Icons.warning;
        break;
      case PaymentStatus.pending:
        color = AppColors.onSurfaceVariant;
        label = 'PENDING';
        icon = Icons.schedule;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class MemberTierChip extends StatelessWidget {
  final String tier;
  final String tierLabel;
  const MemberTierChip({
    super.key,
    required this.tier,
    required this.tierLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color textColor;

    switch (tier) {
      case 'elitePro':
        borderColor = AppColors.primaryContainer.withOpacity(0.3);
        textColor = AppColors.primaryContainer;
        break;
      case 'vip':
        borderColor = AppColors.tertiary.withOpacity(0.3);
        textColor = AppColors.tertiary;
        break;
      case 'master':
        borderColor = AppColors.tertiary.withOpacity(0.3);
        textColor = AppColors.tertiary;
        break;
      default:
        borderColor = AppColors.outlineVariant.withOpacity(0.3);
        textColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.08),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        tierLabel,
        style: GoogleFonts.roboto(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
