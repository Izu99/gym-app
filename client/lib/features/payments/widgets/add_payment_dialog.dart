import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/tier_repository.dart';

import '../../../core/services/data_sync_controller.dart';
import '../../../shared/widgets/custom_top_bar.dart';

class AddPaymentDialog extends StatefulWidget {
  const AddPaymentDialog({super.key});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  List<ApiMember> _members = [];
  List<Tier> _tiers = [];
  ApiMember? _selectedMember;
  Tier? _selectedTier;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final results = await Future.wait([
        MemberRepository.getMembers(limit: 1000),
        TierRepository.getTiers(),
      ]);
      final page = results[0] as MembersPage;
      final tiers = results[1] as List<Tier>;
      if (mounted) {
        setState(() {
          _members = page.members;
          _tiers = tiers.where((tier) => !tier.isArchived).toList();
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
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMember() async {
    final selected = await showDialog<ApiMember>(
      context: context,
      builder: (context) => _PaymentMemberSearchDialog(
        members: _members,
        selectedMemberId: _selectedMember?.id,
      ),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedMember = selected;
      _selectedTier = _tiers.cast<Tier?>().firstWhere(
        (tier) => tier?.id == selected.tier,
        orElse: () => _tiers.isNotEmpty ? _tiers.first : null,
      );
      _amountCtrl.text =
          (_selectedTier?.monthlyFee ?? selected.monthlyFee).toStringAsFixed(0);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedMember == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await PaymentRepository.createPayment({
        'member': _selectedMember!.id,
        'tierId': _selectedTier?.id,
        'plan': _selectedTier?.name ?? _selectedMember!.tierLabel,
        'amount': double.parse(_amountCtrl.text),
        'status': 'pending',
        'dueDate': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
      });

      if (mounted) {
        dataSync.notify(DataRefreshEvent.payments);
        dataSync.notify(
          DataRefreshEvent.members,
        ); // Payment might affect member status

        final selected = _selectedMember!;
        final amt = double.parse(_amountCtrl.text);
        final p = _selectedTier?.name ?? selected.tierLabel;

        // Show Receipt
        showDialog(
          context: context,
          builder: (context) =>
              _ReceiptDialog(member: selected, amount: amt, plan: p),
        ).then((_) {
          if (mounted) Navigator.pop(context, true);
        });
      }
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
                      title: 'PAYMENT ENTRY',
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

                            _label('SELECT MEMBER'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _members.isEmpty ? null : _pickMember,
                              icon: const Icon(Icons.search, size: 18),
                              label: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _selectedMember == null
                                      ? 'SEARCH MEMBER BY NAME / PHONE / EMAIL'
                                      : '${_selectedMember!.name.toUpperCase()}${_selectedMember!.phone?.isNotEmpty == true ? ' • ${_selectedMember!.phone}' : ''}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.onSurface,
                                side: BorderSide(
                                  color: AppColors.outlineVariant.withOpacity(
                                    0.25,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            _label('PACKAGE'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Tier>(
                              value: _selectedTier,
                              items: _tiers
                                  .map(
                                    (tier) => DropdownMenuItem<Tier>(
                                      value: tier,
                                      child: Text(
                                        '${tier.name.toUpperCase()} • RS.${tier.monthlyFee.toStringAsFixed(0)}',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (tier) {
                                setState(() {
                                  _selectedTier = tier;
                                  if (tier != null) {
                                    _amountCtrl.text = tier.monthlyFee
                                        .toStringAsFixed(0);
                                  }
                                });
                              },
                              dropdownColor: AppColors.surfaceContainer,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.workspace_premium_outlined,
                                  size: 20,
                                ),
                                hintText: 'Select package',
                              ),
                              validator: (value) =>
                                  value == null ? 'Select package' : null,
                            ),
                            const SizedBox(height: 24),

                            _label('AMOUNT (RS.)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.roboto(
                                color: AppColors.onSurface,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: '5000',
                                prefixIcon: Icon(
                                  Icons.payments_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
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
                                        'GENERATE INVOICE',
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

class _PaymentMemberSearchDialog extends StatefulWidget {
  final List<ApiMember> members;
  final String? selectedMemberId;

  const _PaymentMemberSearchDialog({
    required this.members,
    this.selectedMemberId,
  });

  @override
  State<_PaymentMemberSearchDialog> createState() =>
      _PaymentMemberSearchDialogState();
}

class _PaymentMemberSearchDialogState extends State<_PaymentMemberSearchDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.members.where((member) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return member.name.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query) ||
          (member.phone?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIND MEMBER',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (value) => setState(() => _query = value),
                    autofocus: true,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, or email',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.clear, size: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x1A484847)),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No members found',
                        style: GoogleFonts.roboto(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final member = filtered[index];
                        final isSelected = member.id == widget.selectedMemberId;
                        return ListTile(
                          tileColor: isSelected
                              ? AppColors.primaryContainer.withOpacity(0.12)
                              : null,
                          title: Text(
                            member.name.toUpperCase(),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (member.phone?.isNotEmpty == true) member.phone!,
                              member.email,
                            ].join(' • '),
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryContainer,
                                  size: 18,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, member),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptDialog extends StatelessWidget {
  final ApiMember member;
  final double amount;
  final String plan;

  const _ReceiptDialog({
    required this.member,
    required this.amount,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = "${now.day} ${_getMonth(now.month)} ${now.year}";
    final invoiceNo =
        "INV-${now.millisecondsSinceEpoch.toString().substring(7)}";

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTopBar(
              title: 'PAYMENT RECEIPT',
              onClose: () => Navigator.pop(context),
              showWindowControls: false,
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PAYMENT SUCCESSFUL',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The transaction has been processed.',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _receiptRow('INVOICE NO', invoiceNo),
                  _receiptRow('DATE', dateStr),
                  _receiptRow('MEMBER', member.name.toUpperCase()),
                  _receiptRow('PLAN', plan.toUpperCase()),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.outlineVariant),
                  ),
                  _receiptRow(
                    'TOTAL AMOUNT',
                    'RS.${amount.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(
                        'DOWNLOAD PDF',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: isBold ? AppColors.primary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonth(int m) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[m - 1];
  }
}
