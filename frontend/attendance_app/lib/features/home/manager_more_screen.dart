import 'package:flutter/material.dart';

import '../../shared/widgets/logout_action.dart';
import '../notifications/notifications_screen.dart';
import '../reports/reports_screen.dart';
import '../swaps/manager_swaps_screen.dart';

class ManagerMoreScreen extends StatelessWidget {
  const ManagerMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        actions: const [LogoutAction()],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            subtitle: const Text('Attendance & overtime'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Shift swap requests'),
            subtitle: const Text('Approve or reject'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManagerSwapsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
