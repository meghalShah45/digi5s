import 'dart:io';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session.dart';
import '../models/news.dart';

class NewsService {
  NewsService([ApiClient? api, SessionStore? store])
      : _store = store ?? SessionStore(),
        _api = api ?? ApiClient(sessionStore: store ?? SessionStore());

  final ApiClient _api;
  final SessionStore _store;

  /// News for the logged-in user's organisation (`GET /news/org/{orgId}`).
  /// A super admin without an organisation gets every item.
  Future<List<News>> getNews() async {
    final orgId = (await _store.read())?.orgId ?? '';
    final res = await _api.get(orgId.isEmpty ? '/news' : '/news/org/$orgId');
    final items = res.list.map(News.fromJson).toList();
    items.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    return items;
  }

  Future<List<News>> getNewsForOrg(String orgId) async {
    final res = await _api.get('/news/org/$orgId');
    return res.list.map(News.fromJson).toList();
  }

  /// `POST /news` (multipart). The backend requires a file.
  Future<List<News>> createNews({
    required String orgId,
    required String title,
    required String description,
    required File file,
  }) async {
    final res = await _api.multipart(
      'POST',
      '/news',
      fields: {'orgId': orgId, 'title': title.trim(), 'description': description.trim()},
      files: [ApiFile(field: 'file', path: file.path)],
    );
    return res.list.map(News.fromJson).toList();
  }

  Future<void> updateNews(String id, {String? title, String? description, String? modifiedBy}) async {
    await _api.put('/news/$id', body: {
      if (title != null) 'title': title.trim(),
      if (description != null) 'description': description.trim(),
      if (modifiedBy != null) 'modifiedBy': modifiedBy,
    });
  }

  Future<void> deleteNews(String newsId) => _api.delete('/news/$newsId');
}
