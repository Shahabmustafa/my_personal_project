import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/model/customer_model.dart';
import '../providers/customer_provider.dart';
import '../providers/customer_state.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/loyalty_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user == null) return;
      if (user.canManageBranches) {
        // Admin/Superadmin: load all
        ref.read(customerProvider.notifier).loadAllCustomers();
      } else if (user.branchIds.isNotEmpty) {
        // Others: load their branches' customers
        ref
            .read(customerProvider.notifier)
            .loadCustomersForBranches(user.branchIds);
      }
    });
  }

  String get _currentBranchId => ref.read(currentBranchIdProvider);

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final filtered = customerState.customers.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phoneNumber.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q);
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
                    const Text('Customers',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${customerState.customers.length} total customers',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E63DD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
              decoration: _searchDecor('Search by name, phone, email or address...'),
            ),
          ),

          // Content
          Expanded(
            child: customerState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customerState.status == CustomerStatus.error
                ? _ErrorView(
              message: customerState.errorMessage ?? 'Error',
              onRetry: () =>
                  ref.read(customerProvider.notifier).loadAllCustomers(),
            )
                : filtered.isEmpty
                ? const _EmptyView()
                : isMobile
                ? _MobileList(
              customers: filtered,
              onEdit: (c) => _showForm(context, customer: c),
              onDelete: (c) => _confirmDelete(context, c),
              onLoyalty: (c) => _showLoyalty(context, c),
            )
                : _DesktopTable(
              customers: filtered,
              onEdit: (c) => _showForm(context, customer: c),
              onDelete: (c) => _confirmDelete(context, c),
              onLoyalty: (c) => _showLoyalty(context, c),
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {CustomerModel? customer}) {
    showDialog(
      context: context,
      builder: (_) => CustomerFormDialog(
        customer: customer,
        branchId: customer?.branchId ?? _currentBranchId,
        onSave: (c) => customer == null
            ? ref.read(customerProvider.notifier).createCustomer(c)
            : ref.read(customerProvider.notifier).updateCustomer(c),
      ),
    );
  }

  void _showLoyalty(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (_) => LoyaltyDialog(customer: customer),
    );
  }

  void _confirmDelete(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer'),
        content: Text('Delete "${customer.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref
                  .read(customerProvider.notifier)
                  .deleteCustomer(customer.id);
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
  final List<CustomerModel> customers;
  final Function(CustomerModel) onEdit;
  final Function(CustomerModel) onDelete;
  final Function(CustomerModel) onLoyalty;

  const _DesktopTable({
    required this.customers,
    required this.onEdit,
    required this.onDelete,
    required this.onLoyalty,
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
                child: const Row(children: [
                  _TH('Name', flex: 3),
                  _TH('Phone', flex: 2),
                  _TH('Email', flex: 3),
                  _TH('Address', flex: 3),
                  _TH('Opening Balance', flex: 2),
                  _TH('Loyalty Points', flex: 2),
                  _TH('Actions', flex: 2),
                ]),
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (_, i) {
                    final c = customers[i];
                    final isLast = i == customers.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                            bottom: BorderSide(color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        // Name + avatar
                        Expanded(
                          flex: 3,
                          child: _TD(child: Row(children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: const Color(0xFFEAEFFD),
                              child: Text(
                                c.name.isNotEmpty
                                    ? c.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Color(0xFF3E63DD),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ])),
                        ),
                        // Phone
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                                  c.phoneNumber.isEmpty ? '—' : c.phoneNumber,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A8FA3)),
                                  overflow: TextOverflow.ellipsis)),
                        ),
                        // Email
                        Expanded(
                          flex: 3,
                          child: _TD(
                              child: Text(
                                  c.email.isEmpty ? '—' : c.email,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A8FA3)),
                                  overflow: TextOverflow.ellipsis)),
                        ),
                        // Address
                        Expanded(
                          flex: 3,
                          child: _TD(
                              child: Text(
                                  c.address.isEmpty ? '—' : c.address,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A8FA3)),
                                  overflow: TextOverflow.ellipsis)),
                        ),
                        // Opening balance
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                                  'Rs. ${c.openingBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 13))),
                        ),
                        // Loyalty points
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Row(children: [
                                const Icon(Icons.star,
                                    size: 14, color: Color(0xFFD4A017)),
                                const SizedBox(width: 4),
                                Text('${c.loyaltyPoints}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ])),
                        ),
                        // Actions
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Row(children: [
                                _IconBtn(
                                  icon: Icons.star_outline,
                                  color: const Color(0xFFD4A017),
                                  tooltip: 'Loyalty Points',
                                  onTap: () => onLoyalty(c),
                                ),
                                const SizedBox(width: 6),
                                _IconBtn(
                                  icon: Icons.edit_outlined,
                                  color: const Color(0xFF3E63DD),
                                  tooltip: 'Edit',
                                  onTap: () => onEdit(c),
                                ),
                                const SizedBox(width: 6),
                                _IconBtn(
                                  icon: Icons.delete_outline,
                                  color: Colors.redAccent,
                                  tooltip: 'Delete',
                                  onTap: () => onDelete(c),
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
  final List<CustomerModel> customers;
  final Function(CustomerModel) onEdit;
  final Function(CustomerModel) onDelete;
  final Function(CustomerModel) onLoyalty;

  const _MobileList({
    required this.customers,
    required this.onEdit,
    required this.onDelete,
    required this.onLoyalty,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: customers.length,
      itemBuilder: (_, i) {
        final c = customers[i];
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEAEFFD),
                    child: Text(c.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFF3E63DD),
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        if (c.phoneNumber.isNotEmpty)
                          Text(c.phoneNumber,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF8A8FA3))),
                        if (c.email.isNotEmpty)
                          Text(c.email,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star,
                      size: 14, color: Color(0xFFD4A017)),
                  const SizedBox(width: 4),
                  Text('${c.loyaltyPoints} pts',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 14, color: Color(0xFF8A8FA3)),
                  const SizedBox(width: 4),
                  Text('Rs. ${c.openingBalance.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _IconBtn(
                      icon: Icons.star_outline,
                      color: const Color(0xFFD4A017),
                      tooltip: 'Loyalty',
                      onTap: () => onLoyalty(c)),
                  const SizedBox(width: 8),
                  _IconBtn(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF3E63DD),
                      tooltip: 'Edit',
                      onTap: () => onEdit(c)),
                  const SizedBox(width: 8),
                  _IconBtn(
                      icon: Icons.delete_outline,
                      color: Colors.redAccent,
                      tooltip: 'Delete',
                      onTap: () => onDelete(c)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
  final IconData icon;
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
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Gold': (const Color(0xFFFFF8E7), const Color(0xFFD4A017)),
      'Silver': (const Color(0xFFF5F5F5), const Color(0xFF757575)),
      'Bronze': (const Color(0xFFFBEEE6), const Color(0xFF8B4513)),
    };
    final pair = colors[tier] ?? (const Color(0xFFF5F5F5), const Color(0xFF757575));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pair.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(tier,
          style: TextStyle(
              color: pair.$2, fontSize: 11, fontWeight: FontWeight.w600)),
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
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
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
        Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        const Text('No customers found',
            style: TextStyle(color: Color(0xFF8A8FA3))),
      ]),
    );
  }
}

InputDecoration _searchDecor(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
  prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8FA3)),
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
      borderSide:
      const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
);