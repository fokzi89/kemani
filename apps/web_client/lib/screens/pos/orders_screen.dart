import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart'; // Removed to avoid missing dependency
import '../../providers/tenant_provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';

final orderServiceProvider = Provider((ref) => OrderService());

final ordersStreamProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  final tenantAsync = ref.watch(tenantProvider);
  if (!tenantAsync.hasValue || tenantAsync.value?.tenant == null) {
    return const Stream.empty();
  }

  final tenantId = tenantAsync.value!.tenant!.id;
  return ref.watch(orderServiceProvider).watchOrders(tenantId);
});

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text('Order #${order.orderNumber}'),
                  subtitle: Text(
                    '${_formatDate(order.createdAt)} • ${order.status.name.toUpperCase()}',
                  ),
                  trailing: Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer ID: ${order.customerId}'),
                          Text(
                            'Payment: ${order.paymentStatus.name.toUpperCase()}',
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Navigate to order details
                              },
                              child: const Text('View Full Details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
