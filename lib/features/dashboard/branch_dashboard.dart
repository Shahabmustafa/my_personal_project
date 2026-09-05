import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../branch/assign_stock_to_my_branch/presentation/screen/branch_assign_list_screen.dart';
import '../branch/assign_stock_to_other_branch/presentation/screens/branch_transfer_screen.dart';
import '../branch/branch_cash_counter/presentation/screens/branch_cash_counter_screen.dart';
import '../branch/branch_stock_inventory/presentation/screen/branch_stock_screen.dart';
import '../branch/customer/presentation/screens/customers_screen.dart';
import '../branch/dashboard/presentation/screen/branch_overview_screen.dart';
import '../branch/employee/presentation/screens/branch_employee_screen.dart';
import '../branch/expense/presentation/screen/expense_screen.dart';
import '../branch/return_stock_to_other_branch/presentation/screens/branch_stock_return_screen.dart';
import '../branch/return_stock_to_other_branch/presentation/screens/incoming_stock_returns_screen.dart';
import '../branch/return_stock_to_warehouse/presentation/screens/branch_warehouse_return_screen.dart';
import '../branch/sale_exchange/presentation/screens/sale_exchange_invoice_picker_screen.dart';
import '../branch/sale_invoice/presentation/screens/sale_invoice_screen.dart';
import '../branch/sale_return/presentation/screens/sale_return_screen.dart';

// Roles: cashier, manager, salesman

class BranchDashboard extends ConsumerStatefulWidget {
  const BranchDashboard({super.key});

  @override
  ConsumerState<BranchDashboard> createState() => _BranchDashboardState();
}

class _BranchDashboardState extends ConsumerState<BranchDashboard> {
  int _index = 0;

  static const _navItems = [
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    SidebarItem(icon: Icons.badge_outlined, label: 'Employees'),
    SidebarItem(icon: Icons.apartment_outlined, label: 'Customers'),
    SidebarItem(
        icon: Icons.apartment_outlined,
        label: 'Assign Stock My Branch',
        group: 'Assign Stock'),
    SidebarItem(
        icon: Icons.compare_arrows_outlined,
        label: 'Assign Stock to Other Branch',
        group: 'Assign Stock'),
    SidebarItem(
        icon: Icons.assignment_return_outlined,
        label: 'Return to Other Branch',
        group: 'Stock Returns'),
    SidebarItem(
        icon: Icons.move_to_inbox_outlined,
        label: 'Incoming Stock Returns',
        group: 'Stock Returns'),
    SidebarItem(
        icon: Icons.warehouse_outlined,
        label: 'Return to Warehouse',
        group: 'Stock Returns'),
    SidebarItem(icon: Icons.apartment_outlined, label: 'Stock Inventory'),
    SidebarItem(icon: Icons.point_of_sale_outlined, label: 'Cash Counter'),
    SidebarItem(icon: Icons.receipt_long_outlined, label: 'Expense'),
    SidebarItem(
        icon: Icons.shopping_cart_checkout_outlined,
        label: 'Sale Invoice',
        group: 'Sales'),
    SidebarItem(
        icon: Icons.assignment_return_outlined,
        label: 'Sale Return',
        group: 'Sales'),
    SidebarItem(
        icon: Icons.swap_horiz_outlined,
        label: 'Sale Exchange',
        group: 'Sales'),
  ];

  static const _pages = [
    BranchOverviewScreen(),
    BranchEmployeeScreen(),
    CustomersScreen(),
    BranchAssignListScreen(),
    BranchTransferScreen(),
    BranchStockReturnScreen(),
    IncomingStockReturnsScreen(),
    BranchWarehouseReturnScreen(),
    BranchStockScreen(),
    BranchCashCounterScreen(),
    ExpenseScreen(),
    SaleInvoiceScreen(),
    SaleReturnScreen(),
    SaleExchangeInvoicePickerScreen(),
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
      onLogout: () async{
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
