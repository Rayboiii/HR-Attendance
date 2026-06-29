import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/notifications_action.dart';
import '../attendance/clock_in_screen.dart';
import '../auth/auth_controller.dart';
import '../shifts/my_shifts_screen.dart';
import 'employee_more_screen.dart';

class EmployeeHome extends ConsumerStatefulWidget {
  const EmployeeHome({super.key});

  @override
  ConsumerState<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends ConsumerState<EmployeeHome> {
  int _index = 0;

  static const _titles = ['My Shifts', 'Clock In', 'More'];
  static const _tabs = [
    MyShiftsScreen(),
    ClockInScreen(),
    EmployeeMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          const NotificationsAction(),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.fullName ?? 'Signed in'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Shifts'),
          NavigationDestination(
              icon: Icon(Icons.fingerprint),
              selectedIcon: Icon(Icons.fingerprint),
              label: 'Clock In'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'More'),
        ],
      ),
    );
  }
}
