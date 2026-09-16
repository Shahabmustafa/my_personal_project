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
import '../superadmin/report/presentation/screens/branch_target_report_screen.dart';
import '../superadmin/report/presentation/screens/sale_summary_report_screen.dart';

import 'package:safishoe_app/core/constants/app_icons.dart';
// Roles: cashier, manager (salesman ke liye alag SalesmanDashboard hai)

class BranchDashboard extends ConsumerStatefulWidget {
  const BranchDashboard({super.key});

  @override
  ConsumerState<BranchDashboard> createState() => _BranchDashboardState();
}

class _BranchDashboardState extends ConsumerState<BranchDashboard> {
  int _index = 0;

  static const _navItems = [
    SidebarItem(icon: AppIcons.dashboardOutlined, label: 'Dashboard'),
    SidebarItem(icon: AppIcons.badgeOutlined, label: 'Employees'),
    SidebarItem(icon: AppIcons.apartmentOutlined, label: 'Customers'),
    SidebarItem(
        icon: AppIcons.apartmentOutlined,
        label: 'Assign Stock My Branch',
        group: 'Assign Stock'),
    SidebarItem(
        icon: AppIcons.compareArrowsOutlined,
        label: 'Assign Stock to Other Branch',
        group: 'Assign Stock'),
    SidebarItem(
        icon: AppIcons.assignmentReturnOutlined,
        label: 'Return to Other Branch',
        group: 'Stock Returns'),
    SidebarItem(
        icon: AppIcons.moveToInboxOutlined,
        label: 'Incoming Stock Returns',
        group: 'Stock Returns'),
    SidebarItem(
        icon: AppIcons.warehouseOutlined,
        label: 'Return to Admin',
        group: 'Stock Returns'),
    SidebarItem(icon: AppIcons.apartmentOutlined, label: 'Stock Inventory'),
    SidebarItem(icon: AppIcons.pointOfSaleOutlined, label: 'Cash Counter'),
    SidebarItem(icon: AppIcons.receiptLongOutlined, label: 'Expense'),
    SidebarItem(
        icon: AppIcons.shoppingCartCheckoutOutlined,
        label: 'Sale Invoice',
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
        icon: AppIcons.listAlt,
        label: 'Sale Summary',
        group: 'Reports'),
    SidebarItem(
        icon: AppIcons.trendingUpOutlined,
        label: 'My Target',
        group: 'Reports'),
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
    SaleSummaryReportScreen(restrictToOwnBranch: true),
    BranchTargetReportScreen(restrictToOwnBranch: true),
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
