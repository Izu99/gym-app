import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/member_model.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../core/services/data_sync_controller.dart';
import '../../../data/repositories/tier_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  late Future<DashboardStats> _statsFuture;
  late Future<List<TierBreakdown>> _tierFuture;
  late Future<List<Tier>> _tiersListFuture;
  late Future<List<DailyRevenue>> _revenueFuture;
  late Future<List<AttendanceStat>> _attendanceFuture;
  late Future<List<ApiAttendanceRecord>> _checkinsFuture;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _loadAll();
    dataSync.addListener(_onDataSync);
  }

  void _onDataSync() {
    if (mounted) _refresh();
  }

  void _loadAll() {
    _statsFuture = DashboardRepository.getStats();
    _tierFuture = DashboardRepository.getTierBreakdown();
    _tiersListFuture = TierRepository.getTiers();
    _revenueFuture = DashboardRepository.getWeeklyRevenue();
    _attendanceFuture = DashboardRepository.getAttendanceStats();
    _checkinsFuture = AttendanceRepository.getTodayAttendance();
  }

  void _refresh() => setState(() => _loadAll());

  @override
  void dispose() {
    dataSync.removeListener(_onDataSync);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;
    return FadeTransition(
      opacity: _fade,
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: AppColors.primaryContainer,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isDesktop ? 40 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDesktop) ...[
                const SizedBox(height: 8),
                _buildHeader(isDesktop),
                const SizedBox(height: 40),
              ],
              _buildMetricsGrid(isDesktop),
              const SizedBox(height: 32),
              _buildChartsRow(isDesktop),
              const SizedBox(height: 32),
              _buildMembershipBreakdown(isDesktop),
              const SizedBox(height: 32),
              _buildBottomSection(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
      builder: (context, snap) {
        final facilityStatus = snap.hasData
            ? (snap.data!.dailyAttendance > 100 ? 'PEAK FLOW' : 'NORMAL')
            : '—';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'COMMAND ',
                          style: GoogleFonts.roboto(
                            fontSize: isDesktop ? 64 : 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -2,
                            height: 0.95,
                          ),
                        ),
                        TextSpan(
                          text: 'CENTER',
                          style: GoogleFonts.roboto(
                            fontSize: isDesktop ? 64 : 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textSecondary,
                            letterSpacing: -2,
                            height: 0.95,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'REAL-TIME FACILITY OUTPUT & TELEMETRY',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primaryContainer,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FACILITY STATUS',
                      style: GoogleFonts.roboto(
                        fontSize: 8,
                        color: AppColors.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      facilityStatus,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMetricsGrid(bool isDesktop) {
    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
      builder: (context, snap) {
        final stats = snap.data;
        final loading = !snap.hasData;
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _AttendanceCard(
                  count: stats?.dailyAttendance,
                  delta: stats?.attendanceDelta,
                  loading: loading,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _RevenueCard(
                  revenue: stats?.monthlyRevenue,
                  loading: loading,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _ActiveMembersCard(
                  active: stats?.activeMembers,
                  newThisMonth: stats?.newThisMonth,
                  loading: loading,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            _AttendanceCard(
              count: stats?.dailyAttendance,
              delta: stats?.attendanceDelta,
              loading: loading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _RevenueCard(
                    revenue: stats?.monthlyRevenue,
                    loading: loading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActiveMembersCard(
                    active: stats?.activeMembers,
                    newThisMonth: stats?.newThisMonth,
                    loading: loading,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsRow(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _WeeklyRevenueChart(future: _revenueFuture)),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: _AttendanceLineChart(future: _attendanceFuture),
          ),
        ],
      );
    }
    return Column(
      children: [
        _WeeklyRevenueChart(future: _revenueFuture),
        const SizedBox(height: 16),
        _AttendanceLineChart(future: _attendanceFuture),
      ],
    );
  }

  Widget _buildMembershipBreakdown(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _MemberTierTable(
              breakdownFuture: _tierFuture,
              tiersFuture: _tiersListFuture,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(child: _TierPieChart(future: _tierFuture)),
        ],
      );
    }
    return Column(
      children: [
        _TierPieChart(future: _tierFuture),
        const SizedBox(height: 16),
        _MemberTierTable(
          breakdownFuture: _tierFuture,
          tiersFuture: _tiersListFuture,
        ),
      ],
    );
  }

  Widget _buildBottomSection(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _LiveCheckinsSection(future: _checkinsFuture),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: FutureBuilder<DashboardStats>(
              future: _statsFuture,
              builder: (context, snap) => _UrgentTasksSection(stats: snap.data),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _LiveCheckinsSection(future: _checkinsFuture),
        const SizedBox(height: 32),
        FutureBuilder<DashboardStats>(
          future: _statsFuture,
          builder: (context, snap) => _UrgentTasksSection(stats: snap.data),
        ),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _shimmer(double w, double h) => Container(
  width: w,
  height: h,
  decoration: BoxDecoration(
    color: AppColors.surfaceLighterHighest,
    borderRadius: BorderRadius.circular(2),
  ),
);

String _fmtCurrency(double v) {
  if (v >= 1000) {
    return 'Rs.${(v / 1000).toStringAsFixed(1)}K';
  }
  return 'Rs.${v.toStringAsFixed(0)}';
}
// ── Metric Cards ──────────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final int? count;
  final double? delta;
  final bool loading;
  const _AttendanceCard({this.count, this.delta, required this.loading});

  @override
  Widget build(BuildContext context) {
    final deltaStr = delta == null
        ? ''
        : delta! >= 0
        ? '+${delta!.toStringAsFixed(1)}% vs yest.'
        : '${delta!.toStringAsFixed(1)}% vs yest.';
    final deltaColor = (delta ?? 0) >= 0
        ? AppColors.primaryContainer
        : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(32),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY ATTENDANCE',
            style: GoogleFonts.roboto(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          loading
              ? _shimmer(120, 56)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${count ?? 0}',
                      style: GoogleFonts.roboto(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (deltaStr.isNotEmpty)
                      Text(
                        deltaStr,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: deltaColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
          const SizedBox(height: 24),
          // Mini bar — just a visual indicator using count
          SizedBox(
            height: 48,
            child: loading
                ? _shimmer(double.infinity, 48)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final isToday = i == 6;
                      final frac = isToday
                          ? 1.0
                          : 0.3 + (i * 0.1).clamp(0.0, 0.9);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            height: 48 * frac,
                            child: ColoredBox(
                              color: isToday
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceLighter,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double? revenue;
  final bool loading;
  const _RevenueCard({this.revenue, required this.loading});

  @override
  Widget build(BuildContext context) {
    final projected = revenue != null ? revenue! * 1.05 : null;
    final progress = revenue != null && projected != null
        ? revenue! / projected
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLighter,
        border: Border(top: BorderSide(color: AppColors.secondary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY REVENUE',
            style: GoogleFonts.roboto(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          loading
              ? _shimmer(100, 36)
              : Text(
                  revenue != null ? _fmtCurrency(revenue!) : '—',
                  style: GoogleFonts.roboto(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
          loading
              ? const SizedBox(height: 4)
              : Text(
                  projected != null
                      ? 'Projected: ${_fmtCurrency(projected)}'
                      : '',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceLighterHighest,
            valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}

class _ActiveMembersCard extends StatelessWidget {
  final int? active;
  final int? newThisMonth;
  final bool loading;
  const _ActiveMembersCard({
    this.active,
    this.newThisMonth,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLighter,
        border: Border(
          top: BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE MEMBERS',
            style: GoogleFonts.roboto(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          loading
              ? _shimmer(80, 36)
              : Text(
                  '${active ?? 0}',
                  style: GoogleFonts.roboto(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
          loading
              ? const SizedBox(height: 4)
              : Text(
                  newThisMonth != null ? '+$newThisMonth new this month' : '',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(
              4,
              (i) => Container(
                width: 28,
                height: 28,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLighterHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  i < 3 ? ['A', 'B', 'C'][i] : '+',
                  style: GoogleFonts.roboto(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Charts ────────────────────────────────────────────────────────────────────

class _WeeklyRevenueChart extends StatelessWidget {
  final Future<List<DailyRevenue>> future;
  const _WeeklyRevenueChart({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DailyRevenue>>(
      future: future,
      builder: (context, snap) {
        final data = snap.data ?? [];
        final total = data.fold(0.0, (s, d) => s + d.revenue);
        final maxY = data.isEmpty
            ? 10000.0
            : (data.map((d) => d.revenue).reduce((a, b) => a > b ? a : b) *
                  1.2);

        return Container(
          padding: const EdgeInsets.all(28),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WEEKLY REVENUE',
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      snap.connectionState == ConnectionState.waiting
                          ? _shimmer(100, 28)
                          : Text(
                              _fmtCurrency(total),
                              style: GoogleFonts.roboto(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                    ],
                  ),
                  if (data.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      color: AppColors.primaryContainer.withOpacity(0.15),
                      child: Text(
                        '${data.length} DAYS',
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 160,
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryContainer,
                          strokeWidth: 2,
                        ),
                      )
                    : data.isEmpty
                    ? Center(
                        child: Text(
                          'No revenue data',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) =>
                                  AppColors.surfaceLighterHighest,
                              getTooltipItem: (group, gi, rod, _) =>
                                  BarTooltipItem(
                                    '${data[gi].date}\n${_fmtCurrency(rod.toY)}',
                                    GoogleFonts.roboto(
                                      fontSize: 10,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= data.length)
                                    return const SizedBox();
                                  // Show last 3 chars of date (day number)
                                  final label = data[i].date.length >= 2
                                      ? data[i].date.substring(
                                          data[i].date.length - 2,
                                        )
                                      : data[i].date;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      label,
                                      style: GoogleFonts.roboto(
                                        fontSize: 8,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: AppColors.outlineVariant.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: data.asMap().entries.map((e) {
                            final isMax =
                                e.value.revenue ==
                                data
                                    .map((d) => d.revenue)
                                    .reduce((a, b) => a > b ? a : b);
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.revenue,
                                  color: isMax
                                      ? AppColors.primaryContainer
                                      : AppColors.surfaceLighterHighest,
                                  width: 20,
                                  borderRadius: BorderRadius.zero,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceLineChart extends StatelessWidget {
  final Future<List<AttendanceStat>> future;
  const _AttendanceLineChart({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceStat>>(
      future: future,
      builder: (context, snap) {
        final data = snap.data ?? [];
        final spots = data
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
            .toList();
        final maxY = data.isEmpty
            ? 160.0
            : (data
                      .map((d) => d.count.toDouble())
                      .reduce((a, b) => a > b ? a : b) *
                  1.2);
        final minY = data.isEmpty
            ? 0.0
            : (data
                      .map((d) => d.count.toDouble())
                      .reduce((a, b) => a < b ? a : b) *
                  0.8);

        return Container(
          padding: const EdgeInsets.all(28),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ATTENDANCE TREND',
                style: GoogleFonts.roboto(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '7-DAY ROLLING',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 160,
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryContainer,
                          strokeWidth: 2,
                        ),
                      )
                    : spots.isEmpty
                    ? Center(
                        child: Text(
                          'No attendance data',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          minY: minY,
                          maxY: maxY,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) =>
                                  AppColors.surfaceLighterHighest,
                              getTooltipItems: (spots) => spots
                                  .map(
                                    (s) => LineTooltipItem(
                                      '${s.y.toInt()} members',
                                      GoogleFonts.roboto(
                                        fontSize: 10,
                                        color: AppColors.primaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: AppColors.outlineVariant.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: AppColors.primaryContainer,
                              barWidth: 2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, __, ___, ____) =>
                                    FlDotCirclePainter(
                                      radius: 3,
                                      color: AppColors.primaryContainer,
                                      strokeWidth: 0,
                                    ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primaryContainer.withOpacity(
                                  0.06,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tier breakdown ────────────────────────────────────────────────────────────

class _TierPieChart extends StatefulWidget {
  final Future<List<TierBreakdown>> future;
  const _TierPieChart({required this.future});
  @override
  State<_TierPieChart> createState() => _TierPieChartState();
}

class _TierPieChartState extends State<_TierPieChart> {
  int _touchedIndex = -1;

  final _colors = [
    AppColors.primaryContainer,
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.tertiaryContainer,
    AppColors.surfaceLighterHighest,
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TierBreakdown>>(
      future: widget.future,
      builder: (context, snap) {
        final data = snap.data ?? [];
        final total = data.fold(0, (s, d) => s + d.count);

        return Container(
          padding: const EdgeInsets.all(28),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIER DISTRIBUTION',
                style: GoogleFonts.roboto(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryContainer,
                          strokeWidth: 2,
                        ),
                      )
                    : data.isEmpty
                    ? Center(
                        child: Text(
                          'No data',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response?.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = response!
                                    .touchedSection!
                                    .touchedSectionIndex;
                              });
                            },
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: data.asMap().entries.map((e) {
                            final isTouched = e.key == _touchedIndex;
                            final pct = total > 0
                                ? (e.value.count / total * 100)
                                : 0.0;
                            final color = _colors[e.key % _colors.length];
                            return PieChartSectionData(
                              color: color,
                              value: e.value.count.toDouble(),
                              title: '${pct.toStringAsFixed(0)}%',
                              radius: isTouched ? 60 : 50,
                              titleStyle: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.surface,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              ...data.asMap().entries.map((e) {
                final t = e.value;
                final i = e.key;
                final pct = total > 0 ? (t.count / total * 100) : 0.0;
                final color = _colors[i % _colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.tier.toUpperCase(),
                          style: GoogleFonts.roboto(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Text(
                        '${t.count} (${pct.toStringAsFixed(0)}%)',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _MemberTierTable extends StatelessWidget {
  final Future<List<TierBreakdown>> breakdownFuture;
  final Future<List<Tier>> tiersFuture;
  const _MemberTierTable({
    required this.breakdownFuture,
    required this.tiersFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([breakdownFuture, tiersFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snap) {
        final breakdown = (snap.data?[0] as List<TierBreakdown>?) ?? [];
        final tiers = (snap.data?[1] as List<Tier>?) ?? [];

        return Container(
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                child: Text(
                  'MEMBERSHIP BREAKDOWN',
                  style: GoogleFonts.roboto(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                color: AppColors.surfaceLighterHighest.withOpacity(0.4),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _TH('TIER')),
                    Expanded(flex: 2, child: _TH('MEMBERS')),
                    Expanded(flex: 2, child: _TH('MO. REVENUE')),
                    Expanded(flex: 2, child: _TH('SHARE')),
                  ],
                ),
              ),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryContainer,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (breakdown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No member data',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else ...[
                ...() {
                  final total = breakdown.fold(0, (s, d) => s + d.count);
                  return breakdown.map((r) {
                    final label = r.tier.toUpperCase();
                    final tierInfo = tiers.firstWhere(
                      (t) => t.id == r.tierId || t.name == r.tier,
                      orElse: () =>
                          Tier(id: r.tierId, name: r.tier, monthlyFee: 0),
                    );

                    final revenue = r.count * tierInfo.monthlyFee;
                    final pct = total > 0 ? (r.count / total * 100) : 0.0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0x0D484847)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              label,
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${r.count}',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _fmtCurrency(revenue.toDouble()),
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                }(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.roboto(
      fontSize: 8,
      fontWeight: FontWeight.w900,
      color: AppColors.textSecondary,
      letterSpacing: 2,
    ),
  );
}

// ── Live Check-ins & Urgent Tasks ─────────────────────────────────────────────

class _LiveCheckinsSection extends StatelessWidget {
  final Future<List<ApiAttendanceRecord>> future;
  const _LiveCheckinsSection({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ApiAttendanceRecord>>(
      future: future,
      builder: (context, snap) {
        final records = snap.data ?? [];
        final present = records
            .where((r) => r.status == AttendanceStatus.present)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LIVE CHECK-INS',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  children: [
                    if (snap.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryContainer,
                          strokeWidth: 2,
                        ),
                      ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'VIEW ALL',
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: AppColors.primaryContainer,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Color(0x1A484847)),
            const SizedBox(height: 8),
            if (present.isEmpty &&
                snap.connectionState != ConnectionState.waiting)
              Container(
                padding: const EdgeInsets.all(24),
                color: AppColors.surface,
                child: Text(
                  'No check-ins yet today',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...present.take(5).toList().asMap().entries.map((e) {
                final r = e.value;
                final isFirst = e.key == 0;
                return _CheckinItem(
                  name: r.memberName,
                  tier: r.tierLabel,
                  time: r.checkinTime != null
                      ? _formatTime(r.checkinTime!)
                      : 'TODAY',
                  isLive: isFirst,
                  bgColor: e.key % 2 == 0
                      ? AppColors.surface
                      : AppColors.surfaceLighter,
                );
              }),
          ],
        );
      },
    );
  }

  static String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      final ampm = d.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return 'TODAY';
    }
  }
}

class _CheckinItem extends StatelessWidget {
  final String name, tier, time;
  final bool isLive;
  final Color bgColor;
  const _CheckinItem({
    required this.name,
    required this.tier,
    required this.time,
    required this.isLive,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: bgColor,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceLighterHighest,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'TIER: $tier',
                  style: GoogleFonts.roboto(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isLive) _PulseDot(),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 4),
      decoration: const BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _UrgentTasksSection extends StatelessWidget {
  final DashboardStats? stats;
  const _UrgentTasksSection({this.stats});

  @override
  Widget build(BuildContext context) {
    final overdueCount = stats?.overduePayments ?? 0;
    final overdueMembers = stats?.overdueMembers ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'URGENT TASKS',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const Divider(color: Color(0x1A484847)),
        const SizedBox(height: 12),
        if (overdueCount > 0)
          _UrgentItem(
            color: AppColors.secondary,
            tag: 'PAYMENT FAILURE',
            title:
                '$overdueCount OVERDUE PAYMENT${overdueCount != 1 ? 'S' : ''}',
          ),
        if (overdueCount > 0) const SizedBox(height: 8),
        if (overdueMembers > 0)
          _UrgentItem(
            color: AppColors.tertiary,
            tag: 'MEMBERS AT RISK',
            title:
                '$overdueMembers MEMBER${overdueMembers != 1 ? 'S' : ''} OVERDUE',
          ),
        if (overdueCount == 0 && overdueMembers == 0)
          _UrgentItem(
            color: AppColors.primaryContainer,
            tag: 'ALL CLEAR',
            title: 'NO URGENT TASKS',
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.surfaceLighterHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ELITE MEMBERSHIP GOAL',
                style: GoogleFonts.roboto(
                  fontSize: 9,
                  color: AppColors.primaryContainer,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                stats == null
                    ? 'Loading...'
                    : 'You have ${stats!.activeMembers} active members. '
                          'Analyze membership trends to reach your Q3 target.',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryContainer),
                    foregroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'LAUNCH CAMPAIGN',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UrgentItem extends StatelessWidget {
  final Color color;
  final String tag, title;
  const _UrgentItem({
    required this.color,
    required this.tag,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLighter,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: GoogleFonts.roboto(
              fontSize: 9,
              color: color,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
