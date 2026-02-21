import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../widgets/navigation/responsive_shell.dart';
import 'pos/pos_screen.dart';
import 'orders/orders_screen.dart';
import 'staff/staff_management_screen.dart';
import 'products/product_inventory_screen.dart';
import 'overview/dashboard_overview_screen.dart';
import 'customers/customer_management_screen.dart';
import 'settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardOverviewScreen(),
    POSScreen(),
    OrdersScreen(),
    ProductInventoryScreen(),
    CustomerManagementScreen(),
    StaffManagementScreen(),
    SettingsScreen(),
  ];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _handleLogout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      onLogout: _handleLogout,
      child: _screens[_selectedIndex],
    );
  }
}
