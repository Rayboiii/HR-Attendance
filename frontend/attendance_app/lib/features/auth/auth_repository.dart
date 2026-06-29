import '../../core/api/api_client.dart';
import '../../shared/models/auth_response.dart';
import '../../shared/models/user.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthResponse> login(String email, String password) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(res.data!);
  }

  Future<AppUser> me() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/auth/me');
    return AppUser.fromJson(res.data!);
  }

  Future<void> logout() async {
    await _api.dio.post<void>('/auth/logout');
  }
}
