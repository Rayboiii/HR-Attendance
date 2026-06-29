import '../../core/api/api_client.dart';
import '../../shared/models/attendance_record.dart';

class AttendanceRepository {
  AttendanceRepository(this._api);

  final ApiClient _api;

  Future<AttendanceRecord?> getToday() async {
    final res = await _api.dio.get<dynamic>('/attendance/today');
    final data = res.data;
    if (data == null || data is! Map<String, dynamic>) return null;
    return AttendanceRecord.fromJson(data);
  }

  Future<AttendanceRecord> clockIn({
    required ClockInMethod method,
    String? pin,
    String? qrToken,
    double? lat,
    double? lng,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/attendance/clock-in',
      data: {
        'method': method.apiValue,
        'pin': pin,
        'qrToken': qrToken,
        'lat': lat,
        'lng': lng,
      },
    );
    return AttendanceRecord.fromJson(res.data!);
  }

  Future<AttendanceRecord> clockOut({double? lat, double? lng}) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/attendance/clock-out',
      data: {'lat': lat, 'lng': lng},
    );
    return AttendanceRecord.fromJson(res.data!);
  }
}
