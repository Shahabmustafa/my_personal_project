import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/auth/presentation/screens/login_screen.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';
import 'package:safishoe_app/features/warehouse/purchase_invoice/presentation/screens/purchase_invoice_screen.dart';
import 'package:safishoe_app/features/warehouse/purchase_invoice/presentation/screens/purchase_return_screen.dart';
import 'package:safishoe_app/features/warehouse/warehouse_cash_counter/presentation/screens/warehouse_cash_counter_screen.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../warehouse/assign_stock_to_branch/presentation/screens/assign_stock_screen.dart';
import '../warehouse/brand/presentation/screens/brands_screen.dart';
import '../warehouse/category/presentation/screens/categorys_screen.dart';
import '../warehouse/color/presentation/screens/colors_screen.dart';
import '../warehouse/company/presentation/screens/companies_screen.dart';
import '../warehouse/product/presentation/screens/products_screen.dart';
import '../warehouse/size/presentation/screens/sizes_screen.dart';
import '../warehouse/type/presentation/screens/types_screen.dart';
import '../warehouse/stock_inventory/presentation/screens/stock_screen.dart';

// Roles: warehouse_manager, inventory_manager

class WarehouseDashboard extends ConsumerStatefulWidget {
  const WarehouseDashboard({super.key});

  @override
  ConsumerState<WarehouseDashboard> createState() =>
      _WarehouseDashboardState();
}

class _WarehouseDashboardState extends ConsumerState<WarehouseDashboard> {
  int _index = 0;

  static const _navItems = [
    SidebarItem(icon: Icons.business_outlined,           label: 'Purchase Invoice'),
    SidebarItem(icon: Icons.business_outlined,           label: 'Purchase Return'),
    SidebarItem(icon: Icons.business_outlined,           label: 'Assign Stock To Branch'),
    SidebarItem(icon: Icons.business_outlined,           label: 'Warehouse Cash Counter'),
    SidebarItem(icon: Icons.business_outlined,           label: 'Company'),
    SidebarItem(icon: Icons.inventory_2_outlined,        label: 'Products'),
    SidebarItem(icon: Icons.branding_watermark_outlined, label: 'Brands'),
    SidebarItem(icon: Icons.format_size_outlined,        label: 'Sizes'),
    SidebarItem(icon: Icons.color_lens_outlined,         label: 'Colors'),
    SidebarItem(icon: Icons.category_outlined,           label: 'Categories'),
    SidebarItem(icon: Icons.style_outlined,              label: 'Types'),
    SidebarItem(icon: Icons.warehouse_outlined,          label: 'Stock Inventory'),
  ];

  static const _pages = [
    PurchaseInvoiceScreen(),
    PurchaseReturnScreen(),
    AssignStockScreen(),
    WarehouseCashCounterScreen(),
    CompaniesScreen(),
    ProductsScreen(),
    BrandsScreen(),
    SizesScreen(),
    ColorsScreen(),
    CategorysScreen(),
    TypesScreen(),
    StockScreen(),   // warehouseId is now a constant inside the feature
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
