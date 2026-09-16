import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/model/customer_model.dart';
import '../providers/customer_provider.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/loyalty_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String get _currentBranchId => ref.read(currentBranchIdProvider);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);
    final notifier = ref.read(customerProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 768;

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
                    TotalCountLabel(
                        label: 'Customers', count: state.totalCount),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(context),
                  icon: const AppIcon(AppIcons.add, size: 18, color: Colors.white),
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
              onChanged: notifier.setSearch,
              decoration: _searchDecor(
                  'Search by name, phone, email or address...'),
            ),
          ),

          // Content
          Expanded(
            child: isMobile
                ? _MobileList(
                    state: state,
                    notifier: notifier,
                    onEdit: (c) => _showForm(context, customer: c),
                    onDelete: (c) => _confirmDelete(context, c),
                    onLoyalty: (c) => _showLoyalty(context, c),
                  )
                : _DesktopTable(
                    state: state,
                    notifier: notifier,
                    onEdit: (c) => _showForm(context, customer: c),
                    onDelete: (c) => _confirmDelete(context, c),
                    onLoyalty: (c) => _showLoyalty(context, c),
                  ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showForm(BuildContext context, {CustomerModel? customer}) {
    showDialog(
      context: context,
      builder: (_) => CustomerFormDialog(
        customer: customer,
        branchId: customer?.branchId ?? _currentBranchId,
        onSave: (c) async {
          final error = customer == null
              ? await ref.read(customerProvider.notifier).createCustomer(c)
              : await ref.read(customerProvider.notifier).updateCustomer(c);
          if (error != null) _snack(error, error: true);
        },
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
            onPressed: () async {
              Navigator.pop(context);
              final error = await ref
                  .read(customerProvider.notifier)
                  .deleteCustomer(customer.id);
              if (error != null) _snack(error, error: true);
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
  final PaginatedListState<CustomerModel> state;
  final CustomerNotifier notifier;
  final Function(CustomerModel) onEdit;
  final Function(CustomerModel) onDelete;
  final Function(CustomerModel) onLoyalty;

  const _DesktopTable({
    required this.state,
    required this.notifier,
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
                child: PaginatedListView<CustomerModel>(
                  state: state,
                  padding: EdgeInsets.zero,
                  onLoadMore: notifier.loadMore,
                  onRefresh: notifier.refresh,
                  emptyText: 'No customers found',
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: Color(0xFFE7E9F0)),
                  itemBuilder: (_, c, __) {
                    return DecoratedBox(
                      decoration: const BoxDecoration(),
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
                            if (c.isWalkIn) ...[
                              const SizedBox(width: 6),
                              const _SharedBadge(),
                            ],
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
                                const AppIcon(AppIcons.star,
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
                              child: c.isWalkIn
                                  ? Text('Shared across branches',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                          fontStyle: FontStyle.italic))
                                  : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(children: [
                                _IconBtn(
                                  icon: AppIcons.starOutline,
                                  color: const Color(0xFFD4A017),
                                  tooltip: 'Loyalty Points',
                                  onTap: () => onLoyalty(c),
                                ),
                                const SizedBox(width: 6),
                                _IconBtn(
                                  icon: AppIcons.editOutlined,
                                  color: const Color(0xFF3E63DD),
                                  tooltip: 'Edit',
                                  onTap: () => onEdit(c),
                                ),
                                const SizedBox(width: 6),
                                _IconBtn(
                                  icon: AppIcons.deleteOutline,
                                  color: Colors.redAccent,
                                  tooltip: 'Delete',
                                  onTap: () => onDelete(c),
                                ),
                              ]))),
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
  final PaginatedListState<CustomerModel> state;
  final CustomerNotifier notifier;
  final Function(CustomerModel) onEdit;
  final Function(CustomerModel) onDelete;
  final Function(CustomerModel) onLoyalty;

  const _MobileList({
    required this.state,
    required this.notifier,
    required this.onEdit,
    required this.onDelete,
    required this.onLoyalty,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<CustomerModel>(
      state: state,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      onLoadMore: notifier.loadMore,
      onRefresh: notifier.refresh,
      emptyText: 'No customers found',
      itemBuilder: (_, c, __) {
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
                        Row(children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          if (c.isWalkIn) ...[
                            const SizedBox(width: 6),
                            const _SharedBadge(),
                          ],
                        ]),
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
                  const AppIcon(AppIcons.star,
                      size: 14, color: Color(0xFFD4A017)),
                  const SizedBox(width: 4),
                  Text('${c.loyaltyPoints} pts',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  const AppIcon(AppIcons.accountBalanceWalletOutlined,
                      size: 14, color: Color(0xFF8A8FA3)),
                  const SizedBox(width: 4),
                  Text('Rs. ${c.openingBalance.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              if (c.isWalkIn)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Shared across branches',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic)),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _IconBtn(
                        icon: AppIcons.starOutline,
                        color: const Color(0xFFD4A017),
                        tooltip: 'Loyalty',
                        onTap: () => onLoyalty(c)),
                    const SizedBox(width: 8),
                    _IconBtn(
                        icon: AppIcons.editOutlined,
                        color: const Color(0xFF3E63DD),
                        tooltip: 'Edit',
                        onTap: () => onEdit(c)),
                    const SizedBox(width: 8),
                    _IconBtn(
                        icon: AppIcons.deleteOutline,
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

class _SharedBadge extends StatelessWidget {
  const _SharedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFFD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('Shared',
          style: TextStyle(
              color: Color(0xFF3E63DD), fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

InputDecoration _searchDecor(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
  prefixIcon: const TextFieldIcon(AppIcons.search, size: 24, color: Color(0xFF8A8FA3)),
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