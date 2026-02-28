import 'package:flutter/material.dart';
import 'package:pos_admin/models/order.dart';
import 'package:pos_admin/services/order_service.dart';
import 'package:pos_admin/models/customer.dart';
import 'package:pos_admin/services/customer_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  final CustomerService _customerService = CustomerService();

  late Order _order;
  Customer? _customer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final orderWithItems = await _orderService.getOrder(_order.id);
      if (orderWithItems != null) {
        _order = orderWithItems;
      }
      _customer = await _customerService.getCustomer(_order.customerId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      if (newStatus == 'cancelled') {
        _order = await _orderService.cancelOrder(
            _order.id, 'Cancelled via admin UI');
      } else {
        _order = await _orderService.updateOrderStatus(_order.id, newStatus);
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: Text('Order #${_order.orderNumber}'),
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
                      title: const Text('Order Summary'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Type: ${_order.orderType} | Fulfillment: ${_order.fulfillmentType}'),
                          Text('Status: ${_order.orderStatus.toUpperCase()}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              'Payment: ${_order.paymentStatus.toUpperCase()} - ${_order.paymentMethod ?? "Unknown"}'),
                          const Divider(),
                          Text(
                              'Subtotal: \$${_order.subtotal.toStringAsFixed(2)}'),
                          Text('Tax: \$${_order.taxAmount.toStringAsFixed(2)}'),
                          Text(
                              'Delivery: \$${_order.deliveryFee.toStringAsFixed(2)}'),
                          Text(
                              'Total: \$${_order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_customer != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Customer Details'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: ${_customer!.fullName}'),
                            Text('Phone: ${_customer!.phone}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('Order Items',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_order.items == null || _order.items!.isEmpty)
                    const Text('No items found.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _order.items!.length,
                      itemBuilder: (context, index) {
                        final item = _order.items![index];
                        return Card(
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text(
                                'Qty: ${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                            trailing:
                                Text('\$${item.subtotal.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                  const Text('Update Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ElevatedButton(
                        onPressed: _order.orderStatus == 'confirmed'
                            ? null
                            : () => _updateStatus('confirmed'),
                        child: const Text('Confirm'),
                      ),
                      ElevatedButton(
                        onPressed: _order.orderStatus == 'preparing'
                            ? null
                            : () => _updateStatus('preparing'),
                        child: const Text('Prepare'),
                      ),
                      ElevatedButton(
                        onPressed: _order.orderStatus == 'ready'
                            ? null
                            : () => _updateStatus('ready'),
                        child: const Text('Ready'),
                      ),
                      ElevatedButton(
                        onPressed: _order.orderStatus == 'completed'
                            ? null
                            : () => _updateStatus('completed'),
                        child: const Text('Complete'),
                      ),
                      ElevatedButton(
                        onPressed: _order.orderStatus == 'cancelled'
                            ? null
                            : () => _updateStatus('cancelled'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
