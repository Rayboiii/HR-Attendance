import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/models/shift_swap.dart';
import '../../shared/models/user_summary.dart';

/// Swap requests involving the signed-in user (as requester or target).
final mySwapsProvider = FutureProvider.autoDispose<List<ShiftSwap>>(
  (ref) => ref.read(swapsRepositoryProvider).getMy(),
);

/// All swap requests (manager view), pending first.
final allSwapsProvider = FutureProvider.autoDispose<List<ShiftSwap>>(
  (ref) => ref.read(swapsRepositoryProvider).getAll(),
);

/// Minimal directory of active users for picking a swap target.
final directoryProvider = FutureProvider.autoDispose<List<UserSummary>>(
  (ref) => ref.read(swapsRepositoryProvider).directory(),
);
