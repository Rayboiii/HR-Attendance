import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../shared/models/report_rows.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  Future<List<AttendanceReportRow>> attendance({
    required DateTime from,
    required DateTime to,
    String? departmentId,
  }) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/reports/attendance',
      queryParameters: _params(from, to, departmentId),
    );
    return (res.data ?? [])
        .map((e) => AttendanceReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OvertimeReportRow>> overtime({
    required DateTime from,
    required DateTime to,
    String? departmentId,
  }) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/reports/overtime',
      queryParameters: _params(from, to, departmentId),
    );
    return (res.data ?? [])
        .map((e) => OvertimeReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _params(DateTime from, DateTime to, String? departmentId) => {
        'from': _dateFormat.format(from),
        'to': _dateFormat.format(to),
        'departmentId': ?departmentId,
      };
}
