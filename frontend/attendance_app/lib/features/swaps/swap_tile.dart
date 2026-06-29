import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/models/shift_swap.dart';

class SwapTile extends StatelessWidget {
  const SwapTile({super.key, required this.swap, this.actions});

  final ShiftSwap swap;

  /// Optional action row (e.g. approve/reject for managers).
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final created = DateFormat('d MMM, h:mm a').format(swap.createdAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    swap.requesterShiftName ?? 'Shift',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(status: swap.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('${swap.requesterName ?? 'Requester'} → '
                '${swap.targetUserName ?? 'Colleague'}'),
            const SizedBox(height: 4),
            Text('Requested $created',
                style: Theme.of(context).textTheme.bodySmall),
            if (swap.managerNote != null && swap.managerNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: ${swap.managerNote}',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (actions != null) ...[
              const SizedBox(height: 8),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SwapStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      SwapStatus.pending => ('Pending', Colors.orange),
      SwapStatus.approved => ('Approved', Colors.green),
      SwapStatus.rejected => ('Rejected', scheme.error),
      SwapStatus.unknown => ('Unknown', scheme.outline),
    };
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}
