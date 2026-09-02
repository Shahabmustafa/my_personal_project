import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../superadmin/employee_salary/data/models/employee_salary_model.dart';
import '../../../../superadmin/employee_salary/presentation/providers/employee_salary_providers.dart';

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
                      child: const Icon(Icons.refresh, color: _primary, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: _searchDecor('Search by name or role...'),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: salariesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e.toString(),
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

                return filtered.isEmpty
                    ? const _EmptyView()
                    : isMobile
                        ? _MobileList(entries: filtered)
                        : _DesktopTable(entries: filtered);
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
  const _DesktopTable({required this.entries});

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
                  _TH('Return', flex: 2, alignEnd: true),
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
                    return Container(
                      color: i.isEven ? Colors.white : const Color(0xFFFAFAFC),
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
                              child: Text('Rs. ${_fmtAmt(e.totalSales)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                  e.totalSalesReturn > 0 ? '- Rs. ${_fmtAmt(e.totalSalesReturn)}' : 'Rs. 0',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: e.totalSalesReturn > 0
                                          ? Colors.red.shade400
                                          : const Color(0xFF8A8FA3))),
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

// ── Mobile List ───────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<EmployeeSalaryModel> entries;
  const _MobileList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
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
                  _statColumn('Sale', 'Rs. ${_fmtAmt(e.totalSales)}', const Color(0xFF2D2D3A)),
                  const SizedBox(width: 20),
                  _statColumn(
                      'Return',
                      e.totalSalesReturn > 0 ? '- Rs. ${_fmtAmt(e.totalSalesReturn)}' : 'Rs. 0',
                      e.totalSalesReturn > 0 ? Colors.red.shade400 : const Color(0xFF8A8FA3)),
                ],
              ),
              const SizedBox(height: 10),
              _statColumn('Net Salary', 'Rs. ${_fmtAmt(e.netSalary)}', _primary),
            ],
          ),
        );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFEAEFFD), borderRadius: BorderRadius.circular(20)),
      child: Text(role,
          style: const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w600),
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
      prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8FA3)),
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
