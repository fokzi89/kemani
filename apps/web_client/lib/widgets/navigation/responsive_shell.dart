import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/theme_provider.dart';
import 'collapsible_nav_rail.dart';
import 'mobile_nav_bar.dart';
import 'navigation_items.dart';

class ResponsiveShell extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;

  const ResponsiveShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  bool _isRailCollapsed = false;

  void _toggleRail() {
    setState(() => _isRailCollapsed = !_isRailCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder or specific width check
    // Tablet/Desktop breakpoint usually at 600 or 900.
    // POS likely needs more space, so let's say 800+ is desktop/tablet layout
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            CollapsibleNavRail(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
              isCollapsed: _isRailCollapsed,
              onToggleCollapse: _toggleRail,
              onLogout: widget.onLogout,
            ),

          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),

          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? MobileNavBar(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
            )
          : null,
      endDrawer: !isDesktop
          ? _MobileDrawer(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: (index) {
                Navigator.pop(context); // Close drawer
                widget.onDestinationSelected(index);
              },
              onLogout: widget.onLogout,
            )
          : null,
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;

  const _MobileDrawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = NavigationItems.items;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.store, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'Kemani POS',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              leading: Icon(
                selectedIndex == index ? item.selectedIcon : item.icon,
                color: selectedIndex == index
                    ? theme.colorScheme.primary
                    : null,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  color: selectedIndex == index
                      ? theme.colorScheme.primary
                      : null,
                  fontWeight: selectedIndex == index ? FontWeight.bold : null,
                ),
              ),
              selected: selectedIndex == index,
              onTap: () => onDestinationSelected(index),
            );
          }),
          const Divider(),
          Builder(
            builder: (context) {
              final themeProvider = Provider.of<ThemeProvider>(context);
              return ListTile(
                leading: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                title: Text(
                  themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                ),
                onTap: () => themeProvider.toggleTheme(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
