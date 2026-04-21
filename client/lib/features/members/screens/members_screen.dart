import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/member_model.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../core/services/data_sync_controller.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/avatar_placeholder.dart';

import '../widgets/edit_member_dialog.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  int _filterIndex = 0;
  int _currentPage = 1;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  late Future<MembersPage> _future;

  static const _statusFilters = [null, 'paid', 'overdue'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _load();
    dataSync.addListener(_onDataSync);
  }

  void _onDataSync() {
    if (mounted) {
      setState(() => _load());
    }
  }

  @override
  void dispose() {
    dataSync.removeListener(_onDataSync);
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    _future = MemberRepository.getMembers(
      status: _statusFilters[_filterIndex],
      page: _currentPage,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _onSearch(String val) {
    setState(() {
      _searchQuery = val;
      _currentPage = 1;
      _load();
    });
  }

  void _setFilter(int idx) => setState(() {
    _filterIndex = idx;
    _currentPage = 1;
    _load();
  });

  void _setPage(int p) => setState(() {
    _currentPage = p;
    _load();
  });

  Future<void> _deleteMember(ApiMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'DELETE MEMBER',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w900,
            color: AppColors.error,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently remove ${member.name}? This action cannot be undone.',
          style: GoogleFonts.roboto(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.roboto(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await MemberRepository.deleteMember(member.id);
        dataSync.notify(DataRefreshEvent.members);
        setState(() => _load());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editMember(ApiMember member) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditMemberDialog(member: member),
    );
    if (result == true) {
      dataSync.notify(DataRefreshEvent.members);
      setState(() => _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return FadeTransition(
      opacity: _fade,
      child: FutureBuilder<MembersPage>(
        future: _future,
        builder: (context, snap) {
          final page = snap.data;
          final loading = snap.connectionState == ConnectionState.waiting;

          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ERROR LOADING MEMBERS',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _load()),
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 40 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDesktop) ...[
                    _buildHeader(isDesktop, page),
                    const SizedBox(height: 40),
                  ],
                  _buildTable(isDesktop, page, loading),
                  const SizedBox(height: 40),
                  _buildInsightsRow(isDesktop, page),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, MembersPage? page) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'MEMBER ',
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 48 : 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: -1.5,
                    ),
                  ),
                  TextSpan(
                    text: 'MANAGEMENT',
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 48 : 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryContainer,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 96,
              height: 4,
              color: AppColors.primaryContainer,
              margin: const EdgeInsets.only(top: 8),
            ),
          ],
        ),
        if (isDesktop) const Spacer(),
        if (isDesktop && page != null) ...[
          _StatBadge(
            label: 'TOTAL MEMBERS',
            value: '${page.total}',
            borderColor: AppColors.secondary,
          ),
          const SizedBox(width: 16),
          _StatBadge(
            label: 'PAGE ${page.page} OF ${page.pages}',
            value: '${page.members.length}',
            borderColor: AppColors.primaryContainer,
          ),
        ],
      ],
    );
  }

  Widget _buildTable(bool isDesktop, MembersPage? page, bool loading) {
    final members = page?.members ?? [];
    final total = page?.total ?? 0;
    final pages = page?.pages ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Filter tabs and Search
          Container(
            color: AppColors.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterTab(
                    label: 'ALL MEMBERS',
                    count: _filterIndex == 0 ? '$total' : null,
                    isActive: _filterIndex == 0,
                    onTap: () => _setFilter(0),
                  ),
                  const SizedBox(width: 24),
                  _FilterTab(
                    label: 'ACTIVE ONLY',
                    isActive: _filterIndex == 1,
                    onTap: () => _setFilter(1),
                  ),
                  const SizedBox(width: 24),
                  _FilterTab(
                    label: 'OVERDUE',
                    isActive: _filterIndex == 2,
                    onTap: () => _setFilter(2),
                  ),
                  if (isDesktop) const SizedBox(width: 40),
                  // Search Bar
                  if (isDesktop)
                    Container(
                      width: 200,
                      height: 36,
                      margin: const EdgeInsets.only(right: 16),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearch,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'SEARCH NAME...',
                          hintStyle: GoogleFonts.roboto(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(2),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  if (loading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (isDesktop)
            Container(
              color: AppColors.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _TableHeader('MEMBER PROFILE')),
                  Expanded(flex: 2, child: _TableHeader('MEMBERSHIP TYPE')),
                  Expanded(flex: 2, child: _TableHeader('PAYMENT STATUS')),
                  Expanded(flex: 2, child: _TableHeader('MONTHLY FEE')),
                  const SizedBox(width: 40),
                ],
              ),
            ),

          if (loading && members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryContainer,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'No members found',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...members.map(
              (m) => _MemberRow(
                member: m,
                isDesktop: isDesktop,
                onEdit: () => _editMember(m),
                onDelete: () => _deleteMember(m),
              ),
            ),

          // Pagination
          Container(
            color: AppColors.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SHOWING ${members.length} OF $total MEMBERS',
                  style: GoogleFonts.roboto(
                    fontSize: 9,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  children: [
                    _PageBtn(
                      icon: Icons.chevron_left,
                      onTap: _currentPage > 1
                          ? () => _setPage(_currentPage - 1)
                          : () {},
                    ),
                    const SizedBox(width: 4),
                    ...List.generate(
                      pages.clamp(1, 5),
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _PageBtn(
                          label: '${i + 1}',
                          isActive: _currentPage == i + 1,
                          onTap: () => _setPage(i + 1),
                        ),
                      ),
                    ),
                    _PageBtn(
                      icon: Icons.chevron_right,
                      onTap: _currentPage < pages
                          ? () => _setPage(_currentPage + 1)
                          : () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsRow(bool isDesktop, MembersPage? page) {
    final overdueCount =
        page?.members
            .where((m) => m.paymentStatus == PaymentStatus.overdue)
            .length ??
        0;

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 2, child: _InsightsCard(total: page?.total)),
          const SizedBox(width: 24),
          Expanded(child: _PendingPaymentsCard(count: overdueCount)),
        ],
      );
    }
    return Column(
      children: [
        _InsightsCard(total: page?.total),
        const SizedBox(height: 16),
        _PendingPaymentsCard(count: overdueCount),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ApiMember member;
  final bool isDesktop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberRow({
    required this.member,
    required this.isDesktop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktop)
      return _MobileRow(member: member, onEdit: onEdit, onDelete: onDelete);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0D484847))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          hoverColor: AppColors.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      AvatarPlaceholder(
                        initials: member.initials,
                        size: 44,
                        paymentStatus: member.paymentStatus,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name.toUpperCase(),
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.onSurface,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'SINCE ${member.memberSince.toUpperCase()}',
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (member.phone != null &&
                                member.phone!.isNotEmpty)
                              Text(
                                member.phone!,
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant.withOpacity(
                                    0.7,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: MemberTierChip(
                    tier: member.tier,
                    tierLabel: member.tierLabel,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: PaymentStatusChip(status: member.paymentStatus),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Rs.${member.monthlyFee.toStringAsFixed(0)}/mo',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceContainer,
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'EDIT',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'DELETE',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileRow extends StatelessWidget {
  final ApiMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileRow({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0D484847))),
        ),
        child: Row(
          children: [
            AvatarPlaceholder(
              initials: member.initials,
              size: 44,
              paymentStatus: member.paymentStatus,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name.toUpperCase(),
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    member.tierLabel,
                    style: GoogleFonts.roboto(
                      fontSize: 9,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (member.phone != null && member.phone!.isNotEmpty)
                    Text(
                      member.phone!,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            MemberTierChip(tier: member.tier, tierLabel: member.tierLabel),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color borderColor;
  const _StatBadge({
    required this.label,
    required this.value,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(left: BorderSide(color: borderColor, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 8,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final String? count;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? AppColors.primaryContainer
                  : AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: isActive
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHighest,
              child: Text(
                count!,
                style: GoogleFonts.roboto(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isActive
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.roboto(
      fontSize: 9,
      fontWeight: FontWeight.w900,
      color: AppColors.onSurfaceVariant,
      letterSpacing: 2.5,
    ),
  );
}

class _PageBtn extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final bool isActive;
  final VoidCallback onTap;
  const _PageBtn({
    this.icon,
    this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : Colors.transparent,
          border: Border.all(
            color: isActive
                ? AppColors.primaryContainer.withOpacity(0.3)
                : AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 16, color: AppColors.onSurfaceVariant)
            : Text(
                label!,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isActive
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final int? total;
  const _InsightsCard({this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'MEMBER RETENTION ',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'INSIGHTS',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryContainer,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total != null
                ? 'You have $total total members in the system. Monitor payment status and attendance to improve retention.'
                : 'Loading member insights...',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'GENERATE FULL REPORT',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppColors.primaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentsCard extends StatelessWidget {
  final int count;
  const _PendingPaymentsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.bolt, color: AppColors.onSecondary, size: 36),
          const SizedBox(height: 12),
          Text(
            '$count OVERDUE\nPAYMENTS',
            style: GoogleFonts.roboto(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.onSecondary,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onSecondary,
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'REVIEW ALL',
                style: GoogleFonts.roboto(
                  fontSize: 10,
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
}
