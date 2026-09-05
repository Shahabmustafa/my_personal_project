import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';
import 'package:safishoe_app/features/superadmin/bank/presentation/screens/bank_entries_screen.dart';
import 'package:safishoe_app/features/superadmin/bank/presentation/screens/bank_heads_screen.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../superadmin/branch/presentation/screens/branches_screen.dart';
import '../superadmin/discount/presentation/screens/branch_invoice_discount_screen.dart';
import '../superadmin/discount/presentation/screens/branch_stock_discount_screen.dart';
import '../superadmin/head_office/presentation/screens/head_office_screen.dart';
import '../superadmin/incoming_branch_returns/presentation/screens/incoming_branch_returns_screen.dart';
import '../superadmin/printer/presentation/screens/assign_printer_screen.dart';
import '../superadmin/printer/presentation/screens/printer_heads_screen.dart';
import '../superadmin/employee_salary/presentation/screens/employee_salary_screen.dart';
import '../superadmin/report/presentation/screens/sale_exchange_report_screen.dart';
import '../superadmin/report/presentation/screens/sale_invoice_report_screen.dart';
import '../superadmin/report/presentation/screens/sale_return_report_screen.dart';
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
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    SidebarItem(icon: Icons.apartment_outlined, label: 'Branches'),
    SidebarItem(icon: Icons.warehouse_outlined, label: 'Warehouse'),
    SidebarItem(icon: Icons.people_outline, label: 'Users'),
    SidebarItem(
      icon: Icons.inventory_2_outlined,
      label: 'Products',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: Icons.format_size_outlined,
      label: 'Sizes',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: Icons.color_lens_outlined,
      label: 'Colors',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: Icons.branding_watermark_outlined,
      label: 'Brands',
      group: 'Catalog',
    ),
    SidebarItem(
      icon: Icons.category_outlined,
      label: 'Categories',
      group: 'Catalog',
    ),
    SidebarItem(icon: Icons.style_outlined, label: 'Types', group: 'Catalog'),
    SidebarItem(icon: Icons.warehouse_outlined, label: 'Stock Inventory'),
    SidebarItem(
      icon: Icons.receipt_long_outlined,
      label: 'Purchase Invoice',
      group: 'Purchase',
    ),
    SidebarItem(
      icon: Icons.assignment_return_outlined,
      label: 'Purchase Return',
      group: 'Purchase',
    ),
    SidebarItem(icon: Icons.storefront_outlined, label: 'Company'),
    SidebarItem(
      icon: Icons.local_shipping_outlined,
      label: 'Assign Stock To Branch',
      group: 'Assign Stock',
    ),
    SidebarItem(icon: Icons.history, label: 'History', group: 'Assign Stock'),
    SidebarItem(
      icon: Icons.move_to_inbox_outlined,
      label: 'Incoming Branch Returns',
      group: 'Assign Stock',
    ),
    SidebarItem(icon: Icons.business_outlined, label: 'Head Office'),
    SidebarItem(
      icon: Icons.percent_outlined,
      label: 'Branch Invoice Discount',
      group: 'Discount',
    ),
    SidebarItem(
      icon: Icons.sell_outlined,
      label: 'Branch Stock Discount',
      group: 'Discount',
    ),
    SidebarItem(
      icon: Icons.account_balance_outlined,
      label: 'Bank Head',
      group: 'Bank',
    ),
    SidebarItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Bank Entry',
      group: 'Bank',
    ),
    SidebarItem(icon: Icons.print_outlined, label: 'Print', group: 'Printer'),
    SidebarItem(
      icon: Icons.local_printshop_outlined,
      label: 'Assign Print',
      group: 'Printer',
    ),
    SidebarItem(icon: Icons.payments_outlined, label: 'Employee Salary'),
    SidebarItem(
      icon: Icons.receipt_long_outlined,
      label: 'Sale Invoice Report',
      group: 'Reports',
    ),
    SidebarItem(
      icon: Icons.assignment_return_outlined,
      label: 'Sale Return Report',
      group: 'Reports',
    ),
    SidebarItem(
      icon: Icons.swap_horiz_outlined,
      label: 'Sale Exchange Report',
      group: 'Reports',
    ),
  ];

  static const _pages = [
    OverviewScreen(),
    BranchesScreen(),
    WarehouseScreen(),
    UsersScreen(),
    // Admin sirf add kar sakta hai — edit/delete options hidden.
    ProductsScreen(readOnly: true),
    SizesScreen(readOnly: true),
    ColorsScreen(readOnly: true),
    BrandsScreen(readOnly: true),
    CategorysScreen(readOnly: true),
    TypesScreen(readOnly: true),
    // Sab warehouses ka stock — add ho sakta hai, edit/delete nahi.
    HeadOfficeStockScreen(),
    // Admin ko pehle warehouse choose karni hoti hai (khud koi warehouse
    // assign nahi hoti), phir wahi invoice/return screens jo warehouse
    // dashboard mein hain.
    PurchaseInvoiceScreen(),
    PurchaseReturnScreen(),
    CompaniesScreen(),
    // Head office se branch ko stock assign — head_office_id ke sath.
    HoAssignStockScreen(),
    // Assignment history — alag page (sidebar "Assign Stock" group ke andar).
    HoAssignStockListScreen(),
    // Branches se Admin (Head Office) ko jo stock returns aate hain — accept/reject.
    IncomingBranchReturnsScreen(),
    HeadOfficeScreen(),
    BranchInvoiceDiscountScreen(),
    BranchStockDiscountScreen(),
    BankHeadsScreen(),
    BankEntriesScreen(),
    PrinterHeadsScreen(),
    AssignPrinterScreen(),
    EmployeeSalaryScreen(),
    SaleInvoiceReportScreen(),
    SaleReturnReportScreen(),
    SaleExchangeReportScreen(),
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
