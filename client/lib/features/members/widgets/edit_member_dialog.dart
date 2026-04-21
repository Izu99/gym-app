import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/member_model.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/repositories/tier_repository.dart';

import '../../../shared/widgets/custom_top_bar.dart';

class EditMemberDialog extends StatefulWidget {
  final ApiMember member;
  const EditMemberDialog({super.key, required this.member});

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  List<Tier> _tiers = [];
  Tier? _selectedTier;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
    _emailCtrl = TextEditingController(text: widget.member.email);
    _phoneCtrl = TextEditingController(text: widget.member.phone ?? '');
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    try {
      final tiers = await TierRepository.getTiers(includeArchived: true);
      if (mounted) {
        setState(() {
          _tiers = tiers;
          if (_tiers.isNotEmpty) {
            _selectedTier = _tiers.firstWhere(
              (t) => t.id == widget.member.tier || t.name == widget.member.tier,
              orElse: () => _tiers.first,
            );
          }
          _initialLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _initialLoading = false;
        });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedTier == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final initials = _nameCtrl.text
          .trim()
          .split(' ')
          .map((e) => e.isNotEmpty ? e[0] : '')
          .take(2)
          .join()
          .toUpperCase();

      await MemberRepository.updateMember(widget.member.id, {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'initials': initials,
        'tier': _selectedTier!.id,
        'monthlyFee': _selectedTier!.monthlyFee,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: _initialLoading
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTopBar(
                      title: 'EDIT PROTOCOL',
                      onClose: () => Navigator.pop(context),
                      showWindowControls: false,
                    ),

                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 24),
                                color: AppColors.errorContainer,
                                width: double.infinity,
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: AppColors.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],

                            _label('FULL NAME'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameCtrl,
                              style: GoogleFonts.roboto(
                                color: AppColors.onSurface,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'e.g. John Wick',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 24),

                            _label('WORK EMAIL'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.roboto(
                                color: AppColors.onSurface,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'john@example.com',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 24),

                            _label('PHONE NUMBER'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.roboto(
                                color: AppColors.onSurface,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: '+94 77 123 4567',
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            _label('MEMBERSHIP TIER'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _tiers.map((t) {
                                final isActive = _selectedTier?.id == t.id;
                                return InkWell(
                                  onTap: () =>
                                      setState(() => _selectedTier = t),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.primaryContainer
                                          : AppColors.surfaceContainerHighest,
                                      border: Border.all(
                                        color: isActive
                                            ? AppColors.primaryContainer
                                            : AppColors.outlineVariant
                                                  .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          t.name.toUpperCase(),
                                          style: GoogleFonts.roboto(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isActive
                                                ? AppColors.onPrimaryContainer
                                                : AppColors.onSurfaceVariant,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        Text(
                                          'Rs.${t.monthlyFee.toStringAsFixed(0)}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 8,
                                            color: isActive
                                                ? AppColors.onPrimaryContainer
                                                      .withOpacity(0.7)
                                                : AppColors.onSurfaceVariant
                                                      .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 48),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  foregroundColor: AppColors.onPrimaryContainer,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
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
                                        'UPDATE PARAMETERS',
                                        style: GoogleFonts.roboto(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.roboto(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurfaceVariant,
      letterSpacing: 2.5,
    ),
  );
}
