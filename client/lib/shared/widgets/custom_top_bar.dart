import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '../../core/theme/app_colors.dart';

class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onClose;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final bool showWindowControls;

  const CustomTopBar({
    super.key,
    required this.title,
    this.onClose,
    this.actions,
    this.leading,
    this.height = 72,
    this.showWindowControls = true,
  });

  bool get _isDesktop =>
      !Platform.isAndroid &&
      !Platform.isIOS; // Simple check for window controls

  @override
  Widget build(BuildContext context) {
    final parts = title.split(' ');
    final isLogin = title == 'SYSTEM LOGIN';

    return GestureDetector(
      onPanStart: (details) {
        if (_isDesktop) windowManager.startDragging();
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(
              color: AppColors.outlineVariant.withAlpha(
                51,
              ), // 20% opacity (0.2 * 255 = 51)
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            if (leading != null && !isLogin) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            if (!isLogin)
              // Split title into first word (white) and rest (gray/italic)
              Builder(
                builder: (context) {
                  if (parts.length > 1) {
                    final firstPart = parts[0];
                    final restParts = parts.sublist(1).join(' ');
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: firstPart.toUpperCase(),
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: restParts.toUpperCase(),
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.onSurfaceVariant.withOpacity(
                                0.6,
                              ),
                              fontStyle: FontStyle.italic,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Text(
                    title.toUpperCase(),
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  );
                },
              ),
            const Spacer(),
            if (actions != null && !isLogin) ...[
              ...actions!,
              const SizedBox(width: 8),
            ],
            if (onClose != null && !isLogin)
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.onSurfaceVariant,
                splashRadius: 24,
              ),
            if (_isDesktop && showWindowControls) ...[
              if (!isLogin) ...[
                const SizedBox(width: 8),
                const VerticalDivider(
                  width: 1,
                  indent: 20,
                  endIndent: 20,
                  color: AppColors.outlineVariant,
                ),
                const SizedBox(width: 8),
              ],
              _WindowControls(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _WindowControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => windowManager.minimize(),
          icon: const Icon(Icons.remove, size: 18),
          color: AppColors.onSurfaceVariant,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          icon: const Icon(Icons.crop_square, size: 16),
          color: AppColors.onSurfaceVariant,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => windowManager.close(),
          icon: const Icon(Icons.close, size: 18),
          color: AppColors.error,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
