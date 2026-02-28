import 'package:flutter/material.dart';
import 'package:pos_admin/models/customer.dart';
import 'package:pos_admin/services/customer_service.dart';
import 'package:pos_admin/services/loyalty_service.dart';
import 'package:pos_admin/models/order.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final LoyaltyService _loyaltyService = LoyaltyService();
  final CustomerService _customerService = CustomerService();

  late Customer _customer;
  List<Order> _purchaseHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final updatedCustomer = await _customerService.getCustomer(_customer.id);
      if (updatedCustomer != null) {
        _customer = updatedCustomer;
      }
      _purchaseHistory = await _loyaltyService.getPurchaseHistory(_customer.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading details: $e')));
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
        title: Text(_customer.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerFormScreen(customer: _customer),
                ),
              ).then((_) => _fetchDetails());
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Contact Information'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phone: ${_customer.phone}'),
                          if (_customer.email != null)
                            Text('Email: ${_customer.email}'),
                          if (_customer.whatsappNumber != null)
                            Text('WhatsApp: ${_customer.whatsappNumber}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      title: const Text('Loyalty & Analytics'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Loyalty Tier: ${_customer.loyaltyTier.toUpperCase()}'),
                          Text('Points: ${_customer.loyaltyPoints}'),
                          Text(
                              'Total Purchases: \$${_customer.totalPurchases.toStringAsFixed(2)}'),
                          Text('Purchase Count: ${_customer.purchaseCount}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Purchase History',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_purchaseHistory.isEmpty)
                    const Text('No previous purchases found.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _purchaseHistory.length,
                      itemBuilder: (context, index) {
                        final order = _purchaseHistory[index];
                        return Card(
                          child: ListTile(
                            title: Text('Order #${order.orderNumber}'),
                            subtitle: Text(
                                '${order.createdAt.toLocal().toString().split(' ')[0]} - \nAmount: \$${order.totalAmount.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
