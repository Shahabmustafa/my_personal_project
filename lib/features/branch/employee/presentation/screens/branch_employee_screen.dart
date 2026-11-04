import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../superadmin/employee_salary/data/models/employee_salary_model.dart';
import '../../../../superadmin/employee_salary/presentation/providers/employee_salary_providers.dart';

import '../providers/employee_detail_provider.dart';
import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
import 'package:safishoe_app/core/utils/error_text.dart';
import 'package:safishoe_app/core/widget/error_view.dart' as shared;
const _primary = Color(0xFF3E63DD);

/// Dedicated, read-only employee list for a branch — sourced entirely from
/// `employee_salary` (name/role via its join, plus salary/commission/sale/
/// return figures), NOT from the `users`/`user_branches` tables. An
/// employee only shows up here once a salary record exists for them in
/// this branch.
class BranchEmployeeScreen extends ConsumerStatefulWidget {
  const BranchEmployeeScreen({super.key});

  @override
  ConsumerState<BranchEmployeeScreen> createState() => _BranchEmployeeScreenState();
}

class _BranchEmployeeScreenState extends ConsumerState<BranchEmployeeScreen> {
  String _searchQuery = '';
  EmployeeSalaryModel? _selected;

  void _select(EmployeeSalaryModel e) {
    if (MediaQuery.of(context).size.width < 768) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, c) => SingleChildScrollView(
              controller: c, child: _EmployeeDetailPanel(employee: e)),
        ),
      );
    } else {
      setState(() => _selected = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salariesAsync = ref.watch(employeeSalariesForBranchProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Employees',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(
                        '${salariesAsync.value?.length ?? 0} employee${(salariesAsync.value?.length ?? 0) == 1 ? '' : 's'} in this branch',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
                Tooltip(
                  message: 'Refresh',
                  child: InkWell(
                    onTap: () => ref.invalidate(employeeSalariesForBranchProvider),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE7E9F0)),
                      ),
                      child: const AppIcon(AppIcons.refresh, color: _primary, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: TextField(cursorHeight: 16,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: _searchDecor('Search by name or role...'),
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: salariesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(employeeSalariesForBranchProvider),
              ),
              data: (salaries) {
                // Har employee ki is branch ki sab se recent salary entry
                // (create hone par history rakhi ja sakti hai — yahan
                // sirf current/latest snapshot dikhana hai).
                final latestByUser = <String, EmployeeSalaryModel>{};
                for (final s in salaries) {
                  latestByUser.putIfAbsent(s.userId, () => s);
                }

                final q = _searchQuery.toLowerCase();
                final filtered = latestByUser.values.where((s) {
                  return s.userName.toLowerCase().contains(q) ||
                      s.userRole.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) return const _EmptyView();
                if (isMobile) {
                  return _MobileList(entries: filtered, onTap: _select);
                }
                final sel = _selected;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _DesktopTable(
                          entries: filtered,
                          selectedUserId: sel?.userId,
                          onTap: _select),
                    ),
                    if (sel != null)
                      Container(
                        width: 380,
                        margin: const EdgeInsets.fromLTRB(0, 0, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE7E9F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(children: [
                            SingleChildScrollView(
                                child: _EmployeeDetailPanel(
                                    key: ValueKey(sel.userId), employee: sel)),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: IconButton(
                                tooltip: 'Close',
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => setState(() => _selected = null),
                              ),
                            ),
                          ]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<EmployeeSalaryModel> entries;
  final String? selectedUserId;
  final void Function(EmployeeSalaryModel) onTap;
  const _DesktopTable(
      {required this.entries, required this.onTap, this.selectedUserId});

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
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: const Row(children: [
                  _TH('Name', flex: 3),
                  _TH('Role', flex: 2),
                  _TH('Salary', flex: 2, alignEnd: true),
                  _TH('Commission', flex: 2, alignEnd: true),
                  _TH('Sale', flex: 2, alignEnd: true),
                  _TH('Net Salary', flex: 2, alignEnd: true),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE7E9F0)),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return InkWell(
                      onTap: () => onTap(e),
                      child: Container(
                      color: e.userId == selectedUserId
                          ? const Color(0xFFEAEFFD)
                          : i.isEven ? Colors.white : const Color(0xFFFAFAFC),
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Row(children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFEAEFFD),
                                child: Text(
                                  e.userName.isNotEmpty ? e.userName[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                      color: _primary, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.userName,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ),
                        ),
                        Expanded(flex: 2, child: _TD(child: _RoleBadge(role: _roleLabel(e.userRole)))),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Rs. ${_fmtAmt(e.salary)}',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('${_fmtAmt(e.commissionPercent)}%',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Rs. ${_fmtAmt(e.netSale)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Rs. ${_fmtAmt(e.netSalary)}',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
                            ),
                          ),
                        ),
                      ]),
                    ));
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

// ── Mobile List ───────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<EmployeeSalaryModel> entries;
  final void Function(EmployeeSalaryModel) onTap;
  const _MobileList({required this.entries, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return InkWell(
          onTap: () => onTap(e),
          borderRadius: BorderRadius.circular(12),
          child: Container(
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
                    child: Text(e.userName.isNotEmpty ? e.userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.userName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        _RoleBadge(role: _roleLabel(e.userRole)),
                      ],
                    ),
                  ),
                  Text('Rs. ${_fmtAmt(e.salary)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE7E9F0)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statColumn('Commission', '${_fmtAmt(e.commissionPercent)}%',
                      const Color(0xFF8A8FA3)),
                  const SizedBox(width: 20),
                  _statColumn('Sale', 'Rs. ${_fmtAmt(e.netSale)}', const Color(0xFF2D2D3A)),
                ],
              ),
              const SizedBox(height: 10),
              _statColumn('Net Salary', 'Rs. ${_fmtAmt(e.netSalary)}', _primary),
            ],
          ),
        ));
      },
    );
  }

  Widget _statColumn(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignEnd;
  const _TH(this.text, {this.flex = 1, this.alignEnd = false});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(text,
              textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A8FA3),
                  letterSpacing: 0.3)),
        ),
      );
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: child);
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    // Align se badge text jitna hi chaura rehta hai (table cell ki poori
    // width nahi leta), aur text pill ke beech mein aata hai.
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFEAEFFD), borderRadius: BorderRadius.circular(20)),
        child: Text(role,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object? message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) =>
      shared.ErrorView(error: message, onRetry: onRetry);
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AppIcon(AppIcons.peopleOutline, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        const Text('No employees found for this branch', style: TextStyle(color: Color(0xFF8A8FA3))),
        const SizedBox(height: 4),
        Text('Add a salary record for an employee to see them here.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ]),
    );
  }
}

