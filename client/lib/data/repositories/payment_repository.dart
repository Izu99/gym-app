import '../services/api_service.dart';
import '../models/member_model.dart';

class ApiPayment {
  final String id;
  final String memberId;
  final String memberName;
  final String initials;
  final String? memberPhone;
  final String? memberEmail;
  final String invoiceNumber;
  final String plan;
  final double amount;
  final double paidAmount;
  final double balanceAmount;
  final String paymentMethod;
  final String? receivedBy;
  final String? billingPeriodStart;
  final String? billingPeriodEnd;
  final String dueDate;
  final PaymentStatus status;

  ApiPayment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.initials,
    this.memberPhone,
    this.memberEmail,
    required this.invoiceNumber,
    required this.plan,
    required this.amount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentMethod,
    this.receivedBy,
    this.billingPeriodStart,
    this.billingPeriodEnd,
    required this.dueDate,
    required this.status,
  });

  factory ApiPayment.fromJson(Map<String, dynamic> json) {
    final member = json['member'] ?? {};
    final tier = member['tier'];
    String plan = 'GENERAL';
    if (json['plan'] != null) {
      plan = json['plan'].toString().toUpperCase();
    } else if (tier is Map) {
      plan = (tier['name'] ?? 'GENERAL').toString().toUpperCase();
    } else if (member['tierLabel'] != null) {
      plan = member['tierLabel'].toString().toUpperCase();
    }

    return ApiPayment(
      id: json['_id'],
      memberId: member['_id'] ?? '',
      memberName: (json['memberName'] ?? member['name'] ?? 'DELETED MEMBER')
          .toString()
          .toUpperCase(),
      initials: member['initials'] ?? '??',
      memberPhone: member['phone']?.toString(),
      memberEmail: member['email']?.toString(),
      invoiceNumber: (json['invoiceNumber'] ?? 'DRAFT').toString(),
      plan: plan,
      amount: json['amount'].toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceAmount: (json['balanceAmount'] ?? json['amount'] ?? 0).toDouble(),
      paymentMethod: (json['paymentMethod'] ?? 'manual').toString(),
      receivedBy: json['receivedBy']?.toString(),
      billingPeriodStart: json['billingPeriodStart'] != null
          ? _formatDate(json['billingPeriodStart'])
          : null,
      billingPeriodEnd: json['billingPeriodEnd'] != null
          ? _formatDate(json['billingPeriodEnd'])
          : null,
      dueDate: _formatDate(json['dueDate']),
      status: _parseStatus(json['status']),
    );
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final months = [
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
      return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static PaymentStatus _parseStatus(String s) {
    if (s == 'paid') return PaymentStatus.paid;
    if (s == 'overdue') return PaymentStatus.overdue;
    if (s == 'partial') return PaymentStatus.partial;
    if (s == 'cancelled') return PaymentStatus.cancelled;
    return PaymentStatus.pending;
  }
}

class PaymentsPage {
  final List<ApiPayment> payments;
  final int total;
  final int page;
  final int pages;

  PaymentsPage({
    required this.payments,
    required this.total,
    required this.page,
    required this.pages,
  });
}

class PaymentSummary {
  final double totalRevenue;
  final double pendingRevenue;
  final int overdueCount;

  PaymentSummary({
    required this.totalRevenue,
    required this.pendingRevenue,
    required this.overdueCount,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      pendingRevenue: (json['pendingRevenue'] ?? 0).toDouble(),
      overdueCount: json['overdueCount'] ?? 0,
    );
  }
}

class PaymentRepository {
  static Future<PaymentsPage> getPayments({
    String? status,
    int page = 1,
  }) async {
    final query = <String, String>{'page': '$page', 'limit': '20'};
    if (status != null) query['status'] = status;

    final data = await ApiService.get('/payments', query: query);
    final list = data['payments'] as List;
    return PaymentsPage(
      payments: list.map((e) => ApiPayment.fromJson(e)).toList(),
      total: data['total'],
      page: data['page'],
      pages: data['pages'],
    );
  }

  static Future<PaymentSummary> getSummary() async {
    final data = await ApiService.get('/payments/summary');
    return PaymentSummary.fromJson(data);
  }

  static Future<void> markPaid(String id) async {
    await ApiService.patch('/payments/$id/mark-paid');
  }

  static Future<void> unmarkPaid(String id) async {
    await ApiService.patch('/payments/$id/unmark-paid');
  }

  static Future<ApiPayment> createPayment(Map<String, dynamic> data) async {
    final response = await ApiService.post('/payments', data);
    return ApiPayment.fromJson(response);
  }
}
