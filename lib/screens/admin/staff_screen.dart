import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/staff.dart';
import '../../services/staff_service.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffListAsync = ref.watch(staffListProvider);
    final staffService = ref.watch(staffServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
      ),
      body: staffListAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return const Center(
              child: Text('No staff members yet. Invite someone!'),
            );
          }
          return ListView.builder(
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: staff.imageUrl != null ? NetworkImage(staff.imageUrl!) : null,
                    child: staff.imageUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(staff.name),
                  subtitle: Text('${staff.email} - ${staff.role}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                    onPressed: () async {
                      // Confirm deletion
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Staff'),
                          content: Text('Are you sure you want to delete ${staff.name}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(staffListProvider.notifier).deleteStaff(staff.id);
                      }
                    },
                  ),
                  onTap: () {
                    // TODO: Implement staff detail/edit screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped on ${staff.name}')),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showInviteStaffDialog(context, staffService, ref.read(staffListProvider.notifier));
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showInviteStaffDialog(BuildContext context, StaffService staffService, StaffListNotifier staffListNotifier) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    String? role = 'cashier'; // Default role
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite New Staff'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['admin', 'cashier', 'manager']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (String? newValue) {
                  role = newValue;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final newStaff = Staff(
                  id: const Uuid().v4(), // Generate a unique ID
                  name: nameController.text,
                  email: emailController.text,
                  role: role!,
                  isActive: true,
                );
                await staffListNotifier.addStaff(newStaff);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Staff ${newStaff.name} invited!')),
                );
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }
}
