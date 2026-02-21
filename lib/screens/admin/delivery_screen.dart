import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/delivery.dart';
import '../../services/delivery_service.dart';

class DeliveryScreen extends ConsumerWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryList = ref.watch(deliveryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Management'),
      ),
      body: deliveryList.isEmpty
          ? const Center(child: Text('No deliveries found.'))
          : ListView.builder(
              itemCount: deliveryList.length,
              itemBuilder: (context, index) {
                final delivery = deliveryList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text('Order ID: ${delivery.orderId}'),
                    subtitle: Text('Status: ${delivery.status.name} ${delivery.riderId != null ? '- Rider: ${delivery.riderId}' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showDeliveryDialog(context, ref, delivery: delivery),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Delivery'),
                                content: Text('Are you sure you want to delete delivery for Order ID: ${delivery.orderId}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(deliveryListProvider.notifier).deleteDelivery(delivery.id);
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
        onPressed: () => _showDeliveryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeliveryDialog(BuildContext context, WidgetRef ref, {Delivery? delivery}) {
    final TextEditingController orderIdController = TextEditingController(text: delivery?.orderId);
    final TextEditingController riderIdController = TextEditingController(text: delivery?.riderId);
    DeliveryStatus? selectedStatus = delivery?.status ?? DeliveryStatus.pending;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(delivery == null ? 'Add New Delivery' : 'Edit Delivery'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: orderIdController,
                decoration: const InputDecoration(labelText: 'Order ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an Order ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: riderIdController,
                decoration: const InputDecoration(labelText: 'Rider ID (Optional)'),
              ),
              DropdownButtonFormField<DeliveryStatus>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Delivery Status'),
                items: DeliveryStatus.values
                    .map((status) => DropdownMenuItem(value: status, child: Text(status.name)))
                    .toList(),
                onChanged: (DeliveryStatus? newValue) {
                  selectedStatus = newValue;
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a status';
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
                final newDelivery = Delivery(
                  id: delivery?.id ?? const Uuid().v4(),
                  orderId: orderIdController.text,
                  riderId: riderIdController.text.isEmpty ? null : riderIdController.text,
                  status: selectedStatus!,
                  // pickupTime: ...
                  // deliveryTime: ...
                );

                if (delivery == null) {
                  await ref.read(deliveryListProvider.notifier).addDelivery(newDelivery);
                } else {
                  await ref.read(deliveryListProvider.notifier).updateDelivery(newDelivery);
                }

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(delivery == null ? 'Delivery added!' : 'Delivery updated!')),
                );
              }
            },
            child: Text(delivery == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}
