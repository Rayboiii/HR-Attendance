import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/models/app_notification.dart';

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => ref.read(notificationsRepositoryProvider).get(),
);

/// Count of unread notifications, for the app-bar badge.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final items = await ref.read(notificationsRepositoryProvider).get(unreadOnly: true);
  return items.length;
});
