import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/data_sync_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/member_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/member_repository.dart';
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
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _sessionIndex = 0;
  int _currentPage = 1;
  String _searchQuery = '';
  bool _showOnlyPresent = false;
  bool _showCalendarView = false;
  final _searchCtrl = TextEditingController();

  late Future<AttendancePage> _future;
  late Future<List<ApiMember>> _membersFuture;
  Future<MemberAttendanceCalendar?>? _calendarFuture;
  ApiMember? _calendarMember;
  final List<String> _sessions = ['ALL', 'Morning', 'Afternoon', 'Evening'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _membersFuture = _loadMembers();
    _load();
    dataSync.addListener(_onDataSync);
  }

  Future<List<ApiMember>> _loadMembers() async {
    final page = await MemberRepository.getMembers(limit: 1000);
    final members = page.members;
    if (members.isNotEmpty && _calendarMember == null) {
      _calendarMember = members.first;
      _loadCalendar();
    }
    return members;
  }

  void _onDataSync() {
    if (!mounted) return;
    setState(() {
      _membersFuture = _loadMembers();
      _load();
      _loadCalendar();
    });
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
    _future = AttendanceRepository.getAttendance(
      date: dateStr,
      session: _sessions[_sessionIndex],
      page: _currentPage,
    );
  }

  void _loadCalendar() {
    if (_calendarMember == null) {
      _calendarFuture = Future.value(null);
      return;
    }
    _calendarFuture = AttendanceRepository.getMemberCalendar(
      memberId: _calendarMember!.id,
      month: _calendarMonth,
    );
  }

  Future<void> _pickCalendarMember(List<ApiMember> members) async {
    final selected = await showDialog<ApiMember>(
      context: context,
      builder: (context) => _MemberSearchDialog(
        members: members,
        selectedMemberId: _calendarMember?.id,
      ),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _calendarMember = selected;
      _loadCalendar();
    });
  }

  void _onSearch(String val) => setState(() {
    _searchQuery = val;
  });

  void _setSession(int idx) {
    setState(() {
      _sessionIndex = idx;
      _currentPage = 1;
      _load();
    });
  }

  void _setPage(int page) {
    setState(() {
      _currentPage = page;
      _load();
    });
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
      setState(() {
        _load();
        _loadCalendar();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 40 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDesktop),
            const SizedBox(height: 24),
            _buildViewToggle(),
            const SizedBox(height: 24),
            if (_showCalendarView) _buildCalendarView(isDesktop) else ...[
              FutureBuilder<AttendancePage>(
                future: _future,
                builder: (context, snap) {
                  final page = snap.data;
                  final loading = snap.connectionState == ConnectionState.waiting;
                  final records = (page?.records ?? []).where((record) {
                    final matchesSearch = record.memberName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                    final matchesStatus =
                        !_showOnlyPresent ||
                        record.status == AttendanceStatus.present;
                    return matchesSearch && matchesStatus;
                  }).toList();

                  return Column(
                    children: [
                      _buildFilterBar(isDesktop, loading, page?.total ?? 0),
                      const SizedBox(height: 8),
                      _buildAttendanceTable(isDesktop, records, loading, page),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PROTOCOL COMPLIANCE',
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: AppColors.primaryContainer,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _showCalendarView ? null : _selectDate,
              child: Row(
                children: [
                  Text(
                    _showCalendarView ? 'ATTENDANCE CALENDAR ' : 'ATTENDANCE ',
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 48 : 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Text(
                    _showCalendarView
                        ? DateFormat('MMM yyyy').format(_calendarMonth)
                        : DateFormat('MM.dd').format(_selectedDate),
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 48 : 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryContainer,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primaryContainer,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _ModeButton(
            label: 'DAILY ROSTER',
            isActive: !_showCalendarView,
            onTap: () => setState(() => _showCalendarView = false),
          ),
          const SizedBox(width: 12),
          _ModeButton(
            label: 'MEMBER CALENDAR',
            isActive: _showCalendarView,
            onTap: () => setState(() {
              _showCalendarView = true;
              _loadCalendar();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDesktop, bool loading, int total) {
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          ..._sessions.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(right: 24),
              child: _FilterTab(
                label: entry.value.toUpperCase(),
                isActive: _sessionIndex == entry.key,
                onTap: () => _setSession(entry.key),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'PRESENT ONLY',
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _showOnlyPresent,
            onChanged: (value) => setState(() => _showOnlyPresent = value),
            activeColor: AppColors.primaryContainer,
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'FILTER ROSTER... $total',
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
          if (loading) ...[
            const SizedBox(width: 16),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarView(bool isDesktop) {
    return FutureBuilder<List<ApiMember>>(
      future: _membersFuture,
      builder: (context, memberSnap) {
        final members = memberSnap.data ?? [];
        if (memberSnap.connectionState == ConnectionState.waiting && members.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (members.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            color: AppColors.surfaceContainerLow,
            child: Text(
              'No members available for calendar view.',
              style: GoogleFonts.roboto(color: AppColors.onSurfaceVariant),
            ),
          );
        }

        return Column(
          children: [
            Container(
              color: AppColors.surfaceContainer,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a member to inspect monthly attendance quickly.',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickCalendarMember(members),
                          icon: const Icon(Icons.search, size: 18),
                          label: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _calendarMember == null
                                  ? 'SEARCH MEMBER BY NAME / PHONE / EMAIL'
                                  : '${_calendarMember!.name.toUpperCase()}${_calendarMember!.phone?.isNotEmpty == true ? ' • ${_calendarMember!.phone}' : ''}',
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
                              color: AppColors.outlineVariant.withOpacity(0.25),
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
                      ),
                      const SizedBox(width: 16),
                      _MonthButton(
                        icon: Icons.chevron_left,
                        onTap: () => setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month - 1,
                          );
                          _loadCalendar();
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM yyyy').format(_calendarMonth),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MonthButton(
                        icon: Icons.chevron_right,
                        onTap: () => setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month + 1,
                          );
                          _loadCalendar();
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<MemberAttendanceCalendar?>(
              future: _calendarFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final calendar = snap.data;
                return _buildCalendarCard(calendar, isDesktop);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarCard(
    MemberAttendanceCalendar? calendar,
    bool isDesktop,
  ) {
    final days = _buildMonthCells(calendar);
    final presentCount = calendar?.records
            .where((record) => record.status == AttendanceStatus.present)
            .length ??
        0;
    final trackedDays = calendar?.records.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (calendar != null)
                AvatarPlaceholder(
                  initials: calendar.memberInitials,
                  size: 42,
                  paymentStatus: PaymentStatus.pending,
                ),
              if (calendar != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      calendar?.memberName.toUpperCase() ?? 'MEMBER CALENDAR',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '$presentCount present days recorded in $trackedDays tracked entries for this month.',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Legend(label: 'Present', color: AppColors.primaryContainer),
                  _Legend(label: 'Absent', color: AppColors.secondary),
                  _Legend(label: 'No record', color: AppColors.surfaceContainerHighest),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isDesktop ? 1.15 : 0.9,
            ),
            itemBuilder: (context, index) {
              final cell = days[index];
              if (!cell.inMonth) return const SizedBox.shrink();

              final status = cell.record?.status;
              final background = status == AttendanceStatus.present
                  ? AppColors.primaryContainer.withOpacity(0.2)
                  : status == AttendanceStatus.absent
                  ? AppColors.secondary.withOpacity(0.2)
                  : AppColors.surfaceContainerHighest;
              final border = status == AttendanceStatus.present
                  ? AppColors.primaryContainer
                  : status == AttendanceStatus.absent
                  ? AppColors.secondary
                  : AppColors.outlineVariant.withOpacity(0.2);

              return Tooltip(
                waitDuration: const Duration(milliseconds: 250),
                message: _buildCalendarTooltip(cell),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: background,
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('E').format(cell.date).toUpperCase(),
                        style: GoogleFonts.roboto(
                          fontSize: 8,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${cell.date.day}',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        status == AttendanceStatus.present
                            ? 'PRESENT'
                            : status == AttendanceStatus.absent
                            ? 'ABSENT'
                            : 'NO RECORD',
                        style: GoogleFonts.roboto(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: status == AttendanceStatus.present
                              ? AppColors.primaryContainer
                              : status == AttendanceStatus.absent
                              ? AppColors.secondary
                              : AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (cell.record?.session != null)
                        Text(
                          cell.record!.session!,
                          style: GoogleFonts.roboto(
                            fontSize: 9,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _buildCalendarTooltip(_CalendarCell cell) {
    final header = DateFormat('EEE, dd MMM yyyy').format(cell.date);
    final record = cell.record;
    if (record == null) {
      return '$header\nNo attendance record';
    }

    final status = record.status == AttendanceStatus.present
        ? 'Present'
        : record.status == AttendanceStatus.absent
        ? 'Absent'
        : 'Pending';
    final time = record.checkinTime != null
        ? DateFormat('HH:mm').format(DateTime.parse(record.checkinTime!).toLocal())
        : 'Not recorded';
    final session = record.session?.isNotEmpty == true ? record.session! : 'Not set';

    return '$header\nStatus: $status\nCheck-in: $time\nSession: $session';
  }

  List<_CalendarCell> _buildMonthCells(MemberAttendanceCalendar? calendar) {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastDay = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    final leadingEmpty = firstDay.weekday - 1;
    final recordMap = <String, MemberAttendanceCalendarDay>{};

    for (final record in calendar?.records ?? <MemberAttendanceCalendarDay>[]) {
      final key = DateFormat('yyyy-MM-dd').format(record.date.toLocal());
      recordMap[key] = record;
    }

    final cells = <_CalendarCell>[];
    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(
        _CalendarCell(date: firstDay.subtract(Duration(days: leadingEmpty - i)), inMonth: false),
      );
    }

    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
      final key = DateFormat('yyyy-MM-dd').format(date);
      cells.add(
        _CalendarCell(
          date: date,
          inMonth: true,
          record: recordMap[key],
        ),
      );
    }

    while (cells.length % 7 != 0) {
      final nextDate = lastDay.add(Duration(days: cells.length % 7));
      cells.add(_CalendarCell(date: nextDate, inMonth: false));
    }

    return cells;
  }

  Widget _buildAttendanceTable(
    bool isDesktop,
    List<ApiAttendanceRecord> records,
    bool loading,
    AttendancePage? page,
  ) {
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
              child: Row(
                children: [
                  Expanded(flex: 4, child: _ColHeader('MEMBER')),
                  Expanded(flex: 2, child: _ColHeader('SESSION')),
                  Expanded(flex: 2, child: _ColHeader('CHECK-IN')),
                  Expanded(
                    flex: 2,
                    child: _ColHeader(
                      'STATUS / ACTION',
                      align: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          if (loading && records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: Text('No records for this selection')),
            )
          else
            ...records.map(
              (record) => _AttendanceRow(
                record: record,
                isDesktop: isDesktop,
                onToggle: (present) => _markAttendance(record.memberId, present),
              ),
            ),
          if (page != null && page.pages > 1)
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PAGE ${page.page} OF ${page.pages}',
                    style: GoogleFonts.roboto(
                      fontSize: 9,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentPage > 1
                            ? () => _setPage(_currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: _currentPage < page.pages
                            ? () => _setPage(_currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
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
}

class _AttendanceRow extends StatelessWidget {
  final ApiAttendanceRecord record;
  final bool isDesktop;
  final ValueChanged<bool> onToggle;

  const _AttendanceRow({
    required this.record,
    required this.isDesktop,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = record.status == AttendanceStatus.present;

    if (!isDesktop) {
      return ListTile(
        leading: AvatarPlaceholder(
          initials: record.memberInitials,
          size: 40,
          paymentStatus: record.paymentStatus,
        ),
        title: Text(
          record.memberName.toUpperCase(),
          style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          record.session ?? 'No session',
          style: GoogleFonts.roboto(fontSize: 10),
        ),
        trailing: Switch(
          value: isPresent,
          onChanged: onToggle,
          activeColor: AppColors.primaryContainer,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0D484847))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                AvatarPlaceholder(
                  initials: record.memberInitials,
                  size: 40,
                  paymentStatus: record.paymentStatus,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.memberName.toUpperCase(),
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      record.email ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.session?.toUpperCase() ?? '-',
              style: GoogleFonts.roboto(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.checkinTime != null
                  ? DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(record.checkinTime!).toLocal())
                  : '-',
              style: GoogleFonts.roboto(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => onToggle(!isPresent),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPresent
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerHighest,
                  foregroundColor: isPresent
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresent
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 12,
                      color: isPresent ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPresent ? 'PRESENT' : 'MARK PRESENT',
                      style: GoogleFonts.roboto(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCell {
  final DateTime date;
  final bool inMonth;
  final MemberAttendanceCalendarDay? record;

  const _CalendarCell({
    required this.date,
    required this.inMonth,
    this.record,
  });
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isActive
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerHighest,
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isActive
                ? AppColors.onPrimaryContainer
                : AppColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _MemberSearchDialog extends StatefulWidget {
  final List<ApiMember> members;
  final String? selectedMemberId;

  const _MemberSearchDialog({
    required this.members,
    this.selectedMemberId,
  });

  @override
  State<_MemberSearchDialog> createState() => _MemberSearchDialogState();
}

class _MemberSearchDialogState extends State<_MemberSearchDialog> {
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
                          leading: AvatarPlaceholder(
                            initials: member.initials,
                            size: 38,
                            paymentStatus: member.paymentStatus,
                          ),
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

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        color: AppColors.surfaceContainerHighest,
        child: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;

  const _Legend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.roboto(
            fontSize: 9,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
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
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _ColHeader(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: GoogleFonts.roboto(
      fontSize: 9,
      fontWeight: FontWeight.w900,
      color: AppColors.onSurfaceVariant,
      letterSpacing: 2.5,
    ),
  );
}
