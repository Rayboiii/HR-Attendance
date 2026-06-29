import '../../core/api/api_client.dart';
import '../../shared/models/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> get({bool unreadOnly = false}) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/notifications',
      queryParameters: {'unreadOnly': unreadOnly},
    );
    return (res.data ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    await _api.dio.patch<void>('/notifications/$id/read');
  }
}
