import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/employee_salary_report_row.dart';
import '../providers/employee_salary_report_provider.dart';
import '../widgets/employee_salary_detail_screen.dart';
import '../widgets/report_branch_filter_dropdown.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_table_shell.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Har employee ka mahine-wise salary report — basic salary, sale, return,
/// commission aur net salary. Current mahina live, pichle mahine history se.
/// Row par click → us employee ki saare mahinon ki detail.
class EmployeeSalaryReportScreen extends ConsumerStatefulWidget {
  const EmployeeSalaryReportScreen({super.key});

  @override
  ConsumerState<EmployeeSalaryReportScreen> createState() =>
      _EmployeeSalaryReportScreenState();
}

class _EmployeeSalaryReportScreenState
    extends ConsumerState<EmployeeSalaryReportScreen> {
  static const _accent = Color(0xFF3E63DD);
  static const _green = Color(0xFF22A06B);
  static const _orange = Color(0xFFE56A00);
  static const _grey = Color(0xFF8A8FA3);

  /// Set hone par report ki jagah us employee ki detail screen dikhti hai.
  EmployeeSalaryReportRow? _selected;

  static String _amt(double v) => 'Rs. ${v.toStringAsFixed(0)}';

  void _open(EmployeeSalaryReportRow r) => setState(() => _selected = r);

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      return EmployeeSalaryDetailScreen(
        key: ValueKey(selected.employeeSalaryId),
        row: selected,
        onBack: () => setState(() => _selected = null),
      );
    }

    final state = ref.watch(employeeSalaryReportProvider);
    final notifier = ref.read(employeeSalaryReportProvider.notifier);
    final isMobile = Responsive(context).isMobile;

    final cards = [
      ReportSummaryCard(
        label: 'Employees',
        value: '${state.rows.length}',
        icon: AppIcons.peopleOutline,
        color: _accent,
      ),
      ReportSummaryCard(
        label: 'Total Salary',
        value: _amt(state.totalSalary),
        icon: AppIcons.paymentsOutlined,
        color: _accent,
      ),
      ReportSummaryCard(
        label: 'Total Commission',
        value: _amt(state.totalCommission),
        icon: AppIcons.percentOutlined,
        color: _orange,
      ),
      ReportSummaryCard(
        label: 'Total Net Salary',
        value: _amt(state.totalNetSalary),
        icon: AppIcons.accountBalanceWalletOutlined,
        color: _green,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Employee Salary',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const AppIcon(AppIcons.refresh, size: 18),
                onPressed: notifier.load,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const AppIcon(AppIcons.chevronLeft, size: 20),
                    tooltip: 'Previous month',
                    onPressed: () => notifier.shift(-1),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(state.periodLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.chevronRight, size: 20),
                    tooltip: 'Next month',
                    onPressed:
                        state.canGoNext ? () => notifier.shift(1) : null,
                  ),
                ],
              ),
              ReportBranchFilterDropdown(
                value: state.branchId,
                onChanged: notifier.setBranch,
              ),
              if (state.isCurrentMonth)
                const Text('Current month — numbers update with every sale',
                    style: TextStyle(fontSize: 12, color: _grey)),
            ],
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(children: [
                  for (final c in cards)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10), child: c),
                ])
              : Row(children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ]),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Error: ${state.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.rows.isEmpty
                    ? Center(
                        child: Text(
                            'No salary records for ${state.periodLabel}',
                            style: const TextStyle(color: _grey)))
                    : isMobile
                        ? _MobileList(rows: state.rows, onOpen: _open)
                        : SingleChildScrollView(
                            child: ReportTableShell(
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Employee')),
                                DataColumn(label: Text('Branch')),
                                DataColumn(
                                    label: Text('Salary'), numeric: true),
                                DataColumn(
                                    label: Text('Commission %'),
                                    numeric: true),
                                DataColumn(
                                    label: Text('Total Sale'), numeric: true),
                                DataColumn(
                                    label: Text('Return'), numeric: true),
                                DataColumn(
                                    label: Text('Net Sale'), numeric: true),
                                DataColumn(
                                    label: Text('Commission'), numeric: true),
                                DataColumn(
                                    label: Text('Net Salary'), numeric: true),
                              ],
                              rows: [
                                for (var i = 0; i < state.rows.length; i++)
                                  _row(i + 1, state.rows[i]),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  DataRow _row(int serial, EmployeeSalaryReportRow r) =>
      DataRow(onSelectChanged: (_) => _open(r), cells: [
        DataCell(Text('$serial', style: const TextStyle(color: _grey))),
        DataCell(Text(r.userName,
            style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(r.branchName, style: const TextStyle(color: _grey))),
        DataCell(Text(_amt(r.salary))),
        DataCell(Text('${r.commissionPercent.toStringAsFixed(1)}%')),
        DataCell(Text(_amt(r.totalSales))),
        DataCell(Text(_amt(r.totalSalesReturn),
            style: TextStyle(
                color: r.totalSalesReturn > 0 ? Colors.red : null))),
        DataCell(Text(_amt(r.netSale))),
        DataCell(Text(_amt(r.commissionAmount),
            style: const TextStyle(color: _orange))),
        DataCell(Text(_amt(r.netSalary),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: _green))),
      ]);
}

/// Phone width par table ki jagah har employee ka ek card.
class _MobileList extends StatelessWidget {
  final List<EmployeeSalaryReportRow> rows;
  final void Function(EmployeeSalaryReportRow) onOpen;
  const _MobileList({required this.rows, required this.onOpen});

  static String _amt(double v) => 'Rs. ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = rows[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onOpen(r),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E9F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(r.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(r.branchName,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8FA3))),
                ]),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _stat('Salary', _amt(r.salary)),
                    _stat('Net Sale', _amt(r.netSale)),
                    _stat(
                        'Commission (${r.commissionPercent.toStringAsFixed(1)}%)',
                        _amt(r.commissionAmount),
                        color: const Color(0xFFE56A00)),
                    _stat('Net Salary', _amt(r.netSalary),
                        color: const Color(0xFF22A06B)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, {Color? color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF8A8FA3))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF2D2D3A))),
        ],
      );
}
