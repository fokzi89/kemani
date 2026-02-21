import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/tenant_provider.dart';
import '../../services/transaction_service.dart';
import '../../models/sale.dart';

// Provider for TransactionService (Sales)
final salesReportProvider = FutureProvider.autoDispose<List<Sale>>((ref) async {
  final tenantAsync = ref.watch(tenantProvider);
  if (!tenantAsync.hasValue || tenantAsync.value?.tenant == null) {
    return [];
  }

  final tenantId = tenantAsync.value!.tenant!.id;
  // TODO: Add date range filtering to service method
  return ref.read(transactionServiceProvider).getSales(tenantId);
});

final transactionServiceProvider = Provider((ref) => TransactionService());

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final newRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (newRange != null) {
                setState(() {
                  _selectedDateRange = newRange;
                });
                // TODO: Trigger re-fetch with date filter
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implement PDF report export
            },
          ),
        ],
      ),
      body: salesAsync.when(
        data: (sales) {
          // Filter locally if range selected
          var filteredSales = sales;
          if (_selectedDateRange != null) {
            filteredSales = sales.where((sale) {
              if (sale.createdAt == null) return false;
              return sale.createdAt!.isAfter(_selectedDateRange!.start) &&
                  sale.createdAt!.isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1)),
                  );
            }).toList();
          }

          if (filteredSales.isEmpty) {
            return const Center(
              child: Text('No sales found for selected period'),
            );
          }

          final totalAmount = filteredSales.fold<double>(
            0,
            (sum, sale) => sum + sale.totalAmount,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Sales:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredSales.length,
                  itemBuilder: (context, index) {
                    final sale = filteredSales[index];
                    return ListTile(
                      title: Text('Sale #${sale.saleNumber}'),
                      subtitle: Text(
                        DateFormat.yMMMd().add_jm().format(
                          sale.createdAt ?? DateTime.now(),
                        ),
                      ),
                      trailing: Text(
                        '\$${sale.totalAmount.toStringAsFixed(2)}',
                      ),
                      onTap: () {
                        // View sale details
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
