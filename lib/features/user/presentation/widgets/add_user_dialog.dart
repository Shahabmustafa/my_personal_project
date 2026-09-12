import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/user_state.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Roles jo branch dashboard users add kar sakte hain
  static const _branchRoles = ['cashier', 'salesman'];

  // Superadmin ke liye saare roles
  static const _adminRoles = [
    'superadmin', 'manager', 'supervisor',
    'warehouse_manager', 'inventory_manager', 'cashier', 'salesman',
  ];

  static const _roleLabels = {
    'superadmin': 'Super Admin',
    'manager': 'Manager',
    'supervisor': 'Supervisor',
    'warehouse_manager': 'Warehouse Manager',
    'inventory_manager': 'Inventory Manager',
    'cashier': 'Cashier',
    'salesman': 'Salesman',
  };

  late String _role;
  late List<String> _availableRoles;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authProvider).user;
    final isSuper = currentUser?.isSuperAdmin == true;

    _availableRoles = isSuper ? _adminRoles : _branchRoles;
    _role = _availableRoles.first;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final currentUser = ref.read(authProvider).user;

    // Branch IDs automatically — current logged-in user ki branches
    final branchIds = currentUser?.branchIds ?? [];

    final success = await ref.read(userProvider.notifier).createUser(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          role: _role,
          phoneNumber: _phoneCtrl.text.trim(),
          branchIds: branchIds,  // auto assign
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            branchIds.isNotEmpty
                ? 'User created and assigned to ${branchIds.length} branch(es)'
                : 'User created successfully',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error =
          ref.read(userProvider).errorMessage ?? 'Failed to create user';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final branchIds = currentUser?.branchIds ?? [];
    final isSuper = currentUser?.isSuperAdmin == true;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          AppIcon(AppIcons.personAddOutlined, color: Color(0xFF3E63DD), size: 22),
          SizedBox(width: 10),
          Text('Add New User',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                // Username
                _FormField(
                  controller: _usernameCtrl,
                  label: 'Username *',
                  hint: 'e.g. john_doe',
                  icon: AppIcons.personOutline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                ),
                const SizedBox(height: 14),

                // Email
                _FormField(
                  controller: _emailCtrl,
                  label: 'Email *',
                  hint: 'user@example.com',
                  icon: AppIcons.emailOutlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$')
                        .hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: _decor('Password *', AppIcons.lockOutline).copyWith(
                    hintText: 'Min 6 characters',
                    suffixIcon: IconButton(
                      icon: AppIcon(
                        _obscurePassword
                            ? AppIcons.visibilityOffOutlined
                            : AppIcons.visibilityOutlined,
                        color: const Color(0xFF8A8FA3),
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone
                _FormField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  hint: '0300-0000000',
                  icon: AppIcons.phoneOutlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                // Role
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: _decor('Role *', AppIcons.badgeOutlined),
                  isExpanded: true,
                  items: _availableRoles
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(_roleLabels[r] ?? r,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: 14),

                // Branch info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEFFD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3E63DD).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const AppIcon(AppIcons.apartmentOutlined,
                          size: 16, color: Color(0xFF3E63DD)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSuper
                              ? 'Branch assign after creation via Assign button'
                              : branchIds.isNotEmpty
                                  ? 'Auto-assigned to ${branchIds.length} branch(es)'
                                  : 'No branch assigned to you yet',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF3E63DD)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3E63DD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Create User'),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decor(label, icon).copyWith(hintText: hint),
      validator: validator,
    );
  }
}

InputDecoration _decor(String label, String icon) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: AppIcon(icon, size: 16, color: const Color(0xFF8A8FA3)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
