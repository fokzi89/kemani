import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/theme_provider.dart';

import 'navigation_items.dart';

class CollapsibleNavRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;

  const CollapsibleNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onLogout,
  });

  @override
  State<CollapsibleNavRail> createState() => _CollapsibleNavRailState();
}

class _CollapsibleNavRailState extends State<CollapsibleNavRail> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final destinations = NavigationItems.items;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isCollapsed ? 72 : 240,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header / Logo Area
          SizedBox(
            height: 64,
            child: Center(
              child: widget.isCollapsed
                  ? const Icon(Icons.store, size: 32) // Mini Logo
                  : Text(
                      'Kemani',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
          ),
          const Divider(height: 1),

          // Navigation Items
          Expanded(
            child: ListView.separated(
              itemCount: destinations.length,
              padding: const EdgeInsets.symmetric(vertical: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected = widget.selectedIndex == index;

                return _NavTile(
                  icon: isSelected ? item.selectedIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  isCollapsed: widget.isCollapsed,
                  onTap: () => widget.onDestinationSelected(index),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Collapse Toggle, Theme Toggle & Logout
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _NavTile(
                  icon: widget.isCollapsed
                      ? Icons.chevron_right
                      : Icons.chevron_left,
                  label: 'Collapse',
                  isSelected: false,
                  isCollapsed: widget.isCollapsed,
                  onTap: widget.onToggleCollapse,
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final themeProvider = Provider.of<ThemeProvider>(context);
                    return _NavTile(
                      icon: themeProvider.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: themeProvider.isDarkMode
                          ? 'Light Mode'
                          : 'Dark Mode',
                      isSelected: false,
                      isCollapsed: widget.isCollapsed,
                      onTap: () => themeProvider.toggleTheme(),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _NavTile(
                  icon: Icons.logout,
                  label: 'Logout',
                  isSelected: false,
                  isCollapsed: widget.isCollapsed,
                  onTap: widget.onLogout,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final bool isDestructive;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = theme.colorScheme.primary;
    final activeBg = theme.colorScheme.primary.withOpacity(0.1);
    final inactiveColor = isDestructive
        ? theme.colorScheme.error
        : (isDark
              ? AppColors.darkMutedForeground
              : AppColors.lightMutedForeground);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
