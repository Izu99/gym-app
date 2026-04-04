import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/member_model.dart';

class AvatarPlaceholder extends StatelessWidget {
  final String initials;
  final double size;
  final PaymentStatus? paymentStatus;

  const AvatarPlaceholder({
    super.key,
    required this.initials,
    this.size = 48,
    this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = paymentStatus == PaymentStatus.overdue;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withOpacity(0.15)
            : AppColors.surfaceContainerHighest,
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.3)
              : AppColors.outlineVariant.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.lexend(
          fontSize: size * 0.28,
          fontWeight: FontWeight.w900,
          color: isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
