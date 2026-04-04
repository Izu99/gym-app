enum PaymentStatus { paid, overdue, pending }
enum AttendanceStatus { present, absent, pending }

class Member {
  final String id;
  final String name;
  final String initials;
  final String email;
  final String? phone;
  final String tier;
  final String tierLabel;
  final String memberSince;
  final String lastAttendance;
  final String lastActivity;
  final PaymentStatus paymentStatus;
  final String nextPaymentDate;
  final double monthlyFee;
  final bool isLiveNow;
  final bool isAtRisk;
  AttendanceStatus attendanceStatus;

  Member({
    required this.id,
    required this.name,
    required this.initials,
    required this.email,
    this.phone,
    required this.tier,
    required this.tierLabel,
    required this.memberSince,
    required this.lastAttendance,
    required this.lastActivity,
    required this.paymentStatus,
    required this.nextPaymentDate,
    required this.monthlyFee,
    this.isLiveNow = false,
    this.isAtRisk = false,
    this.attendanceStatus = AttendanceStatus.pending,
  });

  String get planLabel => '${tierLabel.toUpperCase()} • Membership';
}
