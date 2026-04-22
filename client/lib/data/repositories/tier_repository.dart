import '../services/api_service.dart';

class Tier {
  final String id;
  final String name;
  final double monthlyFee;
  final String description;
  final String billingCycle;
  final double joiningFee;
  final String status;
  final bool isArchived;

  const Tier({
    required this.id,
    required this.name,
    required this.monthlyFee,
    this.description = '',
    this.billingCycle = 'monthly',
    this.joiningFee = 0,
    this.status = 'active',
    this.isArchived = false,
  });

  factory Tier.fromJson(Map<String, dynamic> json) {
    return Tier(
      id: json['_id'],
      name: json['name'],
      monthlyFee: json['monthlyFee'].toDouble(),
      description: (json['description'] ?? '').toString(),
      billingCycle: (json['billingCycle'] ?? 'monthly').toString(),
      joiningFee: (json['joiningFee'] ?? 0).toDouble(),
      status: (json['status'] ?? 'active').toString(),
      isArchived: json['isArchived'] == true,
    );
  }

  String get billingCycleLabel {
    switch (billingCycle) {
      case 'quarterly':
        return '3 MONTHS';
      case 'half_yearly':
        return '6 MONTHS';
      case 'yearly':
        return '12 MONTHS';
      default:
        return '1 MONTH';
    }
  }
}

class TierRepository {
  static List<Tier>? _cachedTiers;

  static void clearCache() {
    _cachedTiers = null;
  }

  static Future<List<Tier>> getTiers({
    bool forceRefresh = false,
    bool includeArchived = false,
  }) async {
    if (_cachedTiers != null && !forceRefresh) return _cachedTiers!;
    final data = await ApiService.get(
      '/tiers',
      query: includeArchived ? {'includeArchived': 'true'} : null,
    ) as List;
    _cachedTiers = data.map((e) => Tier.fromJson(e)).toList();
    return _cachedTiers!;
  }

  static Future<Tier> createTier(Map<String, dynamic> body) async {
    final data = await ApiService.post('/tiers', body);
    clearCache();
    return Tier.fromJson(data);
  }

  static Future<Tier> updateTier(String id, Map<String, dynamic> body) async {
    final data = await ApiService.patch('/tiers/$id', body);
    clearCache();
    return Tier.fromJson(data);
  }

  static Future<void> deleteTier(String id) async {
    await ApiService.delete('/tiers/$id');
    clearCache();
  }
}
