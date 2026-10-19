import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/dashboard/shortcuts_screen.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';
import 'package:safishoe_app/features/superadmin/bank/presentation/screens/bank_entries_screen.dart';
import 'package:safishoe_app/features/superadmin/bank/presentation/screens/bank_heads_screen.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../branch/sale_claim/presentation/providers/sale_claim_provider.dart'
    show incomingSaleClaimsProvider;
import '../superadmin/sale_claims/presentation/screens/incoming_sale_claims_screen.dart';
import '../superadmin/branch/presentation/screens/branches_screen.dart';
import '../superadmin/branch_target/presentation/screens/branch_target_screen.dart';
import '../superadmin/discount/presentation/screens/branch_invoice_discount_screen.dart';
import '../superadmin/discount/presentation/screens/sale_discount_tiers_screen.dart';
import '../superadmin/discount/presentation/screens/b1g1_offers_screen.dart';
import '../superadmin/head_office/presentation/screens/head_office_screen.dart';
import '../superadmin/head_office_cash_counter/presentation/screens/head_office_cash_counter_screen.dart';
import '../superadmin/expense/presentation/screens/superadmin_expense_screen.dart';
import '../superadmin/incoming_branch_returns/presentation/screens/incoming_branch_returns_screen.dart';
import '../superadmin/branch_payments/presentation/screens/branch_payments_screen.dart';
import '../superadmin/printer/presentation/screens/assign_printer_screen.dart';
import '../superadmin/printer/presentation/screens/printer_heads_screen.dart';
import '../superadmin/employee_salary/presentation/screens/employee_salary_screen.dart';
import '../superadmin/report/presentation/screens/branch_target_report_screen.dart';
import '../superadmin/report/presentation/screens/employee_salary_report_screen.dart';
import '../branch/attendance/presentation/screens/attendance_machines_screen.dart';
import '../branch/attendance/presentation/screens/staff_attendance_screen.dart';
import '../superadmin/report/presentation/screens/sale_summary_report_screen.dart';
import '../superadmin/warehouse/presentation/screens/warehouse_screen.dart';
import '../warehouse/company/presentation/screens/companies_screen.dart';
import '../user/presentation/screens/users_screen.dart';
import '../warehouse/product/presentation/screens/products_screen.dart';
import '../warehouse/size/presentation/screens/sizes_screen.dart';
import '../warehouse/color/presentation/screens/colors_screen.dart';
import '../warehouse/brand/presentation/screens/brands_screen.dart';
import '../warehouse/category/presentation/screens/categorys_screen.dart';
import '../warehouse/type/presentation/screens/types_screen.dart';
import '../superadmin/head_office_stock/presentation/screens/head_office_stock_screen.dart';
import '../superadmin/head_office_assign_stock/presentation/screens/ho_assign_stock_screen.dart';
import '../superadmin/head_office_assign_stock/presentation/screens/ho_assign_stock_list_screen.dart';
import '../superadmin/overview/presentation/screens/overview_screen.dart';
import '../superadmin/head_office_purchase/presentation/screens/purchase_invoice_screen.dart';
import '../superadmin/head_office_purchase/presentation/screens/purchase_return_screen.dart';

