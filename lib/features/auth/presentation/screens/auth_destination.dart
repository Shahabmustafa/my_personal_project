import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/branch_dashboard.dart';
import '../../../dashboard/salesman_dashboard.dart';
import '../../../dashboard/superadmin_dashboard.dart';
import '../../../dashboard/warehouse_dashboard.dart';
import '../../data/model/user_model.dart';
import '../providers/auth_provider.dart';
import 'select_workspace_screen.dart';

/// Login ke baad (ya app start par saved login se) user ko kahan bhejna hai.
/// Login screen aur [AppGate] dono yahi use karte hain.
Widget destinationForUser(UserModel user) {
  final needsWorkspaceSelection = !user.isSuperAdmin &&
      (user.branchIds.length + user.warehouseIds.length) > 1;
  return needsWorkspaceSelection
      ? const SelectWorkspaceScreen()
      : dashboardForUser(user);
}

Widget dashboardForUser(UserModel user) {
  switch (user.role) {
    // ── Superadmin → sab kuch
    case 'superadmin':
      return const SuperAdminDashboard();

    // ── Branch sidebar → cashier, manager
    case 'cashier':
    case 'manager':
      return const BranchDashboard();

    // ── Salesman → apna, restricted dashboard
    case 'salesman':
      return const SalesmanDashboard();
    case 'warehouse_manager':
    case 'inventory_manager':
      return const WarehouseDashboard();

    // ── Supervisor: jo workspace assign hai usi ke hisaab se route karo.
    case 'supervisor':
      if (user.branchIds.isNotEmpty) return const BranchDashboard();
      if (user.warehouseIds.isNotEmpty) return const WarehouseDashboard();
      return const BranchDashboard();

    // Unknown/garbled role ko kabhi superadmin access mat do.
    default:
      return const NoAccessScreen();
  }
}

class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your account has no access. Contact admin.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
