import '../services/api_service.dart';
import '../models/member_model.dart';

class ApiAttendanceRecord {
  final String id;
  final String memberId;
  final String memberName;
  final String memberInitials;
  final String memberTier;
  final String tierLabel;
  final PaymentStatus paymentStatus;
  final String? email;
  final AttendanceStatus status;
  final String? checkinTime;
  final String? session;

  ApiAttendanceRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.memberInitials,
    required this.memberTier,
    required this.tierLabel,
    required this.paymentStatus,
    this.email,
    required this.status,
    this.checkinTime,
    this.session,
  });

  factory ApiAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final member = json['member'] ?? {};
    final t = member['tier'];
    String tierId = '';
    String tierLabel = 'STANDARD';

    if (t is Map) {
      tierId = t['_id'] ?? '';
      tierLabel = (t['name'] ?? 'STANDARD').toString().toUpperCase();
    } else {
      tierId = t?.toString() ?? '';
      tierLabel = member['tierLabel'] ?? tierId.toUpperCase();
    }
    if (tierLabel.isEmpty) tierLabel = 'STANDARD';

    return ApiAttendanceRecord(
      id: json['_id'] ?? '',
      memberId: member['_id'] ?? '',
      memberName: member['name'] ?? 'Unknown',
      memberInitials: member['initials'] ?? '??',
      memberTier: tierId,
      tierLabel: tierLabel,
      paymentStatus: _parsePaymentStatus(member['paymentStatus']),
      email: member['email'],
      status: json['status'] == 'present' ? AttendanceStatus.present : AttendanceStatus.absent,
      checkinTime: json['checkinTime'],
      session: json['session'],
    );
  }

  static PaymentStatus _parsePaymentStatus(String? s) {
    if (s == 'paid') return PaymentStatus.paid;
    if (s == 'overdue') return PaymentStatus.overdue;
    return PaymentStatus.pending;
  }
}

class AttendancePage {
  final List<ApiAttendanceRecord> records;
  final int total;
  final int page;
  final int pages;

  AttendancePage({required this.records, required this.total, required this.page, required this.pages});
}

class AttendanceRepository {
  static Future<AttendancePage> getAttendance({
    String? date,
    String? session,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (date != null) query['date'] = date;
    if (session != null) query['session'] = session;

    final data = await ApiService.get('/attendance', query: query);
    final list = data['records'] as List;
    return AttendancePage(
      records: list.map((e) => ApiAttendanceRecord.fromJson(e)).toList(),
      total: data['total'],
      page: data['page'],
      pages: data['pages'],
    );
  }

  static Future<List<ApiAttendanceRecord>> getTodayAttendance() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final page = await getAttendance(date: dateStr, limit: 100);
    return page.records;
  }

  static Future<ApiAttendanceRecord> markAttendance({
    required String memberId,
    required bool isPresent,
    String? date,
    String? session,
  }) async {
    final statusStr = isPresent ? 'present' : 'absent';
    final data = await ApiService.post('/attendance', {
      'memberId': memberId,
      'status': statusStr,
      if (date != null) 'date': date,
      if (session != null) 'session': session,
    });
    return ApiAttendanceRecord.fromJson(data);
  }
}
