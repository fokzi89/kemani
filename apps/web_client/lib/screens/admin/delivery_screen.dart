import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tenant_provider.dart';
import '../../services/delivery_service.dart';
import '../../models/delivery.dart';

// Provider for DeliveryService
final deliveryServiceProvider = Provider((ref) => DeliveryService());

// Provider for watching deliveries
final deliveriesStreamProvider = StreamProvider.autoDispose<List<Delivery>>((
  ref,
) {
  final tenantAsync = ref.watch(tenantProvider);
  if (!tenantAsync.hasValue || tenantAsync.value?.tenant == null) {
    return const Stream.empty();
  }

  final tenantId = tenantAsync.value!.tenant!.id;
  return ref.watch(deliveryServiceProvider).watchDeliveries(tenantId);
});

class DeliveryScreen extends ConsumerWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigation to manual delivery creation or order selection
              // For now just a placeholder
            },
          ),
        ],
      ),
      body: deliveriesAsync.when(
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return const Center(child: Text('No active deliveries'));
          }
          return ListView.builder(
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_shipping),
                  ),
                  title: Text(delivery.address),
                  subtitle: Text(
                    'Order #${delivery.orderId.substring(0, 8)}... \nStatus: ${delivery.status.name.toUpperCase()}',
                  ),
                  isThreeLine: true,
                  trailing: delivery.driverName != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person, size: 20),
                            Text(
                              delivery.driverName!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        )
                      : const Chip(
                          label: Text('Unassigned'),
                          visualDensity: VisualDensity.compact,
                        ),
                  onTap: () {
                    // TODO: Navigate to delivery details/edit
                  },
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
