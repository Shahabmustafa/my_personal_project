import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/branch_dashboard.dart';
import '../../../dashboard/salesman_dashboard.dart';
import '../../../dashboard/warehouse_dashboard.dart';
import '../../../superadmin/branch/data/model/branch_model.dart';
import '../../../superadmin/branch/presentation/providers/branch_provider.dart';
import '../../../superadmin/warehouse/data/model/warehouse_model.dart';
import '../../../superadmin/warehouse/presentation/providers/warehouse_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workspace_selection_provider.dart';
import 'login_screen.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
/// User ko uske assigned branches aur warehouses dikhata hai — jab
/// login ke baad 1 se zyada assign hon. Jis par tap kare, wahi id
/// locally persist ho jati hai aur app usi branch/warehouse ke liye
/// data load karta hai.
class SelectWorkspaceScreen extends ConsumerStatefulWidget {
  const SelectWorkspaceScreen({super.key});

  @override
  ConsumerState<SelectWorkspaceScreen> createState() =>
      _SelectWorkspaceScreenState();
}

class _SelectWorkspaceScreenState extends ConsumerState<SelectWorkspaceScreen> {
  bool _isLoading = true;
  String? _error;
  List<BranchModel> _branches = [];
  List<WarehouseModel> _warehouses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    try {
      final branchRepo = ref.read(branchRepositoryProvider);
      final warehouseRepo = ref.read(warehouseRepositoryProvider);
      final results = await Future.wait([
        user.branchIds.isNotEmpty
            ? branchRepo.getBranchesForUser(user.branchIds)
            : Future.value(<BranchModel>[]),
        user.warehouseIds.isNotEmpty
            ? warehouseRepo.getWarehousesForUser(user.warehouseIds)
            : Future.value(<WarehouseModel>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _branches = results[0] as List<BranchModel>;
        _warehouses = results[1] as List<WarehouseModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _pickBranch(String branchId) async {
    await ref.read(selectedBranchIdProvider.notifier).select(branchId);
    if (!mounted) return;
    final isSalesman = ref.read(authProvider).user?.isSalesman ?? false;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isSalesman ? const SalesmanDashboard() : const BranchDashboard(),
      ),
    );
  }

  Future<void> _pickWarehouse(String warehouseId) async {
    await ref.read(selectedWarehouseIdProvider.notifier).select(warehouseId);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WarehouseDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hi, ${user?.username ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aapko multiple branches/warehouses assign hain.\nAage badhne ke liye ek select karein.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Text(_error!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              setState(() => _isLoading = true);
                              _load();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (_branches.isNotEmpty) ...[
                      const _SectionLabel(label: 'Branches', icon: AppIcons.apartmentOutlined),
                      const SizedBox(height: 10),
                      ..._branches.map((b) => _WorkspaceCard(
                            title: b.branchName,
                            subtitle: [b.city, b.address]
                                .where((s) => s.isNotEmpty)
                                .join(' • '),
                            icon: AppIcons.apartmentOutlined,
                            onTap: () => _pickBranch(b.id),
                          )),
                      const SizedBox(height: 20),
                    ],
                    if (_warehouses.isNotEmpty) ...[
                      const _SectionLabel(label: 'Warehouses', icon: AppIcons.warehouseOutlined),
                      const SizedBox(height: 10),
                      ..._warehouses.map((w) => _WorkspaceCard(
                            title: w.warehouseName,
                            subtitle: [w.city, w.address]
                                .where((s) => s.isNotEmpty)
                                .join(' • '),
                            icon: AppIcons.warehouseOutlined,
                            onTap: () => _pickWarehouse(w.id),
                          )),
                    ],
                  ],
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    icon: const AppIcon(AppIcons.logout, size: 18),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: Colors.grey.shade600)),
      ],
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;

  const _WorkspaceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E9F0)),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(icon, size: 20, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                AppIcon(AppIcons.chevronRight, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
