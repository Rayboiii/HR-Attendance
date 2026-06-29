import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/shift_swap.dart';
import '../../shared/widgets/state_views.dart';
import 'swap_tile.dart';
import 'swaps_providers.dart';

class ManagerSwapsScreen extends ConsumerWidget {
  const ManagerSwapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swaps = ref.watch(allSwapsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shift swap requests')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allSwapsProvider.future),
        child: swaps.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            message: apiErrorMessage(e),
            onRetry: () => ref.invalidate(allSwapsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.swap_horiz,
                message: 'No swap requests to review.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final s in list)
                  SwapTile(
                    swap: s,
                    actions: s.isPending
                        ? _ResolveActions(swap: s)
                        : null,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResolveActions extends ConsumerWidget {
  const _ResolveActions({required this.swap});

  final ShiftSwap swap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _resolve(context, ref, approve: false),
          child: const Text('Reject'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => _resolve(context, ref, approve: true),
          child: const Text('Approve'),
        ),
      ],
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref,
      {required bool approve}) async {
    final note = await _promptNote(context, approve: approve);
    if (note == null) return; // cancelled
    try {
      final repo = ref.read(swapsRepositoryProvider);
      if (approve) {
        await repo.approve(swap.id, note.isEmpty ? null : note);
      } else {
        await repo.reject(swap.id, note.isEmpty ? null : note);
      }
      ref.invalidate(allSwapsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'Swap approved.' : 'Swap rejected.'),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  /// Returns the note (possibly empty) on confirm, or null if cancelled.
  Future<String?> _promptNote(BuildContext context, {required bool approve}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve swap' : 'Reject swap'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}
