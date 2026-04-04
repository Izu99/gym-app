import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/member_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../core/services/data_sync_controller.dart';
import '../../../shared/widgets/avatar_placeholder.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  DateTime _selectedDate = DateTime.now();
  int _sessionIndex = 0;
  int _currentPage = 1;
  String _searchQuery = '';
  bool _showOnlyPresent = false;
  final _searchCtrl = TextEditingController();

  late Future<AttendancePage> _future;
  final List<String> _sessions = ['ALL', 'Morning', 'Afternoon', 'Evening'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _load();
    dataSync.addListener(_onDataSync);
  }

  void _onDataSync() {
    if (mounted) _load();
  }

  @override
  void dispose() { 
    dataSync.removeListener(_onDataSync);
    _ctrl.dispose(); 
    _searchCtrl.dispose();
    super.dispose(); 
  }

  void _load() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      _future = AttendanceRepository.getAttendance(
        date: dateStr,
        session: _sessions[_sessionIndex],
        page: _currentPage,
      );
    });
  }

  void _onSearch(String val) => setState(() { _searchQuery = val; });

  void _setSession(int idx) {
    _sessionIndex = idx;
    _currentPage = 1;
    _load();
  }

  void _setPage(int p) {
    _currentPage = p;
    _load();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryContainer,
            onPrimary: AppColors.onPrimaryContainer,
            surface: AppColors.surface,
            onSurface: AppColors.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _currentPage = 1;
        _load();
      });
    }
  }

  Future<void> _markAttendance(String memberId, bool present) async {
    try {
      await AttendanceRepository.markAttendance(
        memberId: memberId,
        isPresent: present,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        session: _sessionIndex == 0 ? 'Morning' : _sessions[_sessionIndex],
      );
      dataSync.notify(DataRefreshEvent.attendance);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorContainer,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return FadeTransition(
      opacity: _fade,
      child: FutureBuilder<AttendancePage>(
        future: _future,
        builder: (context, snap) {
          final page = snap.data;
          final loading = snap.connectionState == ConnectionState.waiting;
          final records = (page?.records ?? []).where((r) {
            final matchesSearch = r.memberName.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesStatus = !_showOnlyPresent || r.status == AttendanceStatus.present;
            return matchesSearch && matchesStatus;
          }).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 40 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isDesktop) ...[
                  _buildHeader(isDesktop, page),
                  const SizedBox(height: 40),
                ],
                _buildFilterBar(isDesktop, loading, page?.total ?? 0),
                const SizedBox(height: 8),
                _buildAttendanceTable(isDesktop, records, loading, page),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, AttendancePage? page) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PROTOCOL COMPLIANCE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10, color: AppColors.primaryContainer,
                letterSpacing: 3, fontWeight: FontWeight.w700,
              )),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _selectDate,
              child: Row(
                children: [
                  Text('ATTENDANCE ',
                    style: GoogleFonts.lexend(
                      fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w900,
                      color: AppColors.onSurface, letterSpacing: -1.5,
                    )),
                  Text(DateFormat('MM.dd').format(_selectedDate),
                    style: GoogleFonts.lexend(
                      fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w900,
                      color: AppColors.primaryContainer,
                      fontStyle: FontStyle.italic, letterSpacing: -1.5,
                    )),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today_outlined, color: AppColors.primaryContainer, size: 24),
                ],
              ),
            ),
          ],
        ),
        if (isDesktop) const Spacer(),
        if (isDesktop && page != null) ...[
          _StatBadge(label: 'CHECKED IN', value: '${page.records.where((r)=>r.status == AttendanceStatus.present).length}'),
          const SizedBox(width: 16),
          _StatBadge(label: 'EXPECTED', value: '${page.total}'),
        ],
      ],
    );
  }

  Widget _buildFilterBar(bool isDesktop, bool loading, int total) {
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          ..._sessions.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 24),
            child: _FilterTab(
              label: e.value.toUpperCase(),
              isActive: _sessionIndex == e.key,
              onTap: () => _setSession(e.key),
            ),
          )),
          const Spacer(),
          Text('PRESENT ONLY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10, color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5, fontWeight: FontWeight.w600,
            )),
          const SizedBox(width: 8),
          Switch(
            value: _showOnlyPresent,
            onChanged: (v) => setState(() => _showOnlyPresent = v),
            activeColor: AppColors.primaryContainer,
          ),
          const SizedBox(width: 16),
          Container(
            width: 200, height: 36,
            margin: const EdgeInsets.only(right: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'FILTER ROSTER...',
                hintStyle: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.onSurfaceVariant),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (loading) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable(bool isDesktop, List<ApiAttendanceRecord> records, bool loading, AttendancePage? page) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              color: AppColors.surfaceContainerHighest.withOpacity(0.3),
              child: Row(children: [
                Expanded(flex: 4, child: _ColHeader('MEMBER')),
                Expanded(flex: 2, child: _ColHeader('SESSION')),
                Expanded(flex: 2, child: _ColHeader('CHECK-IN')),
                Expanded(flex: 2, child: _ColHeader('STATUS / ACTION', align: TextAlign.right)),
              ]),
            ),
          
          if (loading && records.isEmpty)
            const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
          else if (records.isEmpty)
            Padding(padding: const EdgeInsets.all(48), child: Center(child: Text('No records for this selection')))
          else
            ...records.map((r) => _AttendanceRow(
              record: r, isDesktop: isDesktop,
              onToggle: (p) => _markAttendance(r.memberId, p),
            )),

          // Pagination
          if (page != null && page.pages > 1)
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PAGE ${page.page} OF ${page.pages}', style: GoogleFonts.spaceGrotesk(fontSize: 9, color: AppColors.onSurfaceVariant)),
                  Row(children: [
                    IconButton(onPressed: _currentPage > 1 ? () => _setPage(_currentPage - 1) : null, icon: const Icon(Icons.chevron_left)),
                    IconButton(onPressed: _currentPage < page.pages ? () => _setPage(_currentPage + 1) : null, icon: const Icon(Icons.chevron_right)),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final ApiAttendanceRecord record;
  final bool isDesktop;
  final Function(bool) onToggle;
  const _AttendanceRow({required this.record, required this.isDesktop, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isPresent = record.status == AttendanceStatus.present;
    
    if (!isDesktop) {
      return ListTile(
        leading: AvatarPlaceholder(initials: record.memberInitials, size: 40, paymentStatus: record.paymentStatus),
        title: Text(record.memberName.toUpperCase(), style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w700)),
        subtitle: Text(record.session ?? 'No session', style: GoogleFonts.spaceGrotesk(fontSize: 10)),
        trailing: Switch(
          value: isPresent, 
          onChanged: onToggle,
          activeColor: AppColors.primaryContainer,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D484847)))),
      child: Row(children: [
        Expanded(flex: 4, child: Row(children: [
          AvatarPlaceholder(initials: record.memberInitials, size: 40, paymentStatus: record.paymentStatus),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.memberName.toUpperCase(), style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(record.email ?? '', style: GoogleFonts.manrope(fontSize: 10, color: AppColors.onSurfaceVariant)),
          ]),
        ])),
        Expanded(flex: 2, child: Text(record.session?.toUpperCase() ?? '—', style: GoogleFonts.spaceGrotesk(fontSize: 11))),
        Expanded(flex: 2, child: Text(record.checkinTime != null ? DateFormat('HH:mm').format(DateTime.parse(record.checkinTime!).toLocal()) : '—', style: GoogleFonts.spaceGrotesk(fontSize: 11))),
        Expanded(flex: 2, child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => onToggle(!isPresent),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPresent ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
              foregroundColor: isPresent ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isPresent ? Icons.check_circle : Icons.radio_button_unchecked, size: 12, color: isPresent ? Colors.white : AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(isPresent ? 'PRESENT' : 'MARK PRESENT', style: GoogleFonts.lexend(fontSize: 9, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        )),
      ]),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  const _StatBadge({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, border: Border(left: BorderSide(color: AppColors.primaryContainer, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 8, color: AppColors.onSurfaceVariant, letterSpacing: 2)),
        Text(value, style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
      ]),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterTab({required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceVariant, letterSpacing: 1.5)));
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _ColHeader(this.text, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) => Text(text, textAlign: align, style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.onSurfaceVariant, letterSpacing: 2.5));
}
