import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/employee_salary_report_row.dart';
import '../providers/employee_salary_report_provider.dart';
import 'report_summary_card.dart';
import 'report_table_shell.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Employee Salary report mein employee par click karne par khulne wali
/// screen — us employee ka har mahine ka salary, sale, commission aur net
/// salary (current mahina live, baqi history se).
class EmployeeSalaryDetailScreen extends ConsumerWidget {
  final EmployeeSalaryReportRow row;
  final VoidCallback onBack;

  const EmployeeSalaryDetailScreen(
      {super.key, required this.row, required this.onBack});

  static const _accent = Color(0xFF3E63DD);
  static const _green = Color(0xFF22A06B);
  static const _orange = Color(0xFFE56A00);
  static const _grey = Color(0xFF8A8FA3);

  static String _amt(double v) => 'Rs. ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(employeeSalaryMonthsProvider(row.employeeSalaryId));
    final isMobile = Responsive(context).isMobile;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${row.userName} — Salary Report',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                    Text(
                        '${row.branchName}  •  Commission ${row.commissionPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12, color: _grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const AppIcon(AppIcons.refresh, size: 18),
                onPressed: () => ref.invalidate(
                    employeeSalaryMonthsProvider(row.employeeSalaryId)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.red))),
              data: (months) {
                final totalSalary = months.fold(0.0, (s, m) => s + m.salary);
                final totalCommission =
                    months.fold(0.0, (s, m) => s + m.commissionAmount);
                final totalNet = months.fold(0.0, (s, m) => s + m.netSalary);
                final cards = [
                  ReportSummaryCard(
                    label: 'Months',
                    value: '${months.length}',
                    icon: AppIcons.calendarTodayOutlined,
                    color: _accent,
                  ),
                  ReportSummaryCard(
                    label: 'Total Salary',
                    value: _amt(totalSalary),
                    icon: AppIcons.paymentsOutlined,
                    color: _accent,
                  ),
                  ReportSummaryCard(
                    label: 'Total Commission',
                    value: _amt(totalCommission),
                    icon: AppIcons.percentOutlined,
                    color: _orange,
                  ),
                  ReportSummaryCard(
                    label: 'Total Net Salary',
                    value: _amt(totalNet),
                    icon: AppIcons.accountBalanceWalletOutlined,
                    color: _green,
                  ),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isMobile
                        ? Column(children: [
                            for (final c in cards)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: c),
                          ])
                        : Row(children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(width: 14),
                              Expanded(child: cards[i]),
                            ],
                          ]),
                    const SizedBox(height: 16),
                    Expanded(
                      child: months.isEmpty
                          ? const Center(child: Text('No salary records'))
                          : SingleChildScrollView(
                              child: ReportTableShell(
                                columns: const [
                                  DataColumn(label: Text('Month')),
                                  DataColumn(
                                      label: Text('Salary'), numeric: true),
                                  DataColumn(
                                      label: Text('Commission %'),
                                      numeric: true),
                                  DataColumn(
                                      label: Text('Total Sale'),
                                      numeric: true),
                                  DataColumn(
                                      label: Text('Return'), numeric: true),
                                  DataColumn(
                                      label: Text('Net Sale'), numeric: true),
                                  DataColumn(
                                      label: Text('Commission'),
                                      numeric: true),
                                  DataColumn(
                                      label: Text('Net Salary'),
                                      numeric: true),
                                ],
                                rows: [for (final m in months) _row(m)],
                              ),
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

  DataRow _row(EmployeeSalaryReportRow m) => DataRow(cells: [
        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
          Text(EmployeeSalaryReportState.monthLabel(m.month),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (m.isLive) ...[
            const SizedBox(width: 8),
            const _LiveBadge(),
          ],
        ])),
        DataCell(Text(_amt(m.salary))),
        DataCell(Text('${m.commissionPercent.toStringAsFixed(1)}%')),
        DataCell(Text(_amt(m.totalSales))),
        DataCell(Text(_amt(m.totalSalesReturn),
            style: TextStyle(
                color: m.totalSalesReturn > 0 ? Colors.red : null))),
        DataCell(Text(_amt(m.netSale))),
        DataCell(Text(_amt(m.commissionAmount),
            style: const TextStyle(color: _orange))),
        DataCell(Text(_amt(m.netSalary),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: _green))),
      ]);
}

/// "In progress" — current mahina abhi khatam nahi hua.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3E63DD).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('In progress',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3E63DD))),
    );
  }
}
