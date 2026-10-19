import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/dashboard/shortcuts_screen.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../branch/assign_stock_to_my_branch/presentation/provider/branch_assign_provider.dart';
import '../branch/assign_stock_to_my_branch/presentation/provider/incoming_assignment_provider.dart';
import '../branch/assign_stock_to_my_branch/presentation/screen/branch_assign_list_screen.dart';
import '../branch/attendance/presentation/screens/my_attendance_screen.dart';
import '../branch/attendance/presentation/screens/staff_attendance_screen.dart';
import '../branch/assign_stock_to_other_branch/presentation/screens/branch_transfer_screen.dart';
import '../branch/branch_cash_counter/presentation/screens/branch_cash_counter_screen.dart';
import '../branch/branch_payment/presentation/screens/branch_payments_history_screen.dart';
import '../branch/branch_stock_inventory/presentation/screen/branch_stock_screen.dart';
import '../branch/customer/presentation/screens/customers_screen.dart';
import '../branch/dashboard/presentation/screen/branch_overview_screen.dart';
import '../branch/employee/presentation/screens/branch_employee_screen.dart';
import '../branch/expense/presentation/screen/expense_screen.dart';
import '../branch/return_stock_to_other_branch/presentation/screens/branch_stock_return_screen.dart';
import '../branch/return_stock_to_other_branch/presentation/screens/incoming_stock_returns_screen.dart';
import '../branch/return_stock_to_warehouse/presentation/screens/branch_warehouse_return_screen.dart';
import '../branch/sale_claim/presentation/screens/sale_claims_screen.dart';
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
    SidebarItem(
      icon: AppIcons.dashboardOutlined,
      label: 'Dashboard',
      shortcut: '0',
    ),
    SidebarItem(
      icon: AppIcons.badgeOutlined,
      label: 'Employees',
      shortcut: 'M',
    ),
    SidebarItem(
      icon: AppIcons.apartmentOutlined,
      label: 'Customers',
      shortcut: 'C',
    ),
    SidebarItem(
      icon: AppIcons.shoppingCartCheckoutOutlined,
      label: 'Sale Invoice',
      shortcut: 'S',
      group: 'Sales',
    ),
    SidebarItem(
      icon: AppIcons.assignmentReturnOutlined,
      label: 'Sale Return',
      shortcut: 'R',
      group: 'Sales',
    ),
    SidebarItem(
      icon: AppIcons.swapHorizOutlined,
      label: 'Sale Exchange',
      shortcut: 'X',
      group: 'Sales',
    ),
    SidebarItem(
      icon: AppIcons.warningAmberOutlined,
      label: 'Sale Claim',
      shortcut: 'L',
      group: 'Sales',
    ),
    SidebarItem(
      icon: AppIcons.pointOfSaleOutlined,
      label: 'Cash Counter',
      shortcut: 'K',
    ),
    SidebarItem(
      icon: AppIcons.apartmentOutlined,
      label: 'Assign Stock My Branch',
      shortcut: 'A',
      group: 'Assign Stock',
    ),
    SidebarItem(
      icon: AppIcons.compareArrowsOutlined,
      label: 'Assign Stock to Other Branch',
      shortcut: 'T',
      group: 'Assign Stock',
    ),
    SidebarItem(
      icon: AppIcons.assignmentReturnOutlined,
      label: 'Return to Other Branch',
      shortcut: 'O',
      group: 'Stock Returns',
    ),
    SidebarItem(
      icon: AppIcons.moveToInboxOutlined,
      label: 'Incoming Stock Returns',
      shortcut: 'I',
      group: 'Stock Returns',
    ),
    SidebarItem(
      icon: AppIcons.warehouseOutlined,
      label: 'Return to Admin',
      shortcut: 'U',
      group: 'Stock Returns',
    ),
    SidebarItem(
      icon: AppIcons.apartmentOutlined,
      label: 'Stock Inventory',
      shortcut: 'V',
    ),
    SidebarItem(
      icon: AppIcons.paymentsOutlined,
      label: 'Branch Payments',
      shortcut: 'P',
    ),
    SidebarItem(
      icon: AppIcons.receiptLongOutlined,
      label: 'Expense',
      shortcut: 'N',
    ),
    SidebarItem(
      icon: AppIcons.listAlt,
      label: 'Sale Summary',
      shortcut: 'Y',
      group: 'Reports',
    ),
    SidebarItem(
      icon: AppIcons.trendingUpOutlined,
      label: 'My Target',
      shortcut: 'G',
      group: 'Reports',
    ),
    SidebarItem(
      icon: AppIcons.accessTimeOutlined,
      label: 'My Attendance',
      shortcut: 'W',
      group: 'Attendance',
    ),
    SidebarItem(
      icon: AppIcons.peopleOutline,
      label: 'Staff Attendance',
      shortcut: 'Shift+W',
      group: 'Attendance',
    ),
  ];

  static const _assignLabel = 'Assign Stock My Branch';

  void _showAssignmentNotification(
    BuildContext context,
    String number,
    int assignIndex,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 420,
        duration: const Duration(seconds: 8),
        backgroundColor: const Color(0xFF1F2333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFF8ED4AA),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New stock assigned',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (number.isNotEmpty)
                    Text(
                      'Assignment $number — accept or reject',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB8BDD0),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        action: assignIndex < 0
            ? null
            : SnackBarAction(
                label: 'View',
                textColor: const Color(0xFF8ED4AA),
                onPressed: () => setState(() => _index = assignIndex),
              ),
      ),
    );
  }

  /// Sirf manager (aur supervisor) poori branch ki attendance dekhta hai.
  static const _managerOnly = {'Staff Attendance'};

  static const _shortcutsItem = SidebarItem(
    icon: AppIcons.infoOutline,
    label: 'Keyboard Shortcuts',
    shortcut: 'Shift+H',
  );

  static const _pages = [
    BranchOverviewScreen(),
    BranchEmployeeScreen(),
    CustomersScreen(),
    SaleInvoiceScreen(),
    SaleReturnScreen(),
    SaleExchangeInvoicePickerScreen(),
    SaleClaimsScreen(),
    BranchCashCounterScreen(),
    BranchAssignListScreen(),
    BranchTransferScreen(),
    BranchStockReturnScreen(),
    IncomingStockReturnsScreen(),
    BranchWarehouseReturnScreen(),
    BranchStockScreen(),
    BranchPaymentsHistoryScreen(),
    ExpenseScreen(),
    SaleSummaryReportScreen(restrictToOwnBranch: true),
    BranchTargetReportScreen(restrictToOwnBranch: true),
    MyAttendanceScreen(),
    StaffAttendanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final canSeeStaff = user != null && (user.isManager || user.isSupervisor);
    final visible = [
      for (var i = 0; i < _navItems.length; i++)
        if (canSeeStaff || !_managerOnly.contains(_navItems[i].label)) i,
    ];
    final assignIndex = visible.indexWhere(
      (i) => _navItems[i].label == _assignLabel,
    );

    // Realtime — naya stock assign hote hi notification.
    ref.listen(incomingAssignmentProvider, (_, next) {
      final number = next.value;
      if (number == null) return;
      _showAssignmentNotification(context, number, assignIndex);
    });

    // Accept/reject ka intezar karne wale assignments — sidebar badge.
    final pendingAssignments = ref
        .watch(branchAssignProvider)
        .assignments
        .where((a) => a.status == 'pending')
        .length;

    final navItems = [
      for (final i in visible)
        _navItems[i].label == _assignLabel
            ? _navItems[i].withBadge(pendingAssignments)
            : _navItems[i],
    ];
    return SidebarShell(
      navItems: [...navItems, _shortcutsItem],
      pages: [
        for (final i in visible) _pages[i],
        ShortcutsScreen(items: navItems),
      ],
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
