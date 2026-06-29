import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../shared/widgets/state_views.dart';
import 'create_swap_screen.dart';
import 'swap_tile.dart';
import 'swaps_providers.dart';

class MySwapsScreen extends ConsumerWidget {
  const MySwapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swaps = ref.watch(mySwapsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My swap requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateSwapScreen()),
          );
          if (created == true) ref.invalidate(mySwapsProvider);
        },
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Request'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(mySwapsProvider.future),
        child: swaps.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            message: apiErrorMessage(e),
            onRetry: () => ref.invalidate(mySwapsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.swap_horiz,
                message: 'No swap requests yet. Tap “Request” to create one.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [for (final s in list) SwapTile(swap: s)],
            );
          },
        ),
      ),
    );
  }
}
