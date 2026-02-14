import 'package:flutter/material.dart';
import 'navigation_items.dart';
import '../../theme.dart';

class MobileNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const MobileNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    // For mobile, we might want to show fewer items or use a 'More' tab
    // Standard bottom nav ideally has 3-5 items.
    // We have 7 items. So we should probably show: Dashboard, POS, Orders, Products, Menu (More)

    final primaryItems = NavigationItems.items.take(4).toList();

    return NavigationBar(
      selectedIndex: selectedIndex > 3 ? 4 : selectedIndex,
      onDestinationSelected: (index) {
        if (index == 4) {
          // Open More Menu / Drawer
          Scaffold.of(context).openEndDrawer();
        } else {
          onDestinationSelected(index);
        }
      },
      destinations: [
        ...primaryItems.map(
          (item) => NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
        ),
        const NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
      ],
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : AppColors.lightCard,
      elevation: 2,
    );
  }
}
