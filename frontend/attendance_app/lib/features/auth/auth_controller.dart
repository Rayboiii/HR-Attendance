import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState(this.status, [this.user]);

  final AuthStatus status;
  final AppUser? user;

  bool get isManager => user?.isManager ?? false;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Kick off the silent token check; state starts as `unknown` (splash).
    Future.microtask(_bootstrap);
    return const AuthState(AuthStatus.unknown);
  }

  Future<void> _bootstrap() async {
    final token = await ref.read(tokenStorageProvider).accessToken;
    if (token == null || token.isEmpty) {
      state = const AuthState(AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(AuthStatus.authenticated, user);
    } catch (_) {
      await ref.read(tokenStorageProvider).clear();
      state = const AuthState(AuthStatus.unauthenticated);
    }
  }

  /// Throws on failure (e.g. bad credentials) so the UI can show the message.
  Future<void> login(String email, String password) async {
    final res = await ref.read(authRepositoryProvider).login(email, password);
    await ref.read(tokenStorageProvider).saveTokens(
          accessToken: res.accessToken,
          refreshToken: res.refreshToken,
        );
    state = AuthState(AuthStatus.authenticated, res.user);
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Best-effort; we clear local state regardless.
    }
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }

  void onSessionExpired() => state = const AuthState(AuthStatus.unauthenticated);
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
