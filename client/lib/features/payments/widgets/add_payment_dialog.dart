import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/repositories/payment_repository.dart';

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
  final _searchCtrl = TextEditingController();
  
  List<ApiMember> _members = [];
  List<ApiMember> _filteredMembers = [];
  ApiMember? _selectedMember;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _members;
      } else {
        _filteredMembers = _members.where((m) {
          return m.name.toLowerCase().contains(query) || 
                 (m.phone?.contains(query) ?? false) ||
                 m.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadMembers() async {
    try {
      final page = await MemberRepository.getMembers(limit: 1000);
      if (mounted) {
        setState(() {
          _members = page.members;
          _filteredMembers = _members;
          _initialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _initialLoading = false; });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
        'plan': _selectedMember!.tierLabel,
        'amount': double.parse(_amountCtrl.text),
        'status': 'pending',
        'dueDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      });

      if (mounted) {
        dataSync.notify(DataRefreshEvent.payments);
        dataSync.notify(DataRefreshEvent.members); // Payment might affect member status
        
        final selected = _selectedMember!;
        final amt = double.parse(_amountCtrl.text);
        final p = selected.tierLabel;

        // Show Receipt
        showDialog(
          context: context,
          builder: (context) => _ReceiptDialog(
            member: selected,
            amount: amt,
            plan: p,
          ),
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
          ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
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
                          child: Text(_error!, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onErrorContainer)),
                        ),
                      ],

                      _label('SELECT MEMBER'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ApiMember>(
                        value: _selectedMember,
                        items: _filteredMembers.take(20).map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name.toUpperCase(), style: GoogleFonts.lexend(fontSize: 13, color: AppColors.onSurface)),
                        )).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMember = val;
                            if (val != null) _amountCtrl.text = val.monthlyFee.toStringAsFixed(0);
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          hintText: 'Search or select member',
                          suffixIcon: _searchCtrl.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => _searchCtrl.clear(),
                              )
                            : null,
                        ),
                        dropdownColor: AppColors.surfaceContainer,
                        selectedItemBuilder: (context) {
                          return _filteredMembers.take(20).map((m) {
                            return Text(m.name.toUpperCase(), style: GoogleFonts.lexend(fontSize: 13, color: AppColors.onSurface));
                          }).toList();
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _searchCtrl,
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'FILTER BY NAME, PHONE OR EMAIL...',
                          hintStyle: GoogleFonts.spaceGrotesk(fontSize: 10, letterSpacing: 1, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _label('AMOUNT (RS.)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.manrope(color: AppColors.onSurface, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '5000',
                          prefixIcon: Icon(Icons.payments_outlined, size: 20),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 48),

                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: AppColors.onPrimaryContainer,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimaryContainer))
                              : Text('GENERATE INVOICE',
                                  style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
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

  Widget _label(String text) => Text(text,
      style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 2.5));
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
    final invoiceNo = "INV-${now.millisecondsSinceEpoch.toString().substring(7)}";

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
                  const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 64),
                  const SizedBox(height: 24),
                  Text('PAYMENT SUCCESSFUL',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 8),
                  Text('The transaction has been processed.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      )),
                  const SizedBox(height: 32),
                  _receiptRow('INVOICE NO', invoiceNo),
                  _receiptRow('DATE', dateStr),
                  _receiptRow('MEMBER', member.name.toUpperCase()),
                  _receiptRow('PLAN', plan.toUpperCase()),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.outlineVariant),
                  ),
                  _receiptRow('TOTAL AMOUNT', 'RS.${amount.toStringAsFixed(2)}', isBold: true),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.download, size: 18),
                      label: Text('DOWNLOAD PDF',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          )),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.5,
              )),
          Text(value,
              style: GoogleFonts.lexend(
                fontSize: isBold ? 14 : 12,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
                color: isBold ? AppColors.primary : Colors.white,
              )),
        ],
      ),
    );
  }

  String _getMonth(int m) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[m - 1];
  }
}
