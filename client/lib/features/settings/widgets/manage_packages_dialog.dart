import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/data_sync_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/tier_repository.dart';
import '../../../shared/widgets/custom_top_bar.dart';

class ManagePackagesDialog extends StatefulWidget {
  const ManagePackagesDialog({super.key});

  @override
  State<ManagePackagesDialog> createState() => _ManagePackagesDialogState();
}

class _ManagePackagesDialogState extends State<ManagePackagesDialog> {
  late Future<List<Tier>> _future;
  bool _isEditing = false;
  Tier? _editingTier;

  final _nameCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _joiningFeeCtrl = TextEditingController(text: '0');
  final _descriptionCtrl = TextEditingController();
  String _billingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = TierRepository.getTiers(
      forceRefresh: true,
      includeArchived: true,
    );
  }

  void _startEdit(Tier? tier) {
    setState(() {
      _isEditing = true;
      _editingTier = tier;
      _nameCtrl.text = tier?.name ?? '';
      _feeCtrl.text = tier?.monthlyFee.toStringAsFixed(0) ?? '';
      _joiningFeeCtrl.text = tier?.joiningFee.toStringAsFixed(0) ?? '0';
      _descriptionCtrl.text = tier?.description ?? '';
      _billingCycle = tier?.billingCycle ?? 'monthly';
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editingTier = null;
      _nameCtrl.clear();
      _feeCtrl.clear();
      _joiningFeeCtrl.text = '0';
      _descriptionCtrl.clear();
      _billingCycle = 'monthly';
    });
  }

  Future<void> _save() async {
    final monthlyFee = double.tryParse(_feeCtrl.text.trim());
    final joiningFee = double.tryParse(_joiningFeeCtrl.text.trim()) ?? 0;

    if (_nameCtrl.text.trim().isEmpty || monthlyFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package name and monthly fee are required')),
      );
      return;
    }

    final body = {
      'name': _nameCtrl.text.trim(),
      'monthlyFee': monthlyFee,
      'joiningFee': joiningFee,
      'description': _descriptionCtrl.text.trim(),
      'billingCycle': _billingCycle,
      'status': _editingTier?.status ?? 'active',
    };

    try {
      if (_editingTier == null) {
        await TierRepository.createTier(body);
      } else {
        await TierRepository.updateTier(_editingTier!.id, body);
      }

      dataSync.notify(DataRefreshEvent.tiers);
      setState(() {
        _cancelEdit();
        _load();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _archive(String id) async {
    try {
      await TierRepository.deleteTier(id);
      dataSync.notify(DataRefreshEvent.tiers);
      setState(() => _load());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _feeCtrl.dispose();
    _joiningFeeCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          children: [
            CustomTopBar(
              title: 'PACKAGE MANAGEMENT',
              onClose: () => Navigator.pop(context),
              showWindowControls: false,
              actions: [
                if (_isEditing)
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('CANCEL'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _startEdit(null),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('ADD PACKAGE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            Expanded(child: _isEditing ? _buildEditor() : _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingTier == null ? 'CREATE PACKAGE' : 'EDIT PACKAGE',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          _label('DISPLAY NAME'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: 'e.g. PLATINUM ELITE'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('PACKAGE PRICE (RS.)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '15000'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('JOINING FEE (RS.)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _joiningFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _label('BILLING CYCLE'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _billingCycle,
            dropdownColor: AppColors.surfaceContainer,
            items: const [
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'quarterly', child: Text('3 Months')),
              DropdownMenuItem(
                value: 'half_yearly',
                child: Text('6 Months'),
              ),
              DropdownMenuItem(value: 'yearly', child: Text('12 Months')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _billingCycle = value);
            },
          ),
          const SizedBox(height: 24),
          _label('DESCRIPTION'),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Summarize benefits, access level, and ideal member profile',
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppColors.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PACKAGE PREVIEW',
                  style: GoogleFonts.roboto(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _nameCtrl.text.trim().isEmpty
                      ? 'UNNAMED PACKAGE'
                      : _nameCtrl.text.trim().toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs.${_feeCtrl.text.isEmpty ? '0' : _feeCtrl.text} / ${_billingCycleLabel(_billingCycle)}',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joining fee: Rs.${_joiningFeeCtrl.text.isEmpty ? '0' : _joiningFeeCtrl.text}',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (_descriptionCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _descriptionCtrl.text.trim(),
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
              ),
              child: Text(
                _editingTier == null ? 'CREATE PACKAGE' : 'SAVE PACKAGE',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Tier>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tiers = snap.data!;
        if (tiers.isEmpty) {
          return Center(
            child: Text(
              'No packages yet',
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: tiers.length,
          itemBuilder: (context, i) {
            final tier = tiers[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x0D484847))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tier.name,
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              color: tier.isArchived
                                  ? AppColors.secondaryContainer
                                  : AppColors.primaryContainer.withOpacity(0.15),
                              child: Text(
                                tier.isArchived ? 'ARCHIVED' : 'ACTIVE',
                                style: GoogleFonts.roboto(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: tier.isArchived
                                      ? AppColors.onSecondaryContainer
                                      : AppColors.primaryContainer,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rs.${tier.monthlyFee.toStringAsFixed(0)} / ${tier.billingCycleLabel}',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Joining fee: Rs.${tier.joiningFee.toStringAsFixed(0)}',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (tier.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              tier.description,
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _startEdit(tier),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  if (!tier.isArchived)
                    IconButton(
                      onPressed: () => _archive(tier.id),
                      icon: const Icon(
                        Icons.archive_outlined,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.roboto(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurfaceVariant,
      letterSpacing: 2,
    ),
  );

  String _billingCycleLabel(String cycle) {
    switch (cycle) {
      case 'quarterly':
        return '3 MONTHS';
      case 'half_yearly':
        return '6 MONTHS';
      case 'yearly':
        return '12 MONTHS';
      default:
        return '1 MONTH';
    }
  }
}
