import '../services/api_service.dart';
import '../models/member_model.dart';

class ApiMember {
  final String id;
  final String name;
  final String initials;
  final String email;
  final String? phone;
  final String tier;
  final String tierLabel;
  final String memberSince;
  final PaymentStatus paymentStatus;
  final String? nextPaymentDate;
  final double monthlyFee;
  final bool isAtRisk;
  final bool isActive;

  const ApiMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.email,
    this.phone,
    required this.tier,
    required this.tierLabel,
    required this.memberSince,
    required this.paymentStatus,
    this.nextPaymentDate,
    required this.monthlyFee,
    this.isAtRisk = false,
    this.isActive = true,
  });

  factory ApiMember.fromJson(Map<String, dynamic> j) {
    PaymentStatus parsePayment(String? s) {
      switch (s) {
        case 'paid':
          return PaymentStatus.paid;
        case 'overdue':
          return PaymentStatus.overdue;
        default:
          return PaymentStatus.pending;
      }
    }

    String extractTierId(dynamic t) {
      if (t is Map) return t['_id'] ?? '';
      return t?.toString() ?? '';
    }

    return ApiMember(
      id: j['_id'] ?? j['id'] ?? '',
      name: j['name'] ?? '',
      initials: j['initials'] ?? '',
      email: j['email'] ?? '',
      phone: j['phone'],
      tier: extractTierId(j['tier']),
      tierLabel:
          j['tierLabel'] ??
          (j['tier'] is Map ? j['tier']['name'] : j['tier'] ?? '')
              .toString()
              .toUpperCase(),
      memberSince: j['memberSince'] != null
          ? _formatDate(j['memberSince'])
          : 'Unknown',
      paymentStatus: parsePayment(j['paymentStatus']),
      nextPaymentDate: j['nextPaymentDate'] != null
          ? _formatDate(j['nextPaymentDate'])
          : null,
      monthlyFee: (j['monthlyFee'] ?? 0).toDouble(),
      isAtRisk: j['isAtRisk'] ?? false,
      isActive: j['isActive'] ?? true,
    );
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class MembersPage {
  final List<ApiMember> members;
  final int total;
  final int page;
  final int pages;
  const MembersPage({
    required this.members,
    required this.total,
    required this.page,
    required this.pages,
  });
}

class MemberRepository {
  static Future<MembersPage> getMembers({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (status != null) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final data = await ApiService.get('/members', query: query);
    final list = (data['members'] as List)
        .map((e) => ApiMember.fromJson(e))
        .toList();
    return MembersPage(
      members: list,
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      pages: data['pages'] ?? 1,
    );
  }

  static Future<ApiMember> createMember(Map<String, dynamic> body) async {
    final data = await ApiService.post('/members', body);
    return ApiMember.fromJson(data);
  }

  static Future<ApiMember> updateMember(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiService.patch('/members/$id', body);
    return ApiMember.fromJson(data);
  }

  static Future<void> deleteMember(String id) async {
    await ApiService.delete('/members/$id');
  }
}
