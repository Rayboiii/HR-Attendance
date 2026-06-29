import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/department.dart';
import '../../shared/models/report_rows.dart';
import '../departments/departments_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _from;
  late DateTime _to;
  String? _departmentId;

  late Future<List<AttendanceReportRow>> _attendance;
  late Future<List<OvertimeReportRow>> _overtime;

  static final _dateLabel = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 30));
    _reload();
  }

  void _reload() {
    final repo = ref.read(reportsRepositoryProvider);
    _attendance = repo.attendance(from: _from, to: _to, departmentId: _departmentId);
    _overtime = repo.overtime(from: _from, to: _to, departmentId: _departmentId);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
        _reload();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(departmentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Attendance'),
            Tab(text: 'Overtime'),
          ]),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(isFrom: true),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('From: ${_dateLabel.format(_from)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(isFrom: false),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('To: ${_dateLabel.format(_to)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  departments.maybeWhen(
                    data: (list) => DropdownButtonFormField<String?>(
                      initialValue: _departmentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('All departments')),
                        ...list.map((Department d) => DropdownMenuItem<String?>(
                            value: d.id, child: Text(d.name))),
                      ],
                      onChanged: (v) => setState(() {
                        _departmentId = v;
                        _reload();
                      }),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AttendanceTab(future: _attendance),
                  _OvertimeTab(future: _overtime),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.future});

  final Future<List<AttendanceReportRow>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceReportRow>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text(apiErrorMessage(snap.error!)));
        }
        final rows = snap.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Text('No attendance in this range.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = rows[i];
            return Card(
              child: ListTile(
                title: Text(r.fullName),
                subtitle: Text(
                  'Present ${r.presentCount} · Late ${r.lateCount} · '
                  'Absent ${r.absentCount} · Half ${r.halfDayCount}\n'
                  '${r.totalDays} days · ${r.totalWorkedHours.toStringAsFixed(1)} h worked',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _OvertimeTab extends StatelessWidget {
  const _OvertimeTab({required this.future});

  final Future<List<OvertimeReportRow>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OvertimeReportRow>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text(apiErrorMessage(snap.error!)));
        }
        final rows = snap.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Text('No completed shifts in this range.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = rows[i];
            return Card(
              child: ListTile(
                title: Text(r.fullName),
                subtitle: Text(
                  'Worked ${r.totalWorkedHours.toStringAsFixed(1)} h · '
                  'Standard ${r.standardHours.toStringAsFixed(1)} h',
                ),
                trailing: Chip(
                  label: Text('OT ${r.overtimeHours.toStringAsFixed(1)} h'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
