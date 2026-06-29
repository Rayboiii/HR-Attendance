import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/employee_home.dart';
import '../../features/home/manager_home.dart';
import '../../features/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod auth changes to a Listenable go_router can refresh on.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (auth.status == AuthStatus.unknown) {
        return loc == '/' ? null : '/';
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return loc == '/login' ? null : '/login';
      }

      // Authenticated: keep users out of splash/login and enforce role areas.
      final home = auth.isManager ? '/manager' : '/employee';
      if (loc == '/' || loc == '/login') return home;
      if (loc.startsWith('/manager') && !auth.isManager) return '/employee';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/employee', builder: (_, _) => const EmployeeHome()),
      GoRoute(path: '/manager', builder: (_, _) => const ManagerHome()),
    ],
  );
});
