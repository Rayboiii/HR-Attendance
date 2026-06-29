import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_error.dart';
import '../../shared/models/shift.dart';
import 'shifts_providers.dart';

class MyShiftsScreen extends ConsumerWidget {
  const MyShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shifts = ref.watch(myShiftsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myShiftsProvider.future),
      child: shifts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(myShiftsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyView();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ShiftCard(shift: list[i]),
          );
        },
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(shift.date);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(DateFormat('dd').format(shift.date)),
        ),
        title: Text(shift.name),
        subtitle: Text(
          '$dateLabel\n${shift.startLabel} – ${shift.endLabel}'
          '${shift.departmentName != null ? ' · ${shift.departmentName}' : ''}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.event_busy,
            size: 64, color: Theme.of(context).disabledColor),
        const SizedBox(height: 16),
        const Center(child: Text('No shifts assigned yet.')),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.error_outline,
            size: 64, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Center(child: Text(message, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
