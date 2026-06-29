import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/state_views.dart';
import 'employees_providers.dart';

class DeactivatedEmployeesScreen extends ConsumerWidget {
  const DeactivatedEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Deactivated employees')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(employeesProvider.future),
        child: employees.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            message: apiErrorMessage(e),
            onRetry: () => ref.invalidate(employeesProvider),
          ),
          data: (list) {
            final inactive = list.where((u) => !u.isActive).toList();
            if (inactive.isEmpty) {
              return const EmptyState(
                icon: Icons.person_off_outlined,
                message: 'No deactivated employees.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: inactive.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DeactivatedCard(
                user: inactive[i],
                onReactivate: () => _reactivate(context, ref, inactive[i]),
                onDelete: () => _confirmDelete(context, ref, inactive[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _reactivate(
      BuildContext context, WidgetRef ref, AppUser user) async {
    try {
      await ref.read(employeesRepositoryProvider).reactivate(user.id);
      ref.invalidate(employeesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} reactivated.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          '${user.fullName} and their attendance history will be permanently '
          'removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(employeesRepositoryProvider).delete(user.id);
      ref.invalidate(employeesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} deleted.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }
}

class _DeactivatedCard extends StatelessWidget {
  const _DeactivatedCard({
    required this.user,
    required this.onReactivate,
    required this.onDelete,
  });

  final AppUser user;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName.isNotEmpty
        ? user.fullName.trim()[0].toUpperCase()
        : '?';
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(initials)),
        title: Text(user.fullName),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Reactivate',
              icon: const Icon(Icons.restore),
              onPressed: onReactivate,
            ),
            IconButton(
              tooltip: 'Delete permanently',
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
