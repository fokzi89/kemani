import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../services/transaction_service.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/auth_provider.dart';
import 'payment_selector.dart';

// Provider for TransactionService (stateless, so simple provider)
final transactionServiceProvider = Provider((ref) => TransactionService());

class CartDrawer extends ConsumerStatefulWidget {
  const CartDrawer({super.key});

  @override
  ConsumerState<CartDrawer> createState() => _CartDrawerState();
}

class _CartDrawerState extends ConsumerState<CartDrawer> {
  String _selectedPaymentMethod = 'cash';
  bool _isProcessing = false;

  Future<void> _processCheckout() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final tenantState = ref.read(tenantProvider).value;
      final authState = ref.read(authProvider);

      if (tenantState?.tenant?.id == null)
        throw Exception('Tenant context missing');
      if (authState.user == null) throw Exception('User not logged in');

      // Process Sale (Offline First)
      await ref
          .read(transactionServiceProvider)
          .processSale(
            items: cartState.items,
            tenantId: tenantState!.tenant!.id,
            cashierId: authState.user!.id,
            paymentMethod: _selectedPaymentMethod,
            branchId: tenantState.profile?.branchId,
            // TODO: customerId
          );

      // Clear Cart
      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        Navigator.pop(context); // Close drawer
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale Processed Successfully!')),
        );
        // Navigate to receipt screen if needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Drawer(
      width: 400, // Wide drawer for desktop/tablet POS
      child: Column(
        children: [
          AppBar(
            title: const Text('Current Sale'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(cartProvider.notifier).clear(),
              ),
            ],
          ),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Cart is empty'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '@ \$${item.product.sellingPrice.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  item.product.id,
                                  item.quantity - 1,
                                ),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .addItem(item.product),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${cart.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PaymentMethodSelector(
                  selectedMethod: _selectedPaymentMethod,
                  onMethodSelected: (val) =>
                      setState(() => _selectedPaymentMethod = val),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (cart.items.isEmpty || _isProcessing)
                        ? null
                        : _processCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Checkout',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
