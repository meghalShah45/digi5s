import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session.dart';

/// Ticker-style announcement. Backend table `FlashNews`: content + expiryDate.
class FlashNews {
  final String id;
  final String orgId;
  final String content;
  final DateTime expiryDate;
  final DateTime? createdAt;
  final String? createdBy;

  const FlashNews({
    required this.id,
    required this.orgId,
    required this.content,
    required this.expiryDate,
    this.createdAt,
    this.createdBy,
  });

  bool get isActive => expiryDate.isAfter(DateTime.now());

  factory FlashNews.fromJson(Map<String, dynamic> j) => FlashNews(
        id: j['id'].toString(),
        orgId: (j['orgId'] ?? '').toString(),
        content: (j['content'] ?? '').toString(),
        expiryDate: DateTime.tryParse(j['expiryDate']?.toString() ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
        createdBy: j['createdBy']?.toString(),
      );
}

class FlashNewsService {
  FlashNewsService(this._api);
  final ApiClient _api;

  Future<List<FlashNews>> forOrg(String orgId) async {
    final res = await _api.get('/flash-news/org/$orgId');
    final items = res.list.map(FlashNews.fromJson).toList();
    items.sort((a, b) => (b.createdAt ?? b.expiryDate).compareTo(a.createdAt ?? a.expiryDate));
    return items;
  }

  Future<List<FlashNews>> activeForOrg(String orgId) async =>
      (await forOrg(orgId)).where((n) => n.isActive).toList();

  Future<FlashNews> create({required String orgId, required String content, required DateTime expiryDate}) async {
    final res = await _api.post('/flash-news', body: {
      'orgId': orgId,
      'content': content.trim(),
      'expiryDate': expiryDate.toUtc().toIso8601String(),
    });
    return FlashNews.fromJson(res.map);
  }

  Future<FlashNews> update(String id, {String? content, DateTime? expiryDate, String? modifiedBy}) async {
    final res = await _api.put('/flash-news/$id', body: {
      if (content != null) 'content': content.trim(),
      if (expiryDate != null) 'expiryDate': expiryDate.toUtc().toIso8601String(),
      if (modifiedBy != null) 'modifiedBy': modifiedBy,
    });
    return FlashNews.fromJson(res.map);
  }

  Future<void> delete(String id) => _api.delete('/flash-news/$id');
}

final flashNewsServiceProvider = Provider((ref) => FlashNewsService(ref.read(apiClientProvider)));

/// All flash news for the current user's organisation.
final orgFlashNewsProvider = FutureProvider.autoDispose<List<FlashNews>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final orgId = user?.orgId;
  if (orgId == null || orgId.isEmpty) return const [];
  return ref.read(flashNewsServiceProvider).forOrg(orgId);
});

/// Only the items that have not expired.
final activeFlashNewsProvider = Provider.autoDispose<AsyncValue<List<FlashNews>>>((ref) {
  return ref.watch(orgFlashNewsProvider).whenData((l) => l.where((n) => n.isActive).toList());
});
