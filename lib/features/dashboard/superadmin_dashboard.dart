import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';
import 'package:safishoe_app/features/superadmin/bank/presentation/screens/bank_entries_screen.dart';
import 'package:safishoe_app/features/superadmin/bank/presentation/screens/bank_heads_screen.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../superadmin/branch/presentation/screens/branches_screen.dart';
import '../superadmin/printer/presentation/screens/assign_printer_screen.dart';
import '../superadmin/printer/presentation/screens/printer_heads_screen.dart';
import '../superadmin/employee_salary/presentation/screens/employee_salary_screen.dart';
import '../superadmin/warehouse/presentation/screens/warehouse_screen.dart';
import '../user/presentation/screens/users_screen.dart';


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
    SidebarItem(icon: Icons.people_outline, label: 'Users'),
    SidebarItem(icon: Icons.apartment_outlined, label: 'Branches'),
    SidebarItem(icon: Icons.warehouse_outlined, label: 'Warehouse'),
    SidebarItem(icon: Icons.warehouse_outlined, label: 'Bank Head'),
    SidebarItem(icon: Icons.warehouse_outlined, label: 'Bank Entry'),
    SidebarItem(icon: Icons.warehouse_outlined, label: 'Print'),
    SidebarItem(icon: Icons.warehouse_outlined, label: 'Assign Print'),
    SidebarItem(icon: Icons.payments_outlined, label: 'Employee Salary'),
  ];

  static const _pages = [
    UsersScreen(),
    BranchesScreen(),
    WarehouseScreen(),
    BankHeadsScreen(),
    BankEntriesScreen(),
    PrinterHeadsScreen(),
    AssignPrinterScreen(),
    EmployeeSalaryScreen(),
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
