import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/logout_action.dart';
import '../../shared/widgets/state_views.dart';
import 'deactivated_employees_screen.dart';
import 'employee_form_screen.dart';
import 'employees_providers.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);
    final inactiveCount =
        employees.asData?.value.where((u) => !u.isActive).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            tooltip: 'Deactivated',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const DeactivatedEmployeesScreen()),
            ),
            icon: Badge(
              isLabelVisible: inactiveCount > 0,
              label: Text('$inactiveCount'),
              child: const Icon(Icons.person_off_outlined),
            ),
          ),
          const LogoutAction(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(employeesProvider.future),
        child: employees.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            message: apiErrorMessage(e),
            onRetry: () => ref.invalidate(employeesProvider),
          ),
          data: (list) {
            final active = list.where((u) => u.isActive).toList();
            if (active.isEmpty) {
              return const EmptyState(
                icon: Icons.people,
                message: 'No active employees. Tap Add to create one.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: active.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EmployeeCard(
                user: active[i],
                onEdit: () => _openForm(context, ref, existing: active[i]),
                onResetPassword: () => _resetPassword(context, ref, active[i]),
                onDeactivate: () => _confirmDeactivate(context, ref, active[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {AppUser? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(existing: existing)),
    );
    if (saved == true) ref.invalidate(employeesProvider);
  }

  Future<void> _resetPassword(
      BuildContext context, WidgetRef ref, AppUser user) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset password · ${user.fullName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
            validator: (v) => (v == null || v.length < 6)
                ? 'At least 6 characters'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (newPassword == null) return;
    try {
      await ref.read(employeesRepositoryProvider).resetPassword(user.id, newPassword);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset. The user must sign in again.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  Future<void> _confirmDeactivate(
      BuildContext context, WidgetRef ref, AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate user?'),
        content: Text('${user.fullName} will no longer be able to sign in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(employeesRepositoryProvider).deactivate(user.id);
      ref.invalidate(employeesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deactivated.')),
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

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.user,
    required this.onEdit,
    required this.onResetPassword,
    required this.onDeactivate,
  });

  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName.isNotEmpty
        ? user.fullName.trim()[0].toUpperCase()
        : '?';
    final role = user.isManager ? 'Manager' : 'Employee';
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(initials)),
        title: Text(user.fullName + (user.isActive ? '' : '  (inactive)')),
        subtitle: Text(
          '${user.email}\n'
          '$role · ${user.departmentName ?? 'No department'}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'reset':
                onResetPassword();
              case 'deactivate':
                onDeactivate();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'reset', child: Text('Reset password')),
            if (user.isActive)
              const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
          ],
        ),
      ),
    );
  }
}
