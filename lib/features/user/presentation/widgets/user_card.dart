import 'package:flutter/material.dart';
import '../../../auth/data/model/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final bool canEdit;
  final List<String> roles;
  final ValueChanged<String> onRoleChange;
  final VoidCallback onToggleActive;
  final VoidCallback onAssign;

  const UserCard({
    super.key,
    required this.user,
    required this.canEdit,
    required this.roles,
    required this.onRoleChange,
    required this.onToggleActive,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name + status
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEAEFFD),
                child: Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: const TextStyle(color: Color(0xFF3E63DD), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(user.email, style: const TextStyle(color: Color(0xFF8A8FA3), fontSize: 13)),
                  ],
                ),
              ),
              _StatusBadge(isActive: user.isActive),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom row: role / actions
          if (canEdit)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: user.role,
                    decoration: _inputDecor('Role'),
                    isDense: true,
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(_displayRole(r), style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) { if (v != null) onRoleChange(v); },
                  ),
                ),
                const SizedBox(width: 8),
                _OutlineBtn(
                  icon: user.isActive ? Icons.block : Icons.check_circle_outline,
                  label: user.isActive ? 'Deactivate' : 'Activate',
                  color: user.isActive ? Colors.redAccent : Colors.green,
                  onTap: onToggleActive,
                ),
                const SizedBox(width: 8),
                _OutlineBtn(
                  icon: Icons.link,
                  label: 'Assign',
                  color: const Color(0xFF3E63DD),
                  onTap: onAssign,
                ),
              ],
            )
          else
            _RoleBadge(role: user.role),

          // Branch / warehouse chips
          if (user.branchIds.isNotEmpty || user.warehouseIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                children: [
                  if (user.branchIds.isNotEmpty)
                    _InfoChip(icon: Icons.apartment_outlined, label: '${user.branchIds.length} branch(es)'),
                  if (user.warehouseIds.isNotEmpty)
                    _InfoChip(icon: Icons.warehouse_outlined, label: '${user.warehouseIds.length} warehouse(s)'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _displayRole(String role) {
  const map = {
    'superadmin': 'Super Admin', 'admin': 'Admin', 'manager': 'Manager',
    'warehouse_manager': 'Warehouse Mgr', 'inventory_manager': 'Inventory Mgr',
    'cashier': 'Cashier', 'salesman': 'Salesman',
  };
  return map[role] ?? role;
}

InputDecoration _inputDecor(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3E63DD))),
    );

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF5E6) : const Color(0xFFFEECEC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFEAEFFD), borderRadius: BorderRadius.circular(20)),
      child: Text(_displayRole(role), style: const TextStyle(color: Color(0xFF3E63DD), fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE7E9F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF8A8FA3)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
        ],
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
