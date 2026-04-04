import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/manage_packages_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _companyAddressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _passLoading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.user;
    if (user != null) {
      _nameCtrl.text = user['name'] ?? '';
      _companyNameCtrl.text = user['companyName'] ?? '';
      _companyAddressCtrl.text = user['companyAddress'] ?? '';
      _phoneCtrl.text = user['phoneNumber'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyAddressCtrl.dispose();
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _loading = true);
    try {
      await AuthService.updateProfile(
        name: _nameCtrl.text.trim(),
        companyName: _companyNameCtrl.text.trim().isEmpty ? null : _companyNameCtrl.text.trim(),
        companyAddress: _companyAddressCtrl.text.trim().isEmpty ? null : _companyAddressCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updatePassword() async {
    final pass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (pass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill both password fields')),
      );
      return;
    }

    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _passLoading = true);
    try {
      await AuthService.updatePassword(pass);
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _passLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop) ...[
            Text('COMPANY PROFILE',
              style: GoogleFonts.lexend(
                fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w900,
                color: AppColors.onSurface, letterSpacing: -1.5,
              )),
            const SizedBox(height: 8),
            Text('MANAGE YOUR GYM INFORMATION AND SYSTEM SECURITY',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10, color: AppColors.onSurfaceVariant,
                letterSpacing: 3, fontWeight: FontWeight.w600,
              )),
            const SizedBox(height: 40),
          ],

          _buildSection(
            'GYM PACKAGES',
            [
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MEMBERSHIP TIERS', style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                          Text('Create and edit your gym membership packages and fees.', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => showDialog(context: context, builder: (c) => const ManagePackagesDialog()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer, 
                        foregroundColor: AppColors.onPrimaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      child: const Text('MANAGE PACKAGES'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          _buildSection(
            'FACILITY DETAILS',
            [
              _buildEditTile('Owner Name', _nameCtrl),
              _buildEditTile('Gym Name', _companyNameCtrl),
              _buildEditTile('Address', _companyAddressCtrl),
              _buildEditTile('Phone', _phoneCtrl, keyboardType: TextInputType.phone),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer, 
                      foregroundColor: AppColors.onPrimaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                    child: _loading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimaryContainer))
                      : const Text('SAVE PROFILE CHANGES'),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          _buildSection(
            'SECURITY',
            [
              _buildEditTile('New Password', _newPassCtrl, obscureText: true),
              _buildEditTile('Confirm Password', _confirmPassCtrl, obscureText: true),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _passLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHighest, 
                      foregroundColor: AppColors.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                    child: _passLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onSurface))
                      : const Text('RESET PASSWORD'),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          _buildSection(
            'SYSTEM INFORMATION',
            [
              _buildSettingTile('API Endpoint', AppConstants.apiBase),
              _buildSettingTile('System ID', 'KINETIC-${AuthService.user?['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNK'}'),
              _buildSettingTile('Connection Status', 'STABLE', isStatus: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
          style: GoogleFonts.lexend(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.primaryContainer, letterSpacing: 2,
          )),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildEditTile(String label, TextEditingController controller, {bool obscureText = false, TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0D484847))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9, color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700, letterSpacing: 1.5,
            )),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurface),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String label, String value, {bool isStatus = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0D484847))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11, color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600, letterSpacing: 1,
            )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: isStatus ? AppColors.primaryContainer.withOpacity(0.1) : AppColors.surfaceContainerHighest,
            child: Text(value,
              style: GoogleFonts.lexend(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: isStatus ? AppColors.primaryContainer : AppColors.onSurface,
              )),
          ),
        ],
      ),
    );
  }
}