String _roleLabel(String role) {
  const map = {
    'superadmin': 'Super Admin',
    'manager': 'Manager',
    'supervisor': 'Supervisor',
    'warehouse_manager': 'WH Manager',
    'inventory_manager': 'Inv Manager',
    'cashier': 'Cashier',
    'salesman': 'Salesman',
  };
  return map[role] ?? (role.isEmpty ? '—' : role);
}

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

InputDecoration _searchDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
      prefixIcon: const TextFieldIcon(AppIcons.search, size: 18, color: Color(0xFF8A8FA3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5)),
    );


// ── Employee detail panel (right slider / bottom sheet) ─────────────────────

class _EmployeeDetailPanel extends ConsumerWidget {
  final EmployeeSalaryModel employee;
  const _EmployeeDetailPanel({super.key, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = employee;
    final detailAsync =
        ref.watch(employeeDetailProvider((userId: e.userId, branchId: e.branchId)));
    final d = detailAsync.value;
    final month = const [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ][DateTime.now().month - 1];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFEAEFFD),
              child: Text(e.userName.isNotEmpty ? e.userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: _primary, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.userName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _RoleBadge(role: _roleLabel(e.userRole)),
              ]),
            ),
            const SizedBox(width: 28),
          ]),
          const SizedBox(height: 20),
          _section('Contact'),
          _row('Email', d == null ? '…' : (d.email.isEmpty ? '—' : d.email)),
          _row('Phone', d == null ? '…' : (d.phone.isEmpty ? '—' : d.phone)),
          _row('Branch', e.branchName.isEmpty ? '—' : e.branchName),
          _row('Status', d == null ? '…' : (d.isActive ? 'Active' : 'Inactive')),
          const SizedBox(height: 16),
          _section('Salary'),
          _row('Base Salary', 'Rs. ${_fmtAmt(e.salary)}'),
          _row('Commission %', '${_fmtAmt(e.commissionPercent)}%'),
          _row('Total Sale', 'Rs. ${_fmtAmt(e.totalSales)}'),
          _row('Sale Return', 'Rs. ${_fmtAmt(e.totalSalesReturn)}'),
          _row('Net Sale', 'Rs. ${_fmtAmt(e.netSale)}'),
          _row('Net Salary', 'Rs. ${_fmtAmt(e.netSalary)}', bold: true, color: _primary),
          const SizedBox(height: 16),
          _section('This month ($month)'),
          if (detailAsync.isLoading)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (detailAsync.hasError)
            Text(friendlyError(detailAsync.error),
                style: const TextStyle(color: Colors.redAccent, fontSize: 12))
          else if (d != null) ...[
            _row('Pairs Sold', '${d.pairs}', bold: true),
            _row('Invoices', '${d.invoices}'),
            _row('Sale Amount', 'Rs. ${_fmtAmt(d.saleAmount)}'),
            _row('Commission Earned', 'Rs. ${_fmtAmt(d.commissionEarned)}'),
          ],
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Color(0xFF8A8FA3))),
      );

  Widget _row(String label, String value, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: color ?? const Color(0xFF2D2D3A))),
          ),
        ]),
      );
}
