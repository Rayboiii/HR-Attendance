import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/shift.dart';
import '../../shared/widgets/logout_action.dart';
import '../../shared/widgets/state_views.dart';
import '../employees/employees_providers.dart';
import '../shifts/manager_shifts_providers.dart';
import 'shift_form_screen.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shifts = ref.watch(managerShiftsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: const [LogoutAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ShiftFormScreen()),
          );
          if (created == true) ref.invalidate(managerShiftsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Shift'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(managerShiftsProvider.future),
        child: shifts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            message: apiErrorMessage(e),
            onRetry: () => ref.invalidate(managerShiftsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.event_busy,
                message: 'No upcoming shifts. Tap “Shift” to create one.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ShiftCard(shift: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ShiftCard extends ConsumerWidget {
  const _ShiftCard({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = DateFormat('EEE, d MMM').format(shift.date);
    final assignees = shift.assignees.isEmpty
        ? 'No one assigned'
        : shift.assignees.map((a) => a.fullName).join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(shift.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _onAction(context, ref, v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'assign', child: Text('Assign people')),
                    PopupMenuItem(value: 'qr', child: Text('Generate QR')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Text('$dateLabel · ${shift.startLabel}–${shift.endLabel}'
                '${shift.departmentName != null ? ' · ${shift.departmentName}' : ''}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(assignees)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'assign':
        await _openAssignSheet(context, ref);
      case 'qr':
        await _generateQr(context, ref);
      case 'edit':
        await _edit(context, ref);
      case 'delete':
        await _confirmDelete(context, ref);
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ShiftFormScreen(existing: shift)),
    );
    if (saved == true) ref.invalidate(managerShiftsProvider);
  }

  Future<void> _openAssignSheet(BuildContext context, WidgetRef ref) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssignSheet(shift: shift),
    );
    if (changed == true) ref.invalidate(managerShiftsProvider);
  }

  Future<void> _generateQr(BuildContext context, WidgetRef ref) async {
    try {
      final token = await ref.read(qrRepositoryProvider).generate(shift.id);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('QR · ${shift.name}'),
          content: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: QrImageView(
                    data: token.token,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Valid until '
                    '${DateFormat('h:mm a').format(token.expiresAt)}'),
                const Text(
                  'Single use — ask the employee to scan now.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete shift?'),
        content: Text('“${shift.name}” on '
            '${DateFormat('d MMM').format(shift.date)} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(shiftsRepositoryProvider).delete(shift.id);
      ref.invalidate(managerShiftsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Shift deleted.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }
}

class _AssignSheet extends ConsumerStatefulWidget {
  const _AssignSheet({required this.shift});

  final Shift shift;

  @override
  ConsumerState<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends ConsumerState<_AssignSheet> {
  late final Set<String> _initial;
  late final Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initial = widget.shift.assignees.map((a) => a.userId).toSet();
    _selected = {..._initial};
  }

  Future<void> _save() async {
    final toAdd = _selected.difference(_initial).toList();
    final toRemove = _initial.difference(_selected).toList();
    if (toAdd.isEmpty && toRemove.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(shiftsRepositoryProvider);
    try {
      if (toAdd.isNotEmpty) await repo.assign(widget.shift.id, toAdd);
      for (final userId in toRemove) {
        await repo.unassign(widget.shift.id, userId);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Assign to ${widget.shift.name}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Flexible(
              child: employees.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(apiErrorMessage(e)),
                data: (list) {
                  final active = list.where((u) => u.isActive).toList();
                  if (active.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No active employees to assign.'),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: active.map((u) {
                      return CheckboxListTile(
                        value: _selected.contains(u.id),
                        title: Text(u.fullName),
                        subtitle: Text(u.departmentName ?? 'No department'),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(u.id);
                          } else {
                            _selected.remove(u.id);
                          }
                        }),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save assignment'),
            ),
          ],
        ),
      ),
    );
  }
}
