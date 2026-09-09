import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'session.dart';

/// Login, logout and password reset against the backend.
class AuthRepository {
  AuthRepository(this._api, this._session);

  final ApiClient _api;
  final SessionNotifier _session;

  /// `POST /users/login`. The JWT arrives in `data.authToken`.
  Future<UserSession> login({required String email, required String password}) async {
    final res = await _api.post('/users/login', body: {
      'email': email.trim().toLowerCase(),
      'password': password,
      'rememberMe': true,
    });
    final data = res.map;
    if (data.isEmpty || data['id'] == null) {
      throw const ApiException(500, 'Invalid response from server.');
    }
    final session = UserSession.fromLoginData(data);
    if (session.token.isEmpty) {
      throw const ApiException(500, 'Login succeeded but no token was returned.');
    }
    if (session.role.isEmpty || session.homeRoute == '/login') {
      throw ApiException(403, 'Your account role (${session.roleRaw}) is not supported by this app.');
    }
    await _session.setSession(session);
    return session;
  }

  /// `POST /auth/logout` (best effort) then clear local storage.
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // The token may already be invalid; local logout still proceeds.
    }
    await _session.clear();
  }

  /// `POST /auth/password-reset/otp` — emails a 6-digit code valid 10 minutes.
  Future<void> requestPasswordResetOtp(String email) async {
    await _api.post('/auth/password-reset/otp', body: {'email': email.trim().toLowerCase()});
  }

  /// `POST /auth/password-reset` — sets a new password using the emailed code.
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _api.post('/auth/password-reset', body: {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
      'password': newPassword,
    });
  }

  /// `PATCH /users/fcmToken` — registers a push token for the current user.
  Future<void> registerFcmToken({required String userId, required String fcmToken}) async {
    await _api.patch('/users/fcmToken', body: {'userId': userId, 'fcmToken': fcmToken});
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), ref.read(sessionProvider.notifier));
});
