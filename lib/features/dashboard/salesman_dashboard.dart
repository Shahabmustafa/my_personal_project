import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../branch/sale_exchange/presentation/screens/sale_exchange_invoice_picker_screen.dart';
import '../branch/sale_invoice/presentation/screens/sale_invoice_screen.dart';
import '../branch/sale_return/presentation/screens/sale_return_screen.dart';
import '../salesman/dashboard/presentation/screens/salesman_overview_screen.dart';
import '../salesman/my_activity/presentation/screens/my_exchanges_screen.dart';
import '../salesman/my_activity/presentation/screens/my_returns_screen.dart';
import '../salesman/my_activity/presentation/screens/my_sales_screen.dart';
import '../salesman/profile/presentation/screens/salesman_profile_screen.dart';

import 'package:safishoe_app/core/constants/app_icons.dart';

/// Salesman ka apna, restricted dashboard — branch-admin screens (Employees,
/// Customers, Stock, Cash Counter, Expense, Reports) yahan nahi hain, sirf
/// apni sale/return/exchange banane aur apni history + profile dekhne ka
/// access hai.
class SalesmanDashboard extends ConsumerStatefulWidget {
  const SalesmanDashboard({super.key});

  @override
  ConsumerState<SalesmanDashboard> createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends ConsumerState<SalesmanDashboard> {
  int _index = 0;

  static const _navItems = [
    SidebarItem(icon: AppIcons.dashboardOutlined, label: 'Dashboard'),
    SidebarItem(
        icon: AppIcons.shoppingCartCheckoutOutlined,
        label: 'New Sale',
        group: 'Sales'),
    SidebarItem(
        icon: AppIcons.assignmentReturnOutlined,
        label: 'Sale Return',
        group: 'Sales'),
    SidebarItem(
        icon: AppIcons.swapHorizOutlined,
        label: 'Sale Exchange',
        group: 'Sales'),
    SidebarItem(
        icon: AppIcons.receiptLongOutlined,
        label: 'My Sales',
        group: 'My Activity'),
    SidebarItem(
        icon: AppIcons.assignmentReturnOutlined,
        label: 'My Returns',
        group: 'My Activity'),
    SidebarItem(
        icon: AppIcons.swapHorizOutlined,
        label: 'My Exchanges',
        group: 'My Activity'),
    SidebarItem(icon: AppIcons.personOutline, label: 'My Profile'),
  ];

  static const _pages = [
    SalesmanOverviewScreen(),
    SaleInvoiceScreen(),
    SaleReturnScreen(),
    SaleExchangeInvoicePickerScreen(),
    MySalesScreen(),
    MyReturnsScreen(),
    MyExchangesScreen(),
    SalesmanProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return SidebarShell(
      navItems: _navItems,
      pages: _pages,
      selectedIndex: _index,
      userName: user?.username ?? '',
      userRole: user?.roleDisplayName ?? '',
      onSelect: (i) => setState(() => _index = i),
      onLogout: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
    );
  }
}
