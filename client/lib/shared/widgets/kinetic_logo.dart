import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class KineticLogo extends StatelessWidget {
  final double fontSize;
  const KineticLogo({super.key, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Text(
      'KINETIC',
      style: GoogleFonts.lexend(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryContainer,
        fontStyle: FontStyle.italic,
        letterSpacing: -1,
      ),
    );
  }
}
