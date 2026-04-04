import '../services/api_service.dart';

class Tier {
  final String id;
  final String name;
  final double monthlyFee;

  Tier({required this.id, required this.name, required this.monthlyFee});

  factory Tier.fromJson(Map<String, dynamic> json) {
    return Tier(
      id: json['_id'],
      name: json['name'],
      monthlyFee: json['monthlyFee'].toDouble(),
    );
  }
}

class TierRepository {
  static List<Tier>? _cachedTiers;

  static Future<List<Tier>> getTiers({bool forceRefresh = false}) async {
    if (_cachedTiers != null && !forceRefresh) return _cachedTiers!;
    final data = await ApiService.get('/tiers') as List;
    _cachedTiers = data.map((e) => Tier.fromJson(e)).toList();
    return _cachedTiers!;
  }

  static Future<Tier> createTier(Map<String, dynamic> body) async {
    final data = await ApiService.post('/tiers', body);
    _cachedTiers = null; // Invalidate cache
    return Tier.fromJson(data);
  }

  static Future<Tier> updateTier(String id, Map<String, dynamic> body) async {
    final data = await ApiService.patch('/tiers/$id', body);
    _cachedTiers = null;
    return Tier.fromJson(data);
  }

  static Future<void> deleteTier(String id) async {
    await ApiService.delete('/tiers/$id');
    _cachedTiers = null;
  }
}
