import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';
import 'package:safishoe_app/features/user/presentation/screens/users_screen.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../branch/customer/presentation/screens/customers_screen.dart';

// Roles: cashier, manager, salesman

class BranchDashboard extends ConsumerStatefulWidget {
  const BranchDashboard({super.key});

  @override
  ConsumerState<BranchDashboard> createState() => _BranchDashboardState();
}

class _BranchDashboardState extends ConsumerState<BranchDashboard> {
  int _index = 0;

  static const _navItems = [
    SidebarItem(icon: Icons.apartment_outlined, label: 'Users'),
    SidebarItem(icon: Icons.apartment_outlined, label: 'Customers'),
  ];

  static const _pages = [
    UsersScreen(),
    CustomersScreen(),
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
