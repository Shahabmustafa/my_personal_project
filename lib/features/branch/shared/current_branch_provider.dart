import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/providers/workspace_selection_provider.dart';

/// Logged-in user ke sath jo branch assign hai uska id.
/// Agar user ko multiple branches assign hain to jo branch usne
/// select-workspace screen par click karke choose kiya (aur locally persist
/// hua), wahi id yahan se milegi. Sirf 1 branch assign hone par wahi
/// automatically use ho jati hai.
final currentBranchIdProvider = Provider<String>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return '';
  final selected = ref.watch(selectedBranchIdProvider);
  if (selected.isNotEmpty && user.branchIds.contains(selected)) {
    return selected;
  }
  return user.branchIds.isNotEmpty ? user.branchIds.first : '';
});
