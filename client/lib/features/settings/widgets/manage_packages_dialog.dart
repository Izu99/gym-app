import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/tier_repository.dart';

import '../../../core/services/data_sync_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = TierRepository.getTiers(forceRefresh: true);
  }

  void _startEdit(Tier? t) {
    setState(() {
      _isEditing = true;
      _editingTier = t;
      _nameCtrl.text = t?.name ?? '';
      _feeCtrl.text = t?.monthlyFee.toStringAsFixed(0) ?? '';
    });
  }

  Future<void> _save() async {
    final body = {
      'name': _nameCtrl.text.trim(),
      'monthlyFee': double.parse(_feeCtrl.text),
    };

    try {
      if (_editingTier == null) {
        await TierRepository.createTier(body);
      } else {
        await TierRepository.updateTier(_editingTier!.id, body);
      }
      dataSync.notify(DataRefreshEvent.tiers);
      setState(() {
        _isEditing = false;
        _load();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(String id) async {
    try {
      await TierRepository.deleteTier(id);
      dataSync.notify(DataRefreshEvent.tiers);
      setState(() => _load());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            CustomTopBar(
              title: 'PACKAGE MANAGEMENT',
              onClose: () => Navigator.pop(context),
              showWindowControls: false,
              actions: [
                if (!_isEditing)
                  ElevatedButton.icon(
                    onPressed: () => _startEdit(null),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('ADD NEW'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: _isEditing ? _buildEditor() : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DISPLAY NAME'),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. PLATINUM ELITE')),
          const SizedBox(height: 24),
          _label('MONTHLY FEE (RS.)'),
          const SizedBox(height: 8),
          TextField(controller: _feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '15000')),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, foregroundColor: AppColors.onPrimaryContainer),
              child: Text('SAVE PACKAGE', style: GoogleFonts.lexend(fontWeight: FontWeight.w900, letterSpacing: 2)),
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
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final tiers = snap.data!;
        return ListView.builder(
          itemCount: tiers.length,
          itemBuilder: (context, i) {
            final t = tiers[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D484847)))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.name, style: GoogleFonts.lexend(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      Text('Rs.${t.monthlyFee.toStringAsFixed(0)}/mo', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    ]),
                  ),
                  IconButton(onPressed: () => _startEdit(t), icon: const Icon(Icons.edit_outlined, size: 18)),
                  IconButton(onPressed: () => _delete(t.id), icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 2));
}
