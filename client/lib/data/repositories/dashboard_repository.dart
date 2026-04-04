import '../services/api_service.dart';

class DashboardStats {
  final int totalMembers;
  final int activeMembers;
  final int overdueMembers;
  final int newThisMonth;
  final int dailyAttendance;
  final double attendanceDelta;
  final double monthlyRevenue;
  final int overduePayments;

  const DashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.overdueMembers,
    required this.newThisMonth,
    required this.dailyAttendance,
    required this.attendanceDelta,
    required this.monthlyRevenue,
    required this.overduePayments,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalMembers: j['totalMembers'] ?? 0,
    activeMembers: j['activeMembers'] ?? 0,
    overdueMembers: j['overdueMembers'] ?? 0,
    newThisMonth: j['newThisMonth'] ?? 0,
    dailyAttendance: j['dailyAttendance'] ?? 0,
    attendanceDelta: (j['attendanceDelta'] ?? 0).toDouble(),
    monthlyRevenue: (j['monthlyRevenue'] ?? 0).toDouble(),
    overduePayments: j['overduePayments'] ?? 0,
  );
}

class TierBreakdown {
  final String tierId;
  final String tier;
  final int count;
  const TierBreakdown({required this.tierId, required this.tier, required this.count});
  factory TierBreakdown.fromJson(Map<String, dynamic> j) =>
      TierBreakdown(
        tierId: j['_id'] ?? '',
        tier: j['tier'] ?? 'Unknown',
        count: j['count'] ?? 0,
      );
}

class DailyRevenue {
  final String date;
  final double revenue;
  const DailyRevenue({required this.date, required this.revenue});
  factory DailyRevenue.fromJson(Map<String, dynamic> j) =>
      DailyRevenue(date: j['_id'] ?? '', revenue: (j['revenue'] ?? 0).toDouble());
}

class AttendanceStat {
  final String date;
  final int count;
  const AttendanceStat({required this.date, required this.count});
  factory AttendanceStat.fromJson(Map<String, dynamic> j) =>
      AttendanceStat(date: j['_id'] ?? '', count: j['count'] ?? 0);
}

class DashboardRepository {
  static Future<DashboardStats> getStats() async {
    final data = await ApiService.get('/dashboard/stats');
    return DashboardStats.fromJson(data);
  }

  static Future<List<TierBreakdown>> getTierBreakdown() async {
    final data = await ApiService.get('/dashboard/tier-breakdown') as List;
    return data.map((e) => TierBreakdown.fromJson(e)).toList();
  }

  static Future<List<DailyRevenue>> getWeeklyRevenue() async {
    final data = await ApiService.get('/payments/weekly') as List;
    return data.map((e) => DailyRevenue.fromJson(e)).toList();
  }

  static Future<List<AttendanceStat>> getAttendanceStats({int days = 7}) async {
    final data = await ApiService.get('/attendance/stats',
        query: {'days': '$days'}) as List;
    return data.map((e) => AttendanceStat.fromJson(e)).toList();
  }
}