import '../superadmin/report/presentation/screens/purchase_summary_report_screen.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
// Roles: superadmin, admin

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  int _index = 0;

  static const _navItems = [
    SidebarItem(
      icon: AppIcons.dashboardOutlined,
      label: 'Dashboard',
      shortcut: '0',
    ),
    SidebarItem(
      icon: AppIcons.businessOutlined,
      label: 'Head Office',
      shortcut: 'H',
    ),
    SidebarItem(
      icon: AppIcons.apartmentOutlined,
      label: 'Branches',
      shortcut: 'B',
    ),
    SidebarItem(
      icon: AppIcons.warehouseOutlined,
      label: 'Warehouse',
      shortcut: 'W',
    ),
    SidebarItem(icon: AppIcons.peopleOutline, label: 'Users', shortcut: 'U'),
    SidebarItem(
      icon: AppIcons.inventory2Outlined,
      label: 'Products',
      shortcut: 'P',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: AppIcons.formatSizeOutlined,
      label: 'Sizes',
      shortcut: 'Z',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: AppIcons.colorLensOutlined,
      label: 'Colors',
      shortcut: 'C',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: AppIcons.brandingWatermarkOutlined,
      label: 'Brands',
      shortcut: 'Shift+B',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: AppIcons.categoryOutlined,
      label: 'Categories',
      shortcut: 'G',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: AppIcons.styleOutlined,
      label: 'Types',
      shortcut: 'Y',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: AppIcons.warehouseOutlined,
      label: 'Stock Inventory',
      shortcut: 'V',
    ),
    SidebarItem(
      icon: AppIcons.receiptLongOutlined,
      label: 'Purchase Invoice',
      shortcut: 'I',
      group: 'Purchase',
    ),
    SidebarItem(
      icon: AppIcons.assignmentReturnOutlined,
      label: 'Purchase Return',
      shortcut: 'R',
      group: 'Purchase',
    ),
    SidebarItem(
      icon: AppIcons.storefrontOutlined,
      label: 'Company',
      shortcut: 'O',
    ),
    SidebarItem(
      icon: AppIcons.savingsOutlined,
      label: 'Head Office Cash Counter',
      shortcut: 'K',
    ),
    SidebarItem(
      icon: AppIcons.businessOutlined,
      label: 'Head Office Expense',
      shortcut: 'X',
      group: 'Expense',
    ),
    SidebarItem(
      icon: AppIcons.apartmentOutlined,
      label: 'Branch Expense',
      shortcut: 'Shift+X',
      group: 'Expense',
    ),
    SidebarItem(
      icon: AppIcons.paymentsOutlined,
      label: 'Branch Payments',
      shortcut: 'Shift+P',
    ),
    SidebarItem(
      icon: AppIcons.localShippingOutlined,
      label: 'Assign Stock To Branch',
      shortcut: 'A',
      group: 'Assign Stock',
    ),
    SidebarItem(
      icon: AppIcons.history,
      label: 'Assign Stock by Admin',
      shortcut: 'Shift+A',
      group: 'Assign Stock',
    ),
    SidebarItem(
      icon: AppIcons.history,
      label: 'Assign Stock by Branch',
      shortcut: 'T',
      group: 'Assign Stock',
    ),
    SidebarItem(
      icon: AppIcons.moveToInboxOutlined,
      label: 'Incoming Branch Returns',
      shortcut: 'Shift+I',
      group: 'Returns & Claims',
    ),
    SidebarItem(
      icon: AppIcons.warningAmberOutlined,
      label: 'Branch Sale Claims',
      shortcut: 'L',
      group: 'Returns & Claims',
    ),
    SidebarItem(
      icon: AppIcons.percentOutlined,
      label: 'Branch Invoice Discount',
      shortcut: 'J',
      group: 'Discount',
    ),
    SidebarItem(
      icon: AppIcons.sellOutlined,
      label: 'Sale Discount Tiers',
      shortcut: 'Shift+J',
      group: 'Discount',
    ),
    SidebarItem(
      icon: AppIcons.sellOutlined,
      label: 'Buy 1 Get 1',
      shortcut: '1',
      group: 'Discount',
    ),
    SidebarItem(
      icon: AppIcons.flagOutlined,
      label: 'Branch Target',
      shortcut: 'Q',
      group: 'Target',
    ),
    SidebarItem(
      icon: AppIcons.accountBalanceOutlined,
      label: 'Bank Head',
      shortcut: '2',
      group: 'Bank',
    ),
    SidebarItem(
      icon: AppIcons.accountBalanceWalletOutlined,
      label: 'Bank Entry',
      shortcut: '3',
      group: 'Bank',
    ),
    SidebarItem(
      icon: AppIcons.printOutlined,
      label: 'Print',
      shortcut: '4',
      group: 'Printer',
    ),
    SidebarItem(
      icon: AppIcons.localPrintshopOutlined,
      label: 'Assign Print',
      shortcut: '5',
      group: 'Printer',
    ),
    SidebarItem(
      icon: AppIcons.paymentsOutlined,
      label: 'Employee Salary',
      shortcut: 'M',
    ),
    SidebarItem(
      icon: AppIcons.listAlt,
      label: 'Sale Summary',
      shortcut: 'S',
      group: 'Reports',
    ),
    SidebarItem(
      icon: AppIcons.shoppingCartCheckoutOutlined,
      label: 'Purchase Summary',
      shortcut: 'Shift+S',
      group: 'Reports',
    ),
    SidebarItem(
      icon: AppIcons.trendingUpOutlined,
      label: 'Branch Target',
      shortcut: 'Shift+Q',
      group: 'Reports',
    ),
    SidebarItem(
      icon: AppIcons.paymentsOutlined,
      label: 'Employee Salary Report',
      shortcut: 'Shift+M',
      group: 'Reports',
    ),
    SidebarItem(
      icon: AppIcons.accessTimeOutlined,
      label: 'Staff Attendance',
      shortcut: 'N',
      group: 'Attendance',
    ),
    SidebarItem(
      icon: AppIcons.fingerprint,
      label: 'Attendance Machines',
      shortcut: 'Shift+N',
      group: 'Attendance',
    ),
  ];

  static const _shortcutsItem = SidebarItem(
    icon: AppIcons.infoOutline,
    label: 'Keyboard Shortcuts',
    shortcut: 'Shift+H',
  );

  static const _pages = [
    OverviewScreen(),
    HeadOfficeScreen(),
    BranchesScreen(),
    WarehouseScreen(),
    UsersScreen(),
    // Edit/delete allowed; delete is refused while stock still uses the row.
    ProductsScreen(),
    SizesScreen(showSizeGroups: true),
    ColorsScreen(),
    BrandsScreen(),
    CategorysScreen(),
    TypesScreen(),
    // Sab warehouses ka stock — add ho sakta hai, edit/delete nahi.
    HeadOfficeStockScreen(),
    // Admin ko pehle warehouse choose karni hoti hai (khud koi warehouse
    // assign nahi hoti), phir wahi invoice/return screens jo warehouse
    // dashboard mein hain.
    PurchaseInvoiceScreen(),
    PurchaseReturnScreen(),
    // Companies head-office se juri hain (system mein ek hi head office) —
    // koi warehouse choose karne ki zaroorat nahi.
    CompaniesScreen(),
    HeadOfficeCashCounterScreen(),
    // Head office ka apna expense.
    HeadOfficeExpenseScreen(),
    // Admin kisi bhi branch ka expense add/edit kar sakta hai.
    BranchExpenseScreen(),
    // Branches ne Head Office ko jo amount pay ki — accept/reject + report.
    BranchPaymentsScreen(),
    // Head office se branch ko stock assign — assigned_by = head office id.
    HoAssignStockScreen(),
    // Assignment history — head office ne jo stock branches ko diya.
    HoAssignStockListScreen(),
    // Branch → branch transfers ki history (sab branches).
    HoAssignStockListScreen(byBranch: true),
    // Branches se Admin (Head Office) ko jo stock returns aate hain — accept/reject.
    IncomingBranchReturnsScreen(),
    // Branches ke sale claims (kharab product) — approve par branch stock se minus.
    IncomingSaleClaimsScreen(),
    BranchInvoiceDiscountScreen(),
    SaleDiscountTiersScreen(),
    B1g1OffersScreen(),
    BranchTargetScreen(),
    BankHeadsScreen(),
    BankEntriesScreen(),
    PrinterHeadsScreen(),
    AssignPrinterScreen(),
    EmployeeSalaryScreen(),
    SaleSummaryReportScreen(),
    PurchaseSummaryReportScreen(),
    BranchTargetReportScreen(),
    EmployeeSalaryReportScreen(),
    StaffAttendanceScreen(allBranches: true),
    AttendanceMachinesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final pendingClaims =
        ref
            .watch(incomingSaleClaimsProvider)
            .value
            ?.where((c) => c.isPending)
            .length ??
        0;
    final navItems = [
      for (final item in _navItems)
        item.label == 'Branch Sale Claims'
            ? item.withBadge(pendingClaims)
            : item,
    ];
    return SidebarShell(
      navItems: [...navItems, _shortcutsItem],
      pages: [
        ..._pages,
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
