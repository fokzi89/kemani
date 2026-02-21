import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, 'Sales Overview'),
            _buildSalesChart(context),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Top Selling Products'),
            _buildTopProductsList(context),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Delivery Performance'),
            _buildDeliveryChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context) {
    // Placeholder data for a LineChart
    final List<FlSpot> spots = [
      const FlSpot(0, 3),
      const FlSpot(1, 5),
      const FlSpot(2, 3.5),
      const FlSpot(3, 4.5),
      const FlSpot(4, 1),
      const FlSpot(5, 6),
      const FlSpot(6, 6.5),
      const FlSpot(7, 6),
      const FlSpot(8, 4),
      const FlSpot(9, 6),
      const FlSpot(10, 6),
      const FlSpot(11, 7),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 4,
                  color: Theme.of(context).primaryColor,
                  belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopProductsList(BuildContext context) {
    // Placeholder for a list of top products
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5, // Example: Top 5 products
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('Product Name ${index + 1}'),
            trailing: const Text('\$123.45'), // Placeholder sales
          );
        },
      ),
    );
  }

  Widget _buildDeliveryChart(BuildContext context) {
    // Placeholder data for a PieChart
    final List<PieChartSectionData> pieChartSections = [
      PieChartSectionData(
        color: Colors.green,
        value: 40,
        title: 'Delivered (40%)',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: 30,
        title: 'In Progress (30%)',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: 10,
        title: 'Cancelled (10%)',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.blueGrey,
        value: 20,
        title: 'Pending (20%)',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: pieChartSections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }
}
