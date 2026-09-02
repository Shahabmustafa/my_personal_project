import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/model/user_model.dart';
import '../../../superadmin/branch/presentation/providers/branch_provider.dart';
import '../../../superadmin/warehouse/presentation/providers/warehouse_provider.dart';
import '../../../superadmin/head_office/presentation/providers/head_office_provider.dart';
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
  late List<String> _selectedHeadOffices;

  // Sirf superadmin/admin/supervisor multiple branches + warehouses (dono
  // types) rakh sakte hain. Baaki roles apne role-type tak limited hain aur
  // sirf 1 hi le sakte hain — DB trigger bhi isi ko enforce karta hai.
  bool get _isUnrestricted =>
      widget.user.isSuperAdmin || widget.user.isSupervisor;
  bool get _showBranches =>
      _isUnrestricted || !(widget.user.isWarehouseManager || widget.user.isInventoryManager);
  bool get _showWarehouses =>
      _isUnrestricted || (widget.user.isWarehouseManager || widget.user.isInventoryManager);
  // Head office sirf superadmin ko assign hota hai.
  bool get _showHeadOffices => widget.user.isSuperAdmin;

  @override
  void initState() {
    super.initState();
    _selectedBranches = List.from(widget.user.branchIds);
    _selectedWarehouses = List.from(widget.user.warehouseIds);
    _selectedHeadOffices = List.from(widget.user.headOfficeIds);
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchProvider).branches;
    final warehouses = ref.watch(warehouseProvider).warehouses;
    final headOffices = ref.watch(headOfficeProvider).headOffices;

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
              if (!_isUnrestricted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Yeh role sirf ek ${_showBranches ? 'branch' : 'warehouse'} tak limited hai.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                  ),
                ),

              // Branches section
              if (_showBranches) ...[
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
                          if (v != true) {
                            _selectedBranches.remove(b.id);
                          } else if (_isUnrestricted) {
                            _selectedBranches.add(b.id);
                          } else {
                            // Restricted roles: sirf ek hi branch select ho sakti hai
                            _selectedBranches
                              ..clear()
                              ..add(b.id);
                          }
                        }),
                      )),
              ],

              if (_showBranches && _showWarehouses) const Divider(height: 24),

              // Warehouses section
              if (_showWarehouses) ...[
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
                          if (v != true) {
                            _selectedWarehouses.remove(w.id);
                          } else if (_isUnrestricted) {
                            _selectedWarehouses.add(w.id);
                          } else {
                            // Restricted roles: sirf ek hi warehouse select ho sakta hai
                            _selectedWarehouses
                              ..clear()
                              ..add(w.id);
                          }
                        }),
                      )),
              ],

              if (_showHeadOffices && (_showBranches || _showWarehouses))
                const Divider(height: 24),

              // Head Offices section (sirf superadmin)
              if (_showHeadOffices) ...[
                const Text('Head Offices',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                if (headOffices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No head offices available',
                        style: TextStyle(color: Color(0xFF8A8FA3), fontSize: 13)),
                  )
                else
                  ...headOffices.map((h) => CheckboxListTile(
                        dense: true,
                        title: Text(h.headOfficeName,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(h.city,
                            style: const TextStyle(fontSize: 11)),
                        value: _selectedHeadOffices.contains(h.id),
                        activeColor: const Color(0xFF3E63DD),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedHeadOffices.add(h.id);
                          } else {
                            _selectedHeadOffices.remove(h.id);
                          }
                        }),
                      )),
              ],
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
            final notifier = ref.read(userProvider.notifier);
            if (_showBranches) {
              await notifier.assignBranchesToUser(
                userId: widget.user.id,
                branchIds: _selectedBranches,
              );
            }
            if (_showWarehouses) {
              await notifier.assignWarehousesToUser(
                userId: widget.user.id,
                warehouseIds: _selectedWarehouses,
              );
            }
            if (_showHeadOffices) {
              await notifier.assignHeadOfficesToUser(
                userId: widget.user.id,
                headOfficeIds: _selectedHeadOffices,
              );
            }
            if (!context.mounted) return;
            final error = ref.read(userProvider).errorMessage;
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
