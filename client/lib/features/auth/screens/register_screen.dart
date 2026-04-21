import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/kinetic_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _companyAddressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutExpo));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyAddressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final companyName = _companyNameCtrl.text.trim();
    final companyAddress = _companyAddressCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.register(
        name: name,
        email: email,
        password: password,
        companyName: companyName.isEmpty ? null : companyName,
        companyAddress: companyAddress.isEmpty ? null : companyAddress,
        phoneNumber: phone.isEmpty ? null : phone,
      );
      if (mounted) context.go(AppConstants.routeDashboard);
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned(
            bottom: -96,
            right: -96,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          if (isDesktop)
            Row(
              children: [
                Expanded(flex: 7, child: _BrandingPanel()),
                Expanded(flex: 5, child: _buildFormPanel(context)),
              ],
            )
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
                    if (MediaQuery.of(context).size.width <
                        AppConstants.mobileBreakpoint) ...[
                      const KineticLogo(fontSize: 36),
                      const SizedBox(height: 40),
                    ],
                    Text(
                      'CREATE ACCOUNT',
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join the elite gym management network.',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    _FieldLabel('FULL NAME'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      style: GoogleFonts.roboto(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'John Doe',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _FieldLabel('WORK EMAIL'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.roboto(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'owner@ironpulse.gym',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _FieldLabel('ACCESS KEY'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.roboto(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••••••',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.outlineVariant,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _FieldLabel('COMPANY NAME'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _companyNameCtrl,
                      style: GoogleFonts.roboto(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Iron Pulse Gym',
                        prefixIcon: Icon(
                          Icons.business_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _FieldLabel('COMPANY ADDRESS'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _companyAddressCtrl,
                      style: GoogleFonts.roboto(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: '123 Power St, Lift City',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _FieldLabel('PHONE NUMBER'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.roboto(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                      onSubmitted: (_) => _register(),
                      decoration: const InputDecoration(
                        hintText: '+1 234 567 890',
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        color: AppColors.errorContainer,
                        child: Text(
                          _error!,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              )
                            : Text(
                                'REGISTER TERMINAL',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'ALREADY HAVE AN ACCOUNT? LOGIN',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF131313), Color(0xFF000000)],
        ),
        border: Border(right: BorderSide(color: Color(0x1A484847))),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'KINETIC',
              style: GoogleFonts.roboto(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryContainer,
                fontStyle: FontStyle.italic,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SYSTEM REGISTRATION',
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.roboto(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurfaceVariant,
      letterSpacing: 2.5,
    ),
  );
}
