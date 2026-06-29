import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/attendance/attendance_repository.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_repository.dart';
import '../features/departments/departments_repository.dart';
import '../features/employees/employees_repository.dart';
import '../features/notifications/notifications_repository.dart';
import '../features/qr/qr_repository.dart';
import '../features/reports/reports_repository.dart';
import '../features/shifts/shifts_repository.dart';
import '../features/swaps/swaps_repository.dart';
import 'api/api_client.dart';
import 'auth/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    storage: ref.read(tokenStorageProvider),
    // Deferred read avoids a construction-time cycle with the auth controller.
    onSessionExpired: () =>
        ref.read(authControllerProvider.notifier).onSessionExpired(),
  );
});

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.read(apiClientProvider)));

final shiftsRepositoryProvider = Provider<ShiftsRepository>(
    (ref) => ShiftsRepository(ref.read(apiClientProvider)));

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
    (ref) => AttendanceRepository(ref.read(apiClientProvider)));

final departmentsRepositoryProvider = Provider<DepartmentsRepository>(
    (ref) => DepartmentsRepository(ref.read(apiClientProvider)));

final employeesRepositoryProvider = Provider<EmployeesRepository>(
    (ref) => EmployeesRepository(ref.read(apiClientProvider)));

final qrRepositoryProvider =
    Provider<QrRepository>((ref) => QrRepository(ref.read(apiClientProvider)));

final swapsRepositoryProvider =
    Provider<SwapsRepository>((ref) => SwapsRepository(ref.read(apiClientProvider)));

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
    (ref) => NotificationsRepository(ref.read(apiClientProvider)));

final reportsRepositoryProvider = Provider<ReportsRepository>(
    (ref) => ReportsRepository(ref.read(apiClientProvider)));
