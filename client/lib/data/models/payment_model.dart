import 'member_model.dart';

class Payment {
  final String id;
  final String memberName;
  final String initials;
  final String plan;
  final double amount;
  final String dueDate;
  final PaymentStatus status;

  const Payment({
    required this.id,
    required this.memberName,
    required this.initials,
    required this.plan,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}
