import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/models/user.dart';

final employeesProvider = FutureProvider.autoDispose<List<AppUser>>(
  (ref) => ref.read(employeesRepositoryProvider).getAll(),
);
