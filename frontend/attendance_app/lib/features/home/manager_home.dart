import 'package:flutter/material.dart';

import '../departments/departments_screen.dart';
import '../employees/employees_screen.dart';
import '../schedule/schedule_screen.dart';
import 'manager_more_screen.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _index = 0;

  static const _tabs = [
    ScheduleScreen(),
    EmployeesScreen(),
    DepartmentsScreen(),
    ManagerMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'Schedule'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Employees'),
          NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment),
              label: 'Departments'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'More'),
        ],
      ),
    );
  }
}
