import '../../core/api/api_client.dart';
import '../../shared/models/shift_swap.dart';
import '../../shared/models/user_summary.dart';

class SwapsRepository {
  SwapsRepository(this._api);

  final ApiClient _api;

  Future<List<UserSummary>> directory() async {
    final res = await _api.dio.get<List<dynamic>>('/users/directory');
    return (res.data ?? [])
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ShiftSwap> create({
    required String targetUserId,
    required String requesterShiftId,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/shift-swaps',
      data: {
        'targetUserId': targetUserId,
        'requesterShiftId': requesterShiftId,
      },
    );
    return ShiftSwap.fromJson(res.data!);
  }

  Future<List<ShiftSwap>> getMy() => _list('/shift-swaps/my');
  Future<List<ShiftSwap>> getAll() => _list('/shift-swaps');

  Future<ShiftSwap> approve(String id, String? note) =>
      _resolve('/shift-swaps/$id/approve', note);

  Future<ShiftSwap> reject(String id, String? note) =>
      _resolve('/shift-swaps/$id/reject', note);

  Future<List<ShiftSwap>> _list(String path) async {
    final res = await _api.dio.get<List<dynamic>>(path);
    return (res.data ?? [])
        .map((e) => ShiftSwap.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ShiftSwap> _resolve(String path, String? note) async {
    final res = await _api.dio.patch<Map<String, dynamic>>(
      path,
      data: {'managerNote': note},
    );
    return ShiftSwap.fromJson(res.data!);
  }
}
