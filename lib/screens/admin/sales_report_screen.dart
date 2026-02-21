import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming you might have a SalesService or similar to fetch sales data
// import '../../services/sales_service.dart';
// import '../../models/sale.dart';

class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder for fetching sales data
    // final salesData = ref.watch(salesReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Range Picker (Placeholder)
            _buildDateRangePicker(context),
            const SizedBox(height: 20),

            // Summary Statistics (Placeholder)
            _buildSummaryStatistics(context),
            const SizedBox(height: 20),

            // Sales Table (Placeholder)
            _buildSalesTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Date Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement date picker
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('From: Jan 1, 2023'), // Placeholder
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement date picker
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('To: Dec 31, 2023'), // Placeholder
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatistics(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _buildStatRow(context, 'Total Sales:', '\$15,000.00'),
            _buildStatRow(context, 'Total Orders:', '120'),
            _buildStatRow(context, 'Average Order Value:', '\$125.00'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSalesTable(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detailed Sales Data', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Order ID')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Amount')),
                ],
                rows: List<DataRow>.generate(
                  10, // Placeholder rows
                  (index) => DataRow(
                    cells: [
                      DataCell(Text('2023-0${index + 1}-15')),
                      DataCell(Text('ORD-${1000 + index}')),
                      DataCell(Text('Customer ${index + 1}')),
                      DataCell(Text('\$${(100 + index * 10).toStringAsFixed(2)}')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
