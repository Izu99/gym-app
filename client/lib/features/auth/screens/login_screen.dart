import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/kinetic_logo.dart';
import '../../../shared/widgets/custom_top_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutExpo));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.login(email, password);
      if (mounted) context.go(AppConstants.routeDashboard);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: isDesktop ? const CustomTopBar(title: 'SYSTEM LOGIN') : null,
      body: Stack(
        children: [
          Positioned(
            bottom: -96, right: -96,
            child: Container(
              width: 256, height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: AppColors.primaryContainer.withOpacity(0.08),
                  blurRadius: 100, spreadRadius: 40,
                )],
              ),
            ),
          ),
          Positioned(
            top: -96, left: -96,
            child: Container(
              width: 256, height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: AppColors.secondary.withOpacity(0.04),
                  blurRadius: 80, spreadRadius: 30,
                )],
              ),
            ),
          ),
          if (isDesktop)
            Row(children: [
              Expanded(flex: 7, child: _BrandingPanel()),
              Expanded(flex: 5, child: _buildFormPanel(context)),
            ])
          else
            _buildFormPanel(context),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          color: AppColors.surface,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint) ...[
                      const KineticLogo(fontSize: 36),
                      const SizedBox(height: 40),
                    ],
                    Text('SYSTEM LOGIN',
                      style: GoogleFonts.lexend(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        color: AppColors.onSurface, letterSpacing: -0.5,
                      )),
                    const SizedBox(height: 8),
                    Text('Enter your credentials to access the command center.',
                      style: GoogleFonts.manrope(
                        fontSize: 14, color: AppColors.onSurfaceVariant,
                      )),
                    const SizedBox(height: 40),

                    _FieldLabel('OWNER ID / EMAIL'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.manrope(color: AppColors.onSurface, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'owner@ironpulse.gym',
                        prefixIcon: Icon(Icons.person_outline,
                            color: AppColors.onSurfaceVariant, size: 20),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _FieldLabel('ACCESS KEY'),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, minimumSize: Size.zero,
                          ),
                          child: Text('FORGOT KEY?',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: AppColors.primary, letterSpacing: 2,
                            )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.manrope(color: AppColors.onSurface, fontSize: 14),
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: '••••••••••••',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.onSurfaceVariant, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.outlineVariant, size: 20,
                          ),
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        color: AppColors.errorContainer,
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.onErrorContainer, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                style: GoogleFonts.manrope(
                                  fontSize: 12, color: AppColors.onErrorContainer,
                                )),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(
                          width: 18, height: 18,
                          child: Checkbox(
                            value: _remember,
                            onChanged: (v) => setState(() => _remember = v!),
                            activeColor: AppColors.primaryContainer,
                            checkColor: AppColors.onPrimaryContainer,
                            side: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('REMEMBER THIS TERMINAL',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant, letterSpacing: 2,
                          )),
                      ],
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          disabledBackgroundColor: AppColors.primaryContainer.withOpacity(0.7),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.onPrimaryContainer,
                                ))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('AUTHORIZE ACCESS',
                                    style: GoogleFonts.lexend(
                                      fontSize: 13, fontWeight: FontWeight.w900,
                                      letterSpacing: 2, color: AppColors.onPrimaryContainer,
                                    )),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push(AppConstants.routeRegister),
                        child: Text('DON\'T HAVE AN ACCOUNT? REGISTER',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppColors.primary, letterSpacing: 1.5,
                          )),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Divider(color: Color(0x1A484847)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('© 2024 IRON PULSE NETWORKS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 8, color: AppColors.outlineVariant, letterSpacing: 2,
                          )),
                        Row(children: [
                          _FooterLink('SUPPORT'),
                          const SizedBox(width: 16),
                          _FooterLink('PRIVACY'),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF131313), Color(0xFF000000)],
        ),
        border: Border(right: BorderSide(color: Color(0x1A484847))),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.5,
                    colors: [AppColors.primaryContainer, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('KINETIC',
                  style: GoogleFonts.lexend(
                    fontSize: 96, fontWeight: FontWeight.w900,
                    color: AppColors.primaryContainer,
                    fontStyle: FontStyle.italic, letterSpacing: -4, height: 0.9,
                  )),
                Container(
                  width: 96, height: 8, color: AppColors.secondary,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                ),
                Text('ELITE PERFORMANCE\nMANAGEMENT ',
                  style: GoogleFonts.lexend(
                    fontSize: 36, fontWeight: FontWeight.w700,
                    color: AppColors.onSurface, letterSpacing: -1, height: 1.1,
                  )),
                RichText(
                  text: TextSpan(
                    text: 'ENGINEERED.',
                    style: GoogleFonts.lexend(
                      fontSize: 36, fontWeight: FontWeight.w700,
                      color: AppColors.secondary, letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 32, left: 32,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text('IRON PULSE DIGITAL ECOSYSTEM',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 8, color: AppColors.outlineVariant,
                  letterSpacing: 5, fontWeight: FontWeight.w600,
                )),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.spaceGrotesk(
      fontSize: 9, fontWeight: FontWeight.w700,
      color: AppColors.onSurfaceVariant, letterSpacing: 2.5,
    ));
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.spaceGrotesk(
      fontSize: 8, color: AppColors.onSurfaceVariant, letterSpacing: 2,
    ));
}
