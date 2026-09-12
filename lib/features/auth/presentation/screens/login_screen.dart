import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/branch_dashboard.dart';
import '../../../dashboard/superadmin_dashboard.dart';
import '../../../dashboard/warehouse_dashboard.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'select_workspace_screen.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(_emailController.text.trim(), _passwordController.text.trim(),);
    }
  }

  Widget _getDashboard(AuthState state) {
    final user = state.user!;
    switch (user.role) {
      // ── Superadmin → sab kuch
      case 'superadmin':
        return const SuperAdminDashboard();

      // ── Branch sidebar → cashier, manager, salesman
      case 'cashier':
      case 'manager':
      case 'salesman':
        return const BranchDashboard();
      case 'warehouse_manager':
      case 'inventory_manager':
        return const WarehouseDashboard();

      // ── Supervisor: koi dedicated dashboard nahi — jo bhi ek workspace
      // assign hai (branch ya warehouse) usi ke hisaab se route karo.
      case 'supervisor':
        if (user.branchIds.isNotEmpty) return const BranchDashboard();
        if (user.warehouseIds.isNotEmpty) return const WarehouseDashboard();
        return const BranchDashboard();

      default:
        return const SuperAdminDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (next.status == AuthStatus.success && next.user != null) {
        final user = next.user!;
        final needsWorkspaceSelection = !user.isSuperAdmin &&
            (user.branchIds.length + user.warehouseIds.length) > 1;

        final destination = needsWorkspaceSelection
            ? const SelectWorkspaceScreen()
            : _getDashboard(next);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // Logo
                    Center(
                      child: Container(
                        height: 84,
                        width: 84,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: AppIcon(
                          AppIcons.storeMallDirectoryRounded,
                          size: 26,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Shoe Shop POS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Login to manage your branches & warehouses',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 40),

                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      icon: AppIcons.emailOutlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$')
                            .hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: AppIcons.lockOutline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: TextFieldIcon(_obscurePassword ? AppIcons.visibilityOffOutlined : AppIcons.visibilityOutlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    PrimaryButton(
                      label: 'Login',
                      isLoading: authState.isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
