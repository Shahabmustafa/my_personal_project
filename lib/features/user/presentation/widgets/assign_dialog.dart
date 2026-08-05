import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/model/user_model.dart';
import '../../../superadmin/branch/presentation/providers/branch_provider.dart';
import '../../../superadmin/warehouse/presentation/providers/warehouse_provider.dart';
import '../providers/user_provider.dart';

class AssignDialog extends ConsumerStatefulWidget {
  final UserModel user;
  const AssignDialog({super.key, required this.user});

  @override
  ConsumerState<AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<AssignDialog> {
  late List<String> _selectedBranches;
  late List<String> _selectedWarehouses;

  @override
  void initState() {
    super.initState();
    _selectedBranches = List.from(widget.user.branchIds);
    _selectedWarehouses = List.from(widget.user.warehouseIds);
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchProvider).branches;
    final warehouses = ref.watch(warehouseProvider).warehouses;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Assign — ${widget.user.username}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branches section
              const Text('Branches', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              if (branches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No branches available', style: TextStyle(color: Color(0xFF8A8FA3), fontSize: 13)),
                )
              else
                ...branches.map((b) => CheckboxListTile(
                      dense: true,
                      title: Text(b.branchName, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(b.city, style: const TextStyle(fontSize: 11)),
                      value: _selectedBranches.contains(b.id),
                      activeColor: const Color(0xFF3E63DD),
                      onChanged: (v) => setState(() {
                        if (v == true) _selectedBranches.add(b.id);
                        else _selectedBranches.remove(b.id);
                      }),
                    )),

              const Divider(height: 24),

              // Warehouses section
              const Text('Warehouses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              if (warehouses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No warehouses available', style: TextStyle(color: Color(0xFF8A8FA3), fontSize: 13)),
                )
              else
                ...warehouses.map((w) => CheckboxListTile(
                      dense: true,
                      title: Text(w.warehouseName, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(w.city, style: const TextStyle(fontSize: 11)),
                      value: _selectedWarehouses.contains(w.id),
                      activeColor: const Color(0xFF3E63DD),
                      onChanged: (v) => setState(() {
                        if (v == true) _selectedWarehouses.add(w.id);
                        else _selectedWarehouses.remove(w.id);
                      }),
                    )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3E63DD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            await ref.read(userProvider.notifier).assignBranchesToUser(
                  userId: widget.user.id,
                  branchIds: _selectedBranches,
                );
            await ref.read(userProvider.notifier).assignWarehousesToUser(
                  userId: widget.user.id,
                  warehouseIds: _selectedWarehouses,
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
