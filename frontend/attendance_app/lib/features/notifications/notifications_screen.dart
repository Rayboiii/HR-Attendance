import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/app_notification.dart';
import '../../shared/widgets/state_views.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: notifications.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            message: apiErrorMessage(e),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none,
                message: 'No notifications yet.',
              );
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _NotificationTile(
                notification: list[i],
                onTap: () => _markRead(ref, list[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markRead(WidgetRef ref, AppNotification n) async {
    if (n.isRead) return;
    await ref.read(notificationsRepositoryProvider).markRead(n.id);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM, h:mm a').format(notification.createdAt);
    return ListTile(
      leading: Icon(
        notification.isRead
            ? Icons.notifications_none
            : Icons.notifications_active,
        color: notification.isRead ? null : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text('${notification.message}\n$when'),
      isThreeLine: true,
      onTap: onTap,
    );
  }
}
