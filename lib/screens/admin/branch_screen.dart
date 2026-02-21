import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/branch.dart';
import '../../services/branch_service.dart';

class BranchScreen extends ConsumerWidget {
  const BranchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchList = ref.watch(branchListProvider);
    final branchService = ref.watch(branchServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Management'),
      ),
      body: branchList.isEmpty
          ? const Center(child: Text('No branches found.'))
          : ListView.builder(
              itemCount: branchList.length,
              itemBuilder: (context, index) {
                final branch = branchList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(branch.name),
                    subtitle: Text(branch.location),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showBranchDialog(context, ref, branch: branch),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Branch'),
                                content: Text('Are you sure you want to delete ${branch.name}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(branchListProvider.notifier).deleteBranch(branch.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBranchDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showBranchDialog(BuildContext context, WidgetRef ref, {Branch? branch}) {
    final TextEditingController nameController = TextEditingController(text: branch?.name);
    final TextEditingController locationController = TextEditingController(text: branch?.location);
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(branch == null ? 'Add New Branch' : 'Edit Branch'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
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
                final newBranch = Branch(
                  id: branch?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  location: locationController.text,
                );

                if (branch == null) {
                  await ref.read(branchListProvider.notifier).addBranch(newBranch);
                } else {
                  await ref.read(branchListProvider.notifier).updateBranch(newBranch);
                }

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(branch == null ? 'Branch added!' : 'Branch updated!')),
                );
              }
            },
            child: Text(branch == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}
