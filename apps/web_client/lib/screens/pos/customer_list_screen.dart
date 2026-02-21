import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tenant_provider.dart';
import '../../services/customer_service.dart';
import '../../models/customer.dart';

// Provider for CustomerService
final customerServiceProvider = Provider((ref) => CustomerService());

// Provider for watching customers
final customersStreamProvider = StreamProvider.autoDispose<List<Customer>>((
  ref,
) {
  final tenantAsync = ref.watch(tenantProvider);
  if (!tenantAsync.hasValue || tenantAsync.value?.tenant == null) {
    return const Stream.empty();
  }

  final tenantId = tenantAsync.value!.tenant!.id;
  return ref.read(customerServiceProvider).watchCustomers(tenantId);
});

class CustomerListScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const CustomerListScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddCustomerDialog(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Select Customer' : 'Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddCustomerDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filteredCustomers = customers.where((customer) {
                  return customer.fullName.toLowerCase().contains(
                        _searchQuery,
                      ) ||
                      (customer.phoneNumber?.contains(_searchQuery) ?? false) ||
                      (customer.email?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                return ListView.builder(
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          customer.fullName.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(customer.fullName),
                      subtitle: Text(
                        [
                          customer.phoneNumber,
                          customer.email,
                        ].where((s) => s != null && s.isNotEmpty).join(' • '),
                      ),
                      onTap: () {
                        if (widget.isSelectionMode) {
                          context.pop(customer);
                        } else {
                          // TODO: Navigate to customer details/edit
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCustomerDialog extends StatefulWidget {
  final WidgetRef ref;

  const _AddCustomerDialog({required this.ref});

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tenant = widget.ref.read(tenantProvider).value?.tenant;
      if (tenant == null) throw Exception('No tenant selected');

      final customer = Customer(
        id: '', // Service will generate ID
        tenantId: tenant.id,
        fullName: _nameController.text,
        phoneNumber: _phoneController.text.isEmpty
            ? null
            : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );

      await widget.ref.read(customerServiceProvider).createCustomer(customer);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Customer'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCustomer,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
