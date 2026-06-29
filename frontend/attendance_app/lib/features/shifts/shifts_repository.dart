import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../shared/models/shift.dart';

class ShiftsRepository {
  ShiftsRepository(this._api);

  final ApiClient _api;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Shifts assigned to the signed-in employee.
  Future<List<Shift>> getMyShifts({DateTime? from, DateTime? to}) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/shifts/my',
      queryParameters: {
        if (from != null) 'from': _dateFormat.format(from),
        if (to != null) 'to': _dateFormat.format(to),
      },
    );
    return _parseList(res.data);
  }

  /// All shifts (manager view).
  Future<List<Shift>> getAll({DateTime? from, DateTime? to}) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/shifts',
      queryParameters: {
        if (from != null) 'from': _dateFormat.format(from),
        if (to != null) 'to': _dateFormat.format(to),
      },
    );
    return _parseList(res.data);
  }

  Future<Shift> create({
    required String departmentId,
    required String name,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/shifts',
      data: {
        'departmentId': departmentId,
        'name': name,
        'date': _dateFormat.format(date),
        'startTime': startTime,
        'endTime': endTime,
      },
    );
    return Shift.fromJson(res.data!);
  }

  Future<Shift> update(
    String shiftId, {
    required String name,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    final res = await _api.dio.put<Map<String, dynamic>>(
      '/shifts/$shiftId',
      data: {
        'name': name,
        'date': _dateFormat.format(date),
        'startTime': startTime,
        'endTime': endTime,
      },
    );
    return Shift.fromJson(res.data!);
  }

  Future<Shift> assign(String shiftId, List<String> userIds) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/shifts/$shiftId/assign',
      data: {'userIds': userIds},
    );
    return Shift.fromJson(res.data!);
  }

  Future<Shift> unassign(String shiftId, String userId) async {
    final res = await _api.dio.delete<Map<String, dynamic>>(
      '/shifts/$shiftId/assign/$userId',
    );
    return Shift.fromJson(res.data!);
  }

  Future<void> delete(String shiftId) async {
    await _api.dio.delete<void>('/shifts/$shiftId');
  }

  List<Shift> _parseList(List<dynamic>? data) =>
      (data ?? []).map((e) => Shift.fromJson(e as Map<String, dynamic>)).toList();
}
