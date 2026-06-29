import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/models/department.dart';

final departmentsProvider = FutureProvider.autoDispose<List<Department>>(
  (ref) => ref.read(departmentsRepositoryProvider).getAll(),
);
