import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/model/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../superadmin/branch/presentation/providers/branch_provider.dart';
import '../../../superadmin/warehouse/presentation/providers/warehouse_provider.dart';
import '../providers/user_provider.dart';
import '../providers/user_state.dart';
import '../widgets/user_card.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/add_user_dialog.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _searchQuery = '';

  static const _roles = [
    'superadmin', 'admin', 'manager',
    'warehouse_manager', 'inventory_manager', 'cashier', 'salesman',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadAllUsers();
      ref.read(branchProvider.notifier).loadAllBranches();
      ref.read(warehouseProvider.notifier).loadAllWarehouses();
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
                    icon: const Icon(Icons.add, size: 18),
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
                        ? const _EmptyView(icon: Icons.people_outline, message: 'No users found')
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
                        Expanded(flex: 2, child: _TD(child: Text('${u.branchIds.length}', style: const TextStyle(fontSize: 13)))),
                        // Warehouses count
                        Expanded(flex: 2, child: _TD(child: Text('${u.warehouseIds.length}', style: const TextStyle(fontSize: 13)))),
                        // Actions
                        if (canEdit)
                          Expanded(
                            flex: 2,
                            child: _TD(child: Row(children: [
                              _IconBtn(
                                icon: u.isActive ? Icons.block : Icons.check_circle_outline,
                                color: u.isActive ? Colors.redAccent : Colors.green,
                                tooltip: u.isActive ? 'Deactivate' : 'Activate',
                                onTap: () => onToggleActive(u),
                              ),
                              const SizedBox(width: 8),
                              _IconBtn(
                                icon: Icons.link,
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
  final IconData icon;
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
          child: Icon(icon, size: 16, color: color),
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
      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]));
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 48, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
    ]));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _roleLabel(String role) {
  const map = {
    'superadmin': 'Super Admin', 'admin': 'Admin', 'manager': 'Manager',
    'warehouse_manager': 'WH Manager', 'inventory_manager': 'Inv Manager',
    'cashier': 'Cashier', 'salesman': 'Salesman',
  };
  return map[role] ?? role;
}

InputDecoration _searchDecor(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
  prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8FA3)),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 12),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
);
