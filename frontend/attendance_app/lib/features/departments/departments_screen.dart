import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../shared/models/department.dart';
import '../../shared/widgets/logout_action.dart';
import '../../shared/widgets/state_views.dart';
import 'departments_providers.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: const [LogoutAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Department'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(departmentsProvider.future),
        child: departments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            message: apiErrorMessage(e),
            onRetry: () => ref.invalidate(departmentsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.apartment,
                message: 'No departments yet. Add one to start scheduling.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DepartmentCard(
                department: list[i],
                onEdit: () => _openForm(context, ref, existing: list[i]),
                onDelete: () => _confirmDelete(context, ref, list[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {Department? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DepartmentForm(existing: existing),
    );
    if (saved == true) ref.invalidate(departmentsProvider);
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Department dept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete department?'),
        content: Text('“${dept.name}” will be removed. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(departmentsRepositoryProvider).delete(dept.id);
      ref.invalidate(departmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Department deleted.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.department,
    required this.onEdit,
    required this.onDelete,
  });

  final Department department;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final geo = department.hasLocation
        ? 'Geofence: ${department.radiusMeters.toStringAsFixed(0)} m'
        : 'No geofence set';
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.apartment)),
        title: Text(department.name),
        subtitle: Text(geo),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _DepartmentForm extends ConsumerStatefulWidget {
  const _DepartmentForm({this.existing});

  final Department? existing;

  @override
  ConsumerState<_DepartmentForm> createState() => _DepartmentFormState();
}

class _DepartmentFormState extends ConsumerState<_DepartmentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _radius;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _name = TextEditingController(text: d?.name ?? '');
    _lat = TextEditingController(text: d?.locationLat?.toString() ?? '');
    _lng = TextEditingController(text: d?.locationLng?.toString() ?? '');
    _radius = TextEditingController(text: (d?.radiusMeters ?? 200).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lng.dispose();
    _radius.dispose();
    super.dispose();
  }

  double? _parseOptional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(departmentsRepositoryProvider);
    final name = _name.text.trim();
    final lat = _parseOptional(_lat);
    final lng = _parseOptional(_lng);
    final radius = double.tryParse(_radius.text.trim()) ?? 200;
    try {
      if (widget.existing == null) {
        await repo.create(name: name, lat: lat, lng: lng, radiusMeters: radius);
      } else {
        await repo.update(widget.existing!.id,
            name: name, lat: lat, lng: lng, radiusMeters: radius);
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
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit department' : 'New department',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _radius,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Geofence radius (m)'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
