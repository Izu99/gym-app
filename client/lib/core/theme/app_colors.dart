import 'package:flutter/material.dart';

class AppColors {
  // --- New Premium Palette ---
  
  // Primary - Refined Electric Lime (The Brand Identity)
  static const primary = Color(0xFFD9FF43); 
  static const onPrimary = Color(0xFF000000); 
  
  // Surface Hierarchy
  static const background = Color(0xFF080808); 
  static const surface = Color(0xFF121212); 
  static const surfaceLight = Color(0xFF1E1E1E); 
  static const surfaceLighter = Color(0xFF282828); 
  
  // Accents & Feedback
  static const accent = Color(0xFFFF521B); 
  static const success = Color(0xFF00E676);
  static const error = Color(0xFFFF3D00);
  static const warning = Color(0xFFFFC107);
  static const secondary = Color(0xFFFF7441); // Restored for existing UI
  
  // Text Hierarchy
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textMuted = Color(0xFF666666);
  
  // Borders & Dividers
  static const border = Color(0xFF2A2A2A);
  static const borderLight = Color(0xFF333333);

  // --- Deprecated Aliases (Mapping old names to new palette for stability) ---
  
  static const primaryContainer = primary;
  static const onPrimaryContainer = onPrimary;
  static const secondaryContainer = surfaceLight;
  static const onSecondaryContainer = textPrimary;
  static const tertiary = accent;
  static const tertiaryContainer = Color(0x33FF521B);
  
  static const onSurface = textPrimary;
  static const onSurfaceVariant = textSecondary;
  static const surfaceContainer = surface;
  static const surfaceContainerLow = surface;
  static const surfaceContainerHighest = surfaceLight;
  static const surfaceLighterHighest = surfaceLighter;
  
  static const outline = border;
  static const outlineVariant = borderLight;
  
  static const errorContainer = Color(0x33FF3D00);
  static const onErrorContainer = Color(0xFFFFD2C8);
  static const onSecondary = Color(0xFF000000);

  // Gradients for "Premium" feel
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFD9FF43), Color(0xFFA6FF00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
