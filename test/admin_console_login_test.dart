import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seicho_app/core/api/api_client.dart';
import 'package:seicho_app/core/auth/auth_repository.dart';
import 'package:seicho_app/core/auth/session.dart';
import 'package:seicho_app/core/config/admin_console.dart';

class _MemoryStore extends SessionStore {
  UserSession? session;

  @override
  Future<UserSession?> read() async => session;
  @override
  Future<String?> readToken() async => session?.token;
  @override
  Future<void> write(UserSession s) async => session = s;
  @override
  Future<void> clear() async => session = null;
}

ProviderContainer _container({required bool console, required String role, required _MemoryStore store}) {
  final client = MockClient((_) async => http.Response(
        jsonEncode({
          'statusCode': 200,
          'data': {'id': 'u1', 'email': 'a@b.co', 'fullName': 'A', 'role': role, 'authToken': 'tok'},
        }),
        200,
      ));
  final c = ProviderContainer(overrides: [
    adminConsoleProvider.overrideWithValue(console),
    sessionStoreProvider.overrideWithValue(store),
    apiClientProvider.overrideWithValue(ApiClient(sessionStore: store, client: client, baseUrl: 'http://test')),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('web console rejects a non super admin and stores nothing', () async {
    final store = _MemoryStore();
    final c = _container(console: true, role: 'ORG-ADMIN', store: store);
    await c.read(sessionProvider.future);

    await expectLater(
      c.read(authRepositoryProvider).login(email: 'a@b.co', password: 'x'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
    expect(store.session, isNull);
    expect(c.read(currentUserProvider), isNull);
  });

  test('web console accepts a super admin', () async {
    final store = _MemoryStore();
    final c = _container(console: true, role: 'SUPER-ADMIN', store: store);
    await c.read(sessionProvider.future);

    final s = await c.read(authRepositoryProvider).login(email: 'a@b.co', password: 'x');
    expect(s.isSuperAdmin, isTrue);
    expect(store.session?.token, 'tok');
  });

  test('mobile app still accepts organisation roles', () async {
    final store = _MemoryStore();
    final c = _container(console: false, role: 'ORG-ADMIN', store: store);
    await c.read(sessionProvider.future);

    final s = await c.read(authRepositoryProvider).login(email: 'a@b.co', password: 'x');
    expect(s.isOrgAdmin, isTrue);
  });
}
