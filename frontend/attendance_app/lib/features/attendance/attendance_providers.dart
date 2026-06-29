import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/models/attendance_record.dart';

/// The signed-in employee's attendance record for today (null if not clocked in).
final todayAttendanceProvider = FutureProvider.autoDispose<AttendanceRecord?>(
  (ref) => ref.read(attendanceRepositoryProvider).getToday(),
);
