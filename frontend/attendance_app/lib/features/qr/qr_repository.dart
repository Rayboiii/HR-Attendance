import '../../core/api/api_client.dart';
import '../../shared/models/qr_token.dart';

class QrRepository {
  QrRepository(this._api);

  final ApiClient _api;

  Future<QrToken> generate(String shiftId, {int validMinutes = 15}) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/qr/generate/$shiftId',
      data: {'validMinutes': validMinutes},
    );
    return QrToken.fromJson(res.data!);
  }
}
