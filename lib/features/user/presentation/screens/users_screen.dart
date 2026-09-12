import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/model/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../superadmin/branch/presentation/providers/branch_provider.dart';
import '../../../superadmin/warehouse/presentation/providers/warehouse_provider.dart';
import '../../../superadmin/head_office/presentation/providers/head_office_provider.dart';
import '../providers/user_provider.dart';
import '../providers/user_state.dart';
import '../widgets/user_card.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/add_user_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _searchQuery = '';

  static const _roles = [
    'superadmin', 'manager', 'supervisor',
    'warehouse_manager', 'inventory_manager', 'cashier', 'salesman',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadAllUsers();
      ref.read(branchProvider.notifier).loadAllBranches();
      ref.read(warehouseProvider.notifier).loadAllWarehouses();
      ref.read(headOfficeProvider.notifier).loadAllHeadOffices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final canEdit = ref.watch(authProvider).user?.canManageUsers ?? false;
    final isMobile = MediaQuery.of(context).size.width < 768;

    final filtered = userState.users.where((u) {
      final q = _searchQuery.toLowerCase();
      return u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
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
                    const Text('Users', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${userState.users.length} total users',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
                if (canEdit)
                  ElevatedButton.icon(
                    onPressed: () => showDialog(context: context, builder: (_) => const AddUserDialog()),
                    icon: const AppIcon(AppIcons.add, size: 18),
                    label: const Text('Add User'),
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
              decoration: _searchDecor('Search by name, email or role...'),
            ),
          ),

          // Content
          Expanded(
            child: userState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : userState.status == UserStatus.error
                ? _ErrorView(
              message: userState.errorMessage ?? 'Error',
              onRetry: () => ref.read(userProvider.notifier).loadAllUsers(),
            )
                : filtered.isEmpty
                ? const _EmptyView(icon: AppIcons.peopleOutline, message: 'No users found')
                : isMobile
                ? _MobileList(
              users: filtered,
              canEdit: canEdit,
              roles: _roles,
              onRoleChange: (u, r) => ref.read(userProvider.notifier).updateUserRole(userId: u.id, role: r),
              onToggleActive: (u) => ref.read(userProvider.notifier).toggleUserActive(userId: u.id, isActive: !u.isActive),
              onAssign: (u) => showDialog(context: context, builder: (_) => AssignDialog(user: u)),
            )
                : _DesktopTable(
              users: filtered,
              canEdit: canEdit,
              roles: _roles,
              onRoleChange: (u, r) => ref.read(userProvider.notifier).updateUserRole(userId: u.id, role: r),
              onToggleActive: (u) => ref.read(userProvider.notifier).toggleUserActive(userId: u.id, isActive: !u.isActive),
              onAssign: (u) => showDialog(context: context, builder: (_) => AssignDialog(user: u)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<UserModel> users;
  final bool canEdit;
  final List<String> roles;
  final Function(UserModel, String) onRoleChange;
  final Function(UserModel) onToggleActive;
  final Function(UserModel) onAssign;

  const _DesktopTable({
    required this.users,
    required this.canEdit,
    required this.roles,
    required this.onRoleChange,
    required this.onToggleActive,
    required this.onAssign,
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
              // Header row
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  _TH('Name', flex: 3),
                  _TH('Email', flex: 3),
                  _TH('Role', flex: 2),
                  _TH('Status', flex: 2),
                  _TH('Branches', flex: 2),
                  _TH('WH', flex: 2),       // short — no wrap
                  if (canEdit) _TH('Actions', flex: 2),
                ]),
              ),
              // Data rows
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final isLast = i == users.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        // Name
                        Expanded(
                          flex: 3,
                          child: _TD(child: Row(children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFEAEFFD),
                              child: Text(
                                u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                                style: const TextStyle(color: Color(0xFF3E63DD), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(u.username,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ])),
                        ),
                        // Email
                        Expanded(
                          flex: 3,
                          child: _TD(child: Text(u.email,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                              overflow: TextOverflow.ellipsis)),
                        ),
                        // Role dropdown
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: canEdit
                                ? DropdownButtonFormField<String>(
                              value: u.role,
                              isDense: true,
                              isExpanded: true,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF3E63DD))),
                              ),
                              items: roles.map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(_roleLabel(r), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (v) { if (v != null) onRoleChange(u, v); },
                            )
                                : _RoleBadge(role: u.role),
                          ),
                        ),
                        // Status
                        Expanded(flex: 2, child: _TD(child: _StatusBadge(isActive: u.isActive))),
                        // Branches count
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: u.branchIds.isEmpty
                                ? Text('0', style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)))
                                : GestureDetector(
                              onTap: () => _showBranchWarehouseDialog(
                                context,
                                title: 'Branches — ${u.username}',
                                icon: AppIcons.apartmentOutlined,
                                ids: u.branchIds,
                                type: 'branch',
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAEFFD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${u.branchIds.length}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3E63DD)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Warehouses count
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: u.warehouseIds.isEmpty
                                ? Text('0', style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)))
                                : GestureDetector(
                              onTap: () => _showBranchWarehouseDialog(
                                context,
                                title: 'Warehouses — ${u.username}',
                                icon: AppIcons.warehouseOutlined,
                                ids: u.warehouseIds,
                                type: 'warehouse',
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FAF0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${u.warehouseIds.length}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Actions
                        if (canEdit)
                          Expanded(
                            flex: 2,
                            child: _TD(child: Row(children: [
                              _IconBtn(
                                icon: u.isActive ? AppIcons.block : AppIcons.checkCircleOutline,
                                color: u.isActive ? Colors.redAccent : Colors.green,
                                tooltip: u.isActive ? 'Deactivate' : 'Activate',
                                onTap: () => onToggleActive(u),
                              ),
                              const SizedBox(width: 8),
                              _IconBtn(
                                icon: AppIcons.link,
                                color: const Color(0xFF3E63DD),
                                tooltip: 'Assign',
                                onTap: () => onAssign(u),
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
  final List<UserModel> users;
  final bool canEdit;
  final List<String> roles;
  final Function(UserModel, String) onRoleChange;
  final Function(UserModel) onToggleActive;
  final Function(UserModel) onAssign;

  const _MobileList({
    required this.users, required this.canEdit, required this.roles,
    required this.onRoleChange, required this.onToggleActive, required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: users.length,
      itemBuilder: (_, i) => UserCard(
        user: users[i],
        canEdit: canEdit,
        roles: roles,
        onRoleChange: (r) => onRoleChange(users[i], r),
        onToggleActive: () => onToggleActive(users[i]),
        onAssign: () => onAssign(users[i]),
      ),
    );
  }
}

// ── Branch / Warehouse Info Dialog ───────────────────────────────────────────

void _showBranchWarehouseDialog(
    BuildContext context, {
      required String title,
      required String icon,
      required List<String> ids,
      required String type, // 'branch' or 'warehouse'
    }) {
  showDialog(
    context: context,
    builder: (_) => _BranchWarehouseInfoDialog(
      title: title,
      icon: icon,
      ids: ids,
      type: type,
    ),
  );
}

class _BranchWarehouseInfoDialog extends ConsumerWidget {
  final String title;
  final String icon;
  final List<String> ids;
  final String type;

  const _BranchWarehouseInfoDialog({
    required this.title,
    required this.icon,
    required this.ids,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBranch = type == 'branch';
    final branches = ref.watch(branchProvider).branches;
    final warehouses = ref.watch(warehouseProvider).warehouses;

    final items = isBranch
        ? branches.where((b) => ids.contains(b.id)).toList()
        : warehouses.where((w) => ids.contains(w.id)).toList();

    final accentColor = isBranch ? const Color(0xFF3E63DD) : const Color(0xFF2E7D32);
    final bgColor = isBranch ? const Color(0xFFEAEFFD) : const Color(0xFFF0FAF0);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: AppIcon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: items.isEmpty
            ? Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AppIcon(AppIcons.infoOutline, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                isBranch ? 'Branch data loading...' : 'Warehouse data loading...',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final name = isBranch
                ? (item as dynamic).branchName as String
                : (item as dynamic).warehouseName as String;
            final sub = (item as dynamic).city as String;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  AppIcon(icon, size: 16, color: accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accentColor)),
                        Text(sub,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF8A8FA3), letterSpacing: 0.3)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
          child: AppIcon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

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
          fontSize: 11, fontWeight: FontWeight.w600,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFEAEFFD), borderRadius: BorderRadius.circular(20)),
      child: Text(_roleLabel(role),
          style: const TextStyle(color: Color(0xFF3E63DD), fontSize: 11, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const AppIcon(AppIcons.errorOutline, size: 48, color: Colors.redAccent),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]));
  }
}

class _EmptyView extends StatelessWidget {
  final String icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AppIcon(icon, size: 48, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
    ]));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _roleLabel(String role) {
  const map = {
    'superadmin': 'Super Admin', 'manager': 'Manager',
    'supervisor': 'Supervisor',
    'warehouse_manager': 'WH Manager', 'inventory_manager': 'Inv Manager',
    'cashier': 'Cashier', 'salesman': 'Salesman',
  };
  return map[role] ?? role;
}

InputDecoration _searchDecor(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
  prefixIcon: const TextFieldIcon(AppIcons.search, size: 16, color: Color(0xFF8A8FA3)),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 12),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
);