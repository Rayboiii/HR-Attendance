import '../../core/api/api_client.dart';
import '../../shared/models/user.dart';

class EmployeesRepository {
  EmployeesRepository(this._api);

  final ApiClient _api;

  Future<List<AppUser>> getAll() async {
    final res = await _api.dio.get<List<dynamic>>('/users');
    return (res.data ?? [])
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppUser> create({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? departmentId,
    String? pin,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/users',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role == UserRole.manager ? 'Manager' : 'Employee',
        'departmentId': departmentId,
        'pin': (pin == null || pin.isEmpty) ? null : pin,
      },
    );
    return AppUser.fromJson(res.data!);
  }

  Future<AppUser> update(
    String id, {
    required String fullName,
    required String email,
    required UserRole role,
    String? departmentId,
    String? pin,
  }) async {
    final res = await _api.dio.put<Map<String, dynamic>>(
      '/users/$id',
      data: {
        'fullName': fullName,
        'email': email,
        'role': role == UserRole.manager ? 'Manager' : 'Employee',
        'departmentId': departmentId,
        'pin': (pin == null || pin.isEmpty) ? null : pin,
      },
    );
    return AppUser.fromJson(res.data!);
  }

  Future<void> resetPassword(String id, String newPassword) async {
    await _api.dio.patch<void>(
      '/users/$id/reset-password',
      data: {'newPassword': newPassword},
    );
  }

  Future<void> deactivate(String id) async {
    await _api.dio.patch<void>('/users/$id/deactivate');
  }

  Future<void> reactivate(String id) async {
    await _api.dio.patch<void>('/users/$id/reactivate');
  }

  /// Permanently deletes a user. The API only allows this for inactive users.
  Future<void> delete(String id) async {
    await _api.dio.delete<void>('/users/$id');
  }
}
