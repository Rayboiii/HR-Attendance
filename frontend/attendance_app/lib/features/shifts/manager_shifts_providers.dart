import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/models/shift.dart';

/// All shifts from today onward for the next ~30 days (manager schedule view).
final managerShiftsProvider = FutureProvider.autoDispose<List<Shift>>((ref) {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day);
  final to = from.add(const Duration(days: 30));
  return ref.read(shiftsRepositoryProvider).getAll(from: from, to: to);
});
