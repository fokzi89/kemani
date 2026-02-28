import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_admin/models/customer.dart';
import 'package:pos_admin/services/customer_service.dart';
import 'package:pos_admin/services/supabase_service.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _whatsappController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.customer?.fullName ?? '');
    _phoneController =
        TextEditingController(text: widget.customer?.phone ?? '');
    _emailController =
        TextEditingController(text: widget.customer?.email ?? '');
    _whatsappController =
        TextEditingController(text: widget.customer?.whatsappNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.customer == null) {
        // Create new
        final tenantId =
            '00000000-0000-0000-0000-000000000000'; // Replace with actual tenant fetching logic
        final newCustomer = Customer(
          id: const Uuid().v4(),
          tenantId: tenantId,
          phone: _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          fullName: _nameController.text,
          whatsappNumber: _whatsappController.text.isEmpty
              ? null
              : _whatsappController.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _customerService.createCustomer(newCustomer);
      } else {
        // Update existing
        final updates = {
          'full_name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text.isEmpty ? null : _emailController.text,
          'whatsapp_number': _whatsappController.text.isEmpty
              ? null
              : _whatsappController.text,
        };
        await _customerService.updateCustomer(widget.customer!.id, updates);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving customer: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Full Name *'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number *'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          const InputDecoration(labelText: 'Email Address'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _whatsappController,
                      decoration:
                          const InputDecoration(labelText: 'WhatsApp Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCustomer,
                        child: Text(widget.customer == null
                            ? 'Save Customer'
                            : 'Update Customer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
