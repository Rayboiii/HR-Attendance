import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/attendance_record.dart';
import '../shifts/shifts_providers.dart';
import 'attendance_providers.dart';
import 'qr_scan_screen.dart';

class ClockInScreen extends ConsumerStatefulWidget {
  const ClockInScreen({super.key});

  @override
  ConsumerState<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends ConsumerState<ClockInScreen> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(todayAttendanceProvider);
    ref.invalidate(myShiftsProvider);
  }

  void _notify(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<void> _run(Future<AttendanceRecord> Function() action,
      String successMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
      _notify(successMessage);
    } catch (e) {
      _notify(apiErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clockInWithPin() async {
    final pin = await _promptPin();
    if (pin == null) return;
    await _run(
      () => ref
          .read(attendanceRepositoryProvider)
          .clockIn(method: ClockInMethod.pin, pin: pin),
      'Clocked in with PIN.',
    );
  }

  Future<void> _clockInWithQr() async {
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (token == null) return;
    await _run(
      () => ref
          .read(attendanceRepositoryProvider)
          .clockIn(method: ClockInMethod.qr, qrToken: token),
      'Clocked in with QR.',
    );
  }

  Future<void> _clockInWithLocation() async {
    final position = await _resolvePosition();
    if (position == null) return;
    await _run(
      () => ref.read(attendanceRepositoryProvider).clockIn(
            method: ClockInMethod.manual,
            lat: position.latitude,
            lng: position.longitude,
          ),
      'Clocked in at your location.',
    );
  }

  Future<void> _clockOut() async {
    await _run(
      () => ref.read(attendanceRepositoryProvider).clockOut(),
      'Clocked out.',
    );
  }

  Future<String?> _promptPin() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Clock in'),
          ),
        ],
      ),
    ).then((value) => (value == null || value.isEmpty) ? null : value);
  }

  Future<Position?> _resolvePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _notify('Location services are turned off.', error: true);
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _notify('Location permission denied.', error: true);
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      _notify('Could not get your location.', error: true);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayAttendanceProvider);

    return today.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _CenteredMessage(
        icon: Icons.error_outline,
        message: apiErrorMessage(e),
        action: FilledButton.tonal(
          onPressed: () => ref.invalidate(todayAttendanceProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (record) => RefreshIndicator(
        onRefresh: () => ref.refresh(todayAttendanceProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (record != null) _StatusCard(record: record),
            const SizedBox(height: 16),
            if (record == null) ...[
              _MethodTile(
                icon: Icons.pin,
                title: 'Clock in with PIN',
                subtitle: 'Enter your personal PIN',
                onTap: _busy ? null : _clockInWithPin,
              ),
              _MethodTile(
                icon: Icons.qr_code_scanner,
                title: 'Scan QR code',
                subtitle: 'Scan the shift QR shown by your manager',
                onTap: _busy ? null : _clockInWithQr,
              ),
              _MethodTile(
                icon: Icons.my_location,
                title: 'Clock in at location',
                subtitle: 'Use GPS to verify you are on-site',
                onTap: _busy ? null : _clockInWithLocation,
              ),
            ] else if (!record.isClockedOut) ...[
              FilledButton.icon(
                onPressed: _busy ? null : _clockOut,
                icon: const Icon(Icons.logout),
                label: const Text('Clock out'),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final clockedOut = record.isClockedOut;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(clockedOut ? Icons.check_circle : Icons.timelapse,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  clockedOut ? 'Shift complete' : 'Clocked in',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Chip(label: Text(record.status)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Shift: ${record.shiftName ?? '—'}'),
            Text('In: ${timeFormat.format(record.clockInTime)} (${record.method})'),
            if (clockedOut)
              Text('Out: ${timeFormat.format(record.clockOutTime!)}'),
            if (record.workedHours != null)
              Text('Worked: ${record.workedHours!.toStringAsFixed(2)} h'),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
