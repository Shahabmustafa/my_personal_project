import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/model/warehouse_model.dart';
import '../providers/warehouse_provider.dart';
import '../providers/warehouse_state.dart';
import '../widgets/warehouse_card.dart';
import '../widgets/warehouse_form_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class WarehouseScreen extends ConsumerStatefulWidget {
  const WarehouseScreen({super.key});

  @override
  ConsumerState<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends ConsumerState<WarehouseScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user == null) return;
      if (user.canManageWarehouses) {
        ref.read(warehouseProvider.notifier).loadAllWarehouses();
      } else {
        ref.read(warehouseProvider.notifier).loadUserWarehouses(user.warehouseIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final warehouseState = ref.watch(warehouseProvider);
    final canEdit = ref.watch(authProvider).user?.canManageWarehouses ?? false;
    final isMobile = MediaQuery.of(context).size.width < 768;

    final filtered = warehouseState.warehouses.where((w) {
      final q = _searchQuery.toLowerCase();
      return w.warehouseName.toLowerCase().contains(q) ||
          w.city.toLowerCase().contains(q) ||
          w.address.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Warehouses',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${warehouseState.warehouses.length} total warehouses',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
                if (canEdit)
                  ElevatedButton.icon(
                    onPressed: () => _showForm(context),
                    icon: const AppIcon(AppIcons.add, size: 18),
                    label: const Text('Add Warehouse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E63DD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: _searchDecor('Search warehouses...'),
            ),
          ),

          // Content
          Expanded(
            child: warehouseState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : warehouseState.status == WarehouseStatus.error
                ? _ErrorView(
              message: warehouseState.errorMessage ?? 'Error',
              onRetry: () => ref.read(warehouseProvider.notifier).loadAllWarehouses(),
            )
                : filtered.isEmpty
                ? const _EmptyView()
                : isMobile
                ? _MobileList(
              warehouses: filtered,
              canEdit: canEdit,
              onEdit: (w) => _showForm(context, warehouse: w),
              onDelete: (w) => _confirmDelete(context, w),
            )
                : _DesktopTable(
              warehouses: filtered,
              canEdit: canEdit,
              onEdit: (w) => _showForm(context, warehouse: w),
              onDelete: (w) => _confirmDelete(context, w),
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {WarehouseModel? warehouse}) {
    showDialog(
      context: context,
      builder: (_) => WarehouseFormDialog(
        warehouse: warehouse,
        onSave: (w) => warehouse == null
            ? ref.read(warehouseProvider.notifier).createWarehouse(w)
            : ref.read(warehouseProvider.notifier).updateWarehouse(w),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WarehouseModel warehouse) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Warehouse'),
        content: Text('Delete "${warehouse.warehouseName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(warehouseProvider.notifier).deleteWarehouse(warehouse.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<WarehouseModel> warehouses;
  final bool canEdit;
  final Function(WarehouseModel) onEdit;
  final Function(WarehouseModel) onDelete;

  const _DesktopTable({
    required this.warehouses,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  _TH('Warehouse Name', flex: 3),
                  _TH('City', flex: 2),
                  _TH('Address', flex: 4),
                  _TH('Phone', flex: 2),
                  _TH('Status', flex: 2),
                  if (canEdit) _TH('Actions', flex: 2),
                ]),
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: warehouses.length,
                  itemBuilder: (_, i) {
                    final w = warehouses[i];
                    final isLast = i == warehouses.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        // Warehouse name with icon
                        Expanded(
                          flex: 3,
                          child: _TD(child: Row(children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const AppIcon(AppIcons.warehouseOutlined,
                                  color: Color(0xFF2E7D32), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(w.warehouseName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ])),
                        ),
                        // City
                        Expanded(
                          flex: 2,
                          child: _TD(child: Text(
                            w.city.isEmpty ? '—' : w.city,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        // Address
                        Expanded(
                          flex: 4,
                          child: _TD(child: Text(
                            w.address.isEmpty ? '—' : w.address,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        // Phone
                        Expanded(
                          flex: 2,
                          child: _TD(child: Text(
                            w.phoneNumber.isEmpty ? '—' : w.phoneNumber,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        // Status
                        Expanded(
                          flex: 2,
                          child: _TD(child: _StatusPill(isActive: w.isActive)),
                        ),
                        // Actions
                        if (canEdit)
                          Expanded(
                            flex: 2,
                            child: _TD(child: Row(children: [
                              _IconBtn(
                                icon: AppIcons.editOutlined,
                                color: const Color(0xFF3E63DD),
                                tooltip: 'Edit',
                                onTap: () => onEdit(w),
                              ),
                              const SizedBox(width: 8),
                              _IconBtn(
                                icon: AppIcons.deleteOutline,
                                color: Colors.redAccent,
                                tooltip: 'Delete',
                                onTap: () => onDelete(w),
                              ),
                            ])),
                          ),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<WarehouseModel> warehouses;
  final bool canEdit;
  final Function(WarehouseModel) onEdit;
  final Function(WarehouseModel) onDelete;

  const _MobileList({
    required this.warehouses,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: warehouses.length,
      itemBuilder: (_, i) => WarehouseCard(
        warehouse: warehouses[i],
        canEdit: canEdit,
        onEdit: () => onEdit(warehouses[i]),
        onDelete: () => onDelete(warehouses[i]),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A8FA3),
                letterSpacing: 0.3)),
      ),
    );
  }
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: child,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
        required this.color,
        required this.tooltip,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6)),
          child: AppIcon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF5E6) : const Color(0xFFFEECEC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const AppIcon(AppIcons.errorOutline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AppIcon(AppIcons.warehouseOutlined, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        const Text('No warehouses found',
            style: TextStyle(color: Color(0xFF8A8FA3))),
      ]),
    );
  }
}

InputDecoration _searchDecor(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
  prefixIcon: const AppIcon(AppIcons.search, color: Color(0xFF8A8FA3)),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 12),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
);