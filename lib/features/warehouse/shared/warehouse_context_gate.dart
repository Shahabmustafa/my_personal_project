import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/providers/workspace_selection_provider.dart';
import '../../superadmin/warehouse/presentation/providers/warehouse_provider.dart';

/// Admin/superadmin don't own a warehouse assignment, but warehouse-scoped
/// features (Purchase Invoice, Purchase Return, Add Stock) need one to work
/// against. This gate lets them explicitly pick a warehouse to act on —
/// non-admin roles (who already have their own assigned warehouse) pass
/// straight through to [child].
class WarehouseContextGate extends ConsumerStatefulWidget {
  final Widget child;
  const WarehouseContextGate({super.key, required this.child});

  @override
  ConsumerState<WarehouseContextGate> createState() =>
      _WarehouseContextGateState();
}

class _WarehouseContextGateState extends ConsumerState<WarehouseContextGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(warehouseProvider.notifier).loadAllWarehouses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.isSuperAdmin == true;
    if (!isAdmin) return widget.child;

    final selected = ref.watch(selectedWarehouseIdProvider);
    final warehouseState = ref.watch(warehouseProvider);
    final warehouses = warehouseState.warehouses;

    // Only one warehouse in the system → nothing to choose. Adopt it silently
    // so warehouse-scoped screens work without an extra click.
    if (selected.isEmpty && warehouses.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(selectedWarehouseIdProvider).isEmpty) {
          ref
              .read(selectedWarehouseIdProvider.notifier)
              .select(warehouses.first.id);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFEAEFFD),
            border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
          ),
          child: Row(
            children: [
              const Icon(Icons.warehouse_outlined,
                  size: 18, color: Color(0xFF3E63DD)),
              const SizedBox(width: 8),
              const Text('Working warehouse:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E63DD))),
              const SizedBox(width: 10),
              Expanded(
                child: warehouseState.isLoading && warehouses.isEmpty
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: warehouses.any((w) => w.id == selected)
                              ? selected
                              : null,
                          hint: const Text('Select a warehouse',
                              style: TextStyle(fontSize: 13)),
                          isDense: true,
                          items: warehouses
                              .map((w) => DropdownMenuItem(
                                    value: w.id,
                                    child: Text(w.warehouseName,
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(selectedWarehouseIdProvider.notifier)
                                  .select(v);
                            }
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        Expanded(
          child: selected.isEmpty || !warehouses.any((w) => w.id == selected)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warehouse_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text('Select a warehouse above to continue',
                          style: TextStyle(color: Color(0xFF8A8FA3))),
                    ],
                  ),
                )
              : widget.child,
        ),
      ],
    );
  }
}
