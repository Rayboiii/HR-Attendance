import '../../core/api/api_client.dart';
import '../../shared/models/department.dart';

class DepartmentsRepository {
  DepartmentsRepository(this._api);

  final ApiClient _api;

  Future<List<Department>> getAll() async {
    final res = await _api.dio.get<List<dynamic>>('/departments');
    return (res.data ?? [])
        .map((e) => Department.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Department> create({
    required String name,
    double? lat,
    double? lng,
    required double radiusMeters,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/departments',
      data: {
        'name': name,
        'locationLat': lat,
        'locationLng': lng,
        'radiusMeters': radiusMeters,
      },
    );
    return Department.fromJson(res.data!);
  }

  Future<Department> update(
    String id, {
    required String name,
    double? lat,
    double? lng,
    required double radiusMeters,
  }) async {
    final res = await _api.dio.put<Map<String, dynamic>>(
      '/departments/$id',
      data: {
        'name': name,
        'locationLat': lat,
        'locationLng': lng,
        'radiusMeters': radiusMeters,
      },
    );
    return Department.fromJson(res.data!);
  }

  Future<void> delete(String id) async {
    await _api.dio.delete<void>('/departments/$id');
  }
}
