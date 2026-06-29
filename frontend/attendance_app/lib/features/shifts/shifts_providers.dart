import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/models/shift.dart';

/// Shifts assigned to the signed-in employee.
final myShiftsProvider = FutureProvider.autoDispose<List<Shift>>(
  (ref) => ref.read(shiftsRepositoryProvider).getMyShifts(),
);
