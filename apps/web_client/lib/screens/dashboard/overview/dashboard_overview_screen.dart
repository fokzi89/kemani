import 'package:flutter/material.dart';
import '../../../services/sale_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme.dart';

class DashboardOverviewScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const DashboardOverviewScreen({super.key, this.onNavigate});

  @override
  State<DashboardOverviewScreen> createState() =>
      _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  final SaleService _saleService = SaleService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _recentSales = [];
  bool _isLoading = true;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = _authService.currentUser;
    if (user != null) {
      _userName = user.userMetadata?['full_name'] ?? 'User';
    }

    try {
      final sales = await _saleService.getSales(limit: 50);
      if (mounted) {
        setState(() {
          _recentSales = sales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate stats
    final totalRevenue = _recentSales
        .where((s) => s['status'] == 'completed')
        .fold(
          0.0,
          (sum, s) => sum + ((s['total_amount'] as num?)?.toDouble() ?? 0),
        );

    final salesCount = _recentSales
        .where((s) => s['status'] == 'completed')
        .length;

    final today = DateTime.now();
    final todaySales = _recentSales.where((s) {
      if (s['status'] != 'completed') return false;
      final dt = DateTime.parse(s['created_at']).toLocal();
      return dt.year == today.year &&
          dt.month == today.month &&
          dt.day == today.day;
    });

    final todayRevenue = todaySales.fold(
      0.0,
      (sum, s) => sum + ((s['total_amount'] as num?)?.toDouble() ?? 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Welcome back, $_userName 👋',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s what\'s happening with your store today.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.lightMutedForeground,
            ),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            childAspectRatio: 1.6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                title: 'Total Revenue',
                value: '₦${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.green,
                isDark: isDark,
              ),
              _StatCard(
                title: 'Total Sales',
                value: '$salesCount',
                icon: Icons.receipt_long,
                color: theme.colorScheme.primary,
                isDark: isDark,
              ),
              _StatCard(
                title: 'Today\'s Revenue',
                value: '₦${todayRevenue.toStringAsFixed(0)}',
                icon: Icons.trending_up,
                color: Colors.blue,
                isDark: isDark,
              ),
              _StatCard(
                title: 'Today\'s Sales',
                value: '${todaySales.length}',
                icon: Icons.today,
                color: Colors.orange,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Recent Activity Section
          Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_recentSales.isEmpty)
            _buildEmptyState(theme, isDark)
          else
            Card(
              elevation: 0,
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentSales.take(5).length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                itemBuilder: (context, index) {
                  final sale = _recentSales[index];
                  final amount =
                      (sale['total_amount'] as num?)?.toDouble() ?? 0;
                  final status = sale['status'] as String? ?? 'completed';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sale #${sale['sale_number'] ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _formatDate(sale['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.lightMutedForeground,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: status == 'completed'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.lightMutedForeground,
            ),
            const SizedBox(height: 12),
            const Text('No recent activity'),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return 'Today, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.lightMutedForeground,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
