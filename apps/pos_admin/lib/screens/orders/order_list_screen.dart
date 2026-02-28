import 'package:flutter/material.dart';
import 'package:pos_admin/models/order.dart';
import 'package:pos_admin/services/order_service.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  List<Order> _orders = [];
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      _orders = await _orderService.listOrders(
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching orders: $e')));
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
        title: const Text('Orders'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String result) {
              setState(() {
                _statusFilter = result == 'all' ? '' : result;
              });
              _fetchOrders();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'all', child: Text('All')),
              const PopupMenuItem<String>(
                  value: 'pending', child: Text('Pending')),
              const PopupMenuItem<String>(
                  value: 'confirmed', child: Text('Confirmed')),
              const PopupMenuItem<String>(
                  value: 'completed', child: Text('Completed')),
              const PopupMenuItem<String>(
                  value: 'cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders found.'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.receipt)),
                        title: Text('Order #${order.orderNumber}'),
                        subtitle: Text(
                            'Status: ${order.orderStatus.toUpperCase()} \nTotal: \$${order.totalAmount.toStringAsFixed(2)}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailScreen(order: order),
                            ),
                          ).then((_) => _fetchOrders());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
