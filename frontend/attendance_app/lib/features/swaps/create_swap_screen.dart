import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/shift.dart';
import '../../shared/models/user_summary.dart';
import '../auth/auth_controller.dart';
import '../shifts/shifts_providers.dart';
import 'swaps_providers.dart';

class CreateSwapScreen extends ConsumerStatefulWidget {
  const CreateSwapScreen({super.key});

  @override
  ConsumerState<CreateSwapScreen> createState() => _CreateSwapScreenState();
}

class _CreateSwapScreenState extends ConsumerState<CreateSwapScreen> {
  String? _shiftId;
  String? _targetUserId;
  bool _saving = false;

  Future<void> _submit() async {
    if (_shiftId == null || _targetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a shift and a colleague.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(swapsRepositoryProvider).create(
            targetUserId: _targetUserId!,
            requesterShiftId: _shiftId!,
          );
      ref.invalidate(mySwapsProvider);
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
    final myShifts = ref.watch(myShiftsProvider);
    final directory = ref.watch(directoryProvider);
    final myId = ref.watch(authControllerProvider).user?.id;
    final dateLabel = DateFormat('EEE d MMM');

    return Scaffold(
      appBar: AppBar(title: const Text('Request shift swap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your shift', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          myShifts.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(apiErrorMessage(e)),
            data: (shifts) {
              if (shifts.isEmpty) {
                return const Text('You have no shifts to swap.');
              }
              return DropdownButtonFormField<String>(
                initialValue: _shiftId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Shift to give away'),
                items: shifts
                    .map((Shift s) => DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} · ${dateLabel.format(s.date)}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _shiftId = v),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Colleague', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          directory.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(apiErrorMessage(e)),
            data: (users) {
              final others = users.where((u) => u.id != myId).toList();
              if (others.isEmpty) {
                return const Text('No colleagues available.');
              }
              return DropdownButtonFormField<String>(
                initialValue: _targetUserId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Swap with'),
                items: others
                    .map((UserSummary u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.departmentName == null
                              ? u.fullName
                              : '${u.fullName} · ${u.departmentName}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _targetUserId = v),
              );
            },
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Send request'),
          ),
        ],
      ),
    );
  }
}
