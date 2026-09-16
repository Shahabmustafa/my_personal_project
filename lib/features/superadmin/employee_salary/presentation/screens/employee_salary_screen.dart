import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/employee_salary_model.dart';
import '../providers/employee_salary_providers.dart';
import '../widgets/employee_salary_card.dart';
import '../widgets/employee_salary_form_dialog.dart';
import '../widgets/employee_salary_history_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class EmployeeSalaryScreen extends ConsumerStatefulWidget {
  const EmployeeSalaryScreen({super.key});

  @override
  ConsumerState<EmployeeSalaryScreen> createState() =>
      _EmployeeSalaryScreenState();
}

class _EmployeeSalaryScreenState extends ConsumerState<EmployeeSalaryScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(employeeSalariesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final salariesAsync = ref.watch(employeeSalariesProvider);
    final isMobile       = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: salariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(employeeSalariesProvider),
        ),
        data: (salaries) {
          final filtered = salaries.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.userName.toLowerCase().contains(q) ||
                s.branchName.toLowerCase().contains(q);
          }).toList();

          return Column(
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
                        const Text('Employee Salary',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('${salaries.length} total records',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const AppIcon(AppIcons.add, size: 18, color: Colors.white),
                      label: const Text('Add Salary'),
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

              // ── Search ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: _searchDecor('Search by employee, branch...'),
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyView()
                    : isMobile
                        ? _MobileList(
                            salaries: filtered,
                            onDelete: (s) => _confirmDelete(context, s),
                            onHistory: (s) => _showHistory(context, s),
                          )
                        : _DesktopTable(
                            salaries: filtered,
                            onDelete: (s) => _confirmDelete(context, s),
                            onHistory: (s) => _showHistory(context, s),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Add Dialog ─────────────────────────────────────────────────────────────

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EmployeeSalaryFormDialog(
        onSave: ({
          required userId,
          required branchId,
          required salary,
          required commissionPercent,
          required totalSales,
          required totalSalesReturn,
        }) async {
          try {
            await ref.read(employeeSalaryRepositoryProvider).addEmployeeSalary(
                  userId:            userId,
                  branchId:          branchId,
                  salary:            salary,
                  commissionPercent: commissionPercent,
                  totalSales:        totalSales,
                  totalSalesReturn:  totalSalesReturn,
                );
            ref.invalidate(employeeSalariesProvider);
            if (context.mounted) {
              _snack(context, 'Salary added successfully!', Colors.green);
            }
          } catch (e) {
            if (context.mounted) {
              _snack(context, 'Error: $e', Colors.red);
            }
          }
        },
      ),
    );
  }

  // ── Confirm Delete ─────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, EmployeeSalaryModel salary) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Salary Record?'),
        content: Text(
            'Delete the salary record of "${salary.userName}" – ${salary.branchName}?'),
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
              try {
                await ref
                    .read(employeeSalaryRepositoryProvider)
                    .removeEmployeeSalary(salary.id);
                ref.invalidate(employeeSalariesProvider);
                if (context.mounted) {
                  _snack(context, 'Record deleted successfully!', Colors.orange);
                }
              } catch (e) {
                if (context.mounted) {
                  _snack(context, 'Error: $e', Colors.red);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── History Dialog ─────────────────────────────────────────────────────────

  void _showHistory(BuildContext context, EmployeeSalaryModel salary) {
    showDialog(
      context: context,
      builder: (_) => EmployeeSalaryHistoryDialog(salary: salary),
    );
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<EmployeeSalaryModel> salaries;
  final Function(EmployeeSalaryModel) onDelete;
  final Function(EmployeeSalaryModel) onHistory;

  const _DesktopTable(
      {required this.salaries, required this.onDelete, required this.onHistory});

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
                  border:
                      Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  _TH('#',            flex: 1),
                  _TH('Employee',     flex: 3),
                  _TH('Branch',       flex: 3),
                  _TH('Salary',       flex: 2),
                  _TH('Commission',   flex: 2),
                  _TH('Total Sale',   flex: 2),
                  _TH('Net Salary',   flex: 2),
                  _TH('Date',         flex: 2),
                  _TH('Action',       flex: 2),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: salaries.length,
                  itemBuilder: (_, i) {
                    final s      = salaries[i];
                    final isLast = i == salaries.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? Colors.white
                            : const Color(0xFFF7F8FC),
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                    color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        Expanded(
                          flex: 1,
                          child: _TD(
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8A8FA3))),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Text(
                              s.userName.isEmpty ? '—' : s.userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Text(
                              s.branchName.isEmpty ? '—' : s.branchName,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF8A8FA3)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Text('Rs. ${s.salary.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Text(
                                '${s.commissionPercent.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Text('Rs. ${s.netSale.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAEFFD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Rs. ${s.netSalary.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF3E63DD),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Text(
                              _fmt(s.createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF8A8FA3)),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _IconBtn(
                                  icon: AppIcons.history,
                                  color: const Color(0xFF3E63DD),
                                  tooltip: 'History',
                                  onTap: () => onHistory(s),
                                ),
                                const SizedBox(width: 6),
                                _IconBtn(
                                  icon: AppIcons.deleteOutline,
                                  color: Colors.redAccent,
                                  tooltip: 'Delete',
                                  onTap: () => onDelete(s),
                                ),
                              ],
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

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<EmployeeSalaryModel> salaries;
  final Function(EmployeeSalaryModel) onDelete;
  final Function(EmployeeSalaryModel) onHistory;

  const _MobileList(
      {required this.salaries, required this.onDelete, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: salaries.length,
      itemBuilder: (_, i) => EmployeeSalaryCard(
        salary: salaries[i],
        onDelete: () => onDelete(salaries[i]),
        onHistory: () => onHistory(salaries[i]),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(text,
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
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child);
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
  Widget build(BuildContext context) => Tooltip(
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const AppIcon(AppIcons.errorOutline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AppIcon(AppIcons.paymentsOutlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('No salary records found',
              style: TextStyle(color: Color(0xFF8A8FA3))),
        ]),
      );
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
