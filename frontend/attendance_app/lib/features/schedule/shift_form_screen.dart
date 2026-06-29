import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/department.dart';
import '../../shared/models/shift.dart';
import '../departments/departments_providers.dart';

/// Create a shift, or edit an existing one when [existing] is provided.
/// The department cannot be changed on edit (API doesn't support it).
class ShiftFormScreen extends ConsumerStatefulWidget {
  const ShiftFormScreen({super.key, this.existing});

  final Shift? existing;

  @override
  ConsumerState<ShiftFormScreen> createState() => _ShiftFormScreenState();
}

class _ShiftFormScreenState extends ConsumerState<ShiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _departmentId;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _date = s?.date ?? DateTime.now();
    _start = _parseTime(s?.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
    _end = _parseTime(s?.endTime) ?? const TimeOfDay(hour: 17, minute: 0);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _apiTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 366)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department.')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(shiftsRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.update(
          widget.existing!.id,
          name: _name.text.trim(),
          date: _date,
          startTime: _apiTime(_start),
          endTime: _apiTime(_end),
        );
      } else {
        await repo.create(
          departmentId: _departmentId!,
          name: _name.text.trim(),
          date: _date,
          startTime: _apiTime(_start),
          endTime: _apiTime(_end),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit shift' : 'New shift')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEdit)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apartment),
                title: const Text('Department'),
                subtitle: Text(widget.existing!.departmentName ?? '—'),
              )
            else
              departments.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(apiErrorMessage(e)),
                data: (list) {
                  if (list.isEmpty) {
                    return const Text(
                        'Create a department first before adding shifts.');
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _departmentId,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: list
                        .map((Department d) =>
                            DropdownMenuItem(value: d.id, child: Text(d.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _departmentId = v),
                    validator: (v) =>
                        v == null ? 'Department is required' : null,
                  );
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Shift name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
              onTap: _pickDate,
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.login),
                    title: const Text('Start'),
                    subtitle: Text(_start.format(context)),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout),
                    title: const Text('End'),
                    subtitle: Text(_end.format(context)),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save changes' : 'Create shift'),
            ),
          ],
        ),
      ),
    );
  }
}
