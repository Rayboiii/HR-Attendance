import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/department.dart';
import '../../shared/models/user.dart';
import '../departments/departments_providers.dart';

/// Add a new employee, or edit an existing one when [existing] is provided.
/// Password is not edited here — use the separate "Reset password" action.
class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key, this.existing});

  final AppUser? existing;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _pin = TextEditingController();
  late UserRole _role;
  String? _departmentId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    _fullName = TextEditingController(text: u?.fullName ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _role = u?.role == UserRole.manager ? UserRole.manager : UserRole.employee;
    _departmentId = u?.departmentId;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(employeesRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.update(
          widget.existing!.id,
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          role: _role,
          departmentId: _departmentId,
          pin: _pin.text.trim(),
        );
      } else {
        await repo.create(
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
          departmentId: _departmentId,
          pin: _pin.text.trim(),
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit employee' : 'Add employee')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullName,
              decoration: const InputDecoration(labelText: 'Full name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Full name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary password',
                  helperText: 'At least 6 characters',
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(
                    value: UserRole.employee, child: Text('Employee')),
                DropdownMenuItem(
                    value: UserRole.manager, child: Text('Manager')),
              ],
              onChanged: (v) => setState(() => _role = v ?? UserRole.employee),
            ),
            const SizedBox(height: 12),
            departments.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  Text('Could not load departments: ${apiErrorMessage(e)}'),
              data: (list) => DropdownButtonFormField<String?>(
                initialValue: _departmentId,
                decoration:
                    const InputDecoration(labelText: 'Department (optional)'),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('None')),
                  ...list.map((Department d) => DropdownMenuItem<String?>(
                      value: d.id, child: Text(d.name))),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pin,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Clock-in PIN (optional)',
                helperText: _isEdit
                    ? 'Leave blank to keep the current PIN'
                    : '4–6 digits, used for PIN clock-in',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!RegExp(r'^\d{4,6}$').hasMatch(v)) {
                  return 'PIN must be 4–6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save changes' : 'Create employee'),
            ),
          ],
        ),
      ),
    );
  }
}
