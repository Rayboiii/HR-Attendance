import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../config/app_config.dart';

/// Wraps a configured [Dio] instance that attaches the bearer token to every
/// request and transparently refreshes it on a 401 before retrying once.
class ApiClient {
  ApiClient({required this.storage, this.onSessionExpired}) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isAuthCall = error.requestOptions.path.contains('/auth/login') ||
            error.requestOptions.path.contains('/auth/refresh');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (error.response?.statusCode != 401 || isAuthCall || alreadyRetried) {
          return handler.next(error);
        }

        // Try to refresh (shared across concurrent 401s) then retry once.
        final refreshed = await _refreshTokens();
        if (!refreshed) {
          await _onAuthFailure();
          return handler.next(error);
        }

        try {
          final response = await _retry(error.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          await _onAuthFailure();
          return handler.next(e);
        } catch (_) {
          await _onAuthFailure();
          return handler.next(error);
        }
      },
    ));
  }

  final TokenStorage storage;
  final void Function()? onSessionExpired;
  late final Dio dio;

  /// In-flight refresh shared by all concurrent 401s, so the rotating refresh
  /// token is only spent once (otherwise the losing refresh clears good tokens).
  Future<bool>? _refreshing;

  Future<bool> _refreshTokens() =>
      _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _performRefresh() async {
    final refresh = await storage.refreshToken;
    if (refresh == null) return false;
    try {
      // Bare client so this call isn't itself intercepted/looped.
      final bare = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final res = await bare.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data!;
      await storage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) {
    options.extra['retried'] = true;
    // onRequest re-attaches the freshly stored token.
    return dio.fetch(options);
  }

  Future<void> _onAuthFailure() async {
    await storage.clear();
    onSessionExpired?.call();
  }
}
