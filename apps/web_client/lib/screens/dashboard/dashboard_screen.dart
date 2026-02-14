import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../../widgets/navigation/responsive_shell.dart';
import 'pos/pos_screen.dart';
import 'staff/staff_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    Center(child: Text('Dashboard Overview')),
    POSScreen(),
    Center(child: Text('Orders Management')),
    Center(child: Text('Product Inventory')),
    Center(child: Text('Customer Management')),
    StaffManagementScreen(),
    Center(child: Text('Settings')),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ResponsiveShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      onLogout: _handleLogout,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kemani POS'),
          actions: [
            // Theme toggle
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              tooltip: themeProvider.isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              onPressed: () => themeProvider.toggleTheme(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: _screens[_selectedIndex],
      ),
    );
  }
}
