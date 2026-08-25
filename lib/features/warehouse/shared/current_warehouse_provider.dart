import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/providers/workspace_selection_provider.dart';

/// Logged-in user ke sath jo warehouse assign hai uska id.
/// Agar user ko multiple warehouses assign hain to jo warehouse usne
/// select-workspace screen par click karke choose kiya (aur locally persist
/// hua), wahi id yahan se milegi. Sirf 1 warehouse assign hone par wahi
/// automatically use ho jati hai.
final currentWarehouseIdProvider = Provider<String>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return '';
  final selected = ref.watch(selectedWarehouseIdProvider);

  // Admin/superadmin don't own a warehouse assignment — they explicitly
  // pick which warehouse to act on (via WarehouseContextGate), so whatever
  // they've selected is used as-is, without the `warehouseIds` ownership check.
  if (user.isSuperAdmin || user.isAdmin) return selected;

  if (selected.isNotEmpty && user.warehouseIds.contains(selected)) {
    return selected;
  }
  return user.warehouseIds.isNotEmpty ? user.warehouseIds.first : '';
});
