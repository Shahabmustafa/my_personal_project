import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/employee_salary_model.dart';
import '../providers/employee_salary_providers.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Ek employee ke pichle mahinon ka archived total_sales/total_sales_return/
/// net_salary — har mahine ki 1 tareekh ko reset se pehle jo record
/// employee_salary_history mein archive hota hai wo yahan dikhta hai.
class EmployeeSalaryHistoryDialog extends ConsumerWidget {
  final EmployeeSalaryModel salary;

  const EmployeeSalaryHistoryDialog({super.key, required this.salary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(employeeSalaryHistoryProvider(salary.id));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${salary.userName} — Salary History',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      content: SizedBox(
        width: 420,
        height: 360,
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (history) {
            if (history.isEmpty) {
              return const Center(
                child: Text('No previous month history yet',
                    style: TextStyle(color: Color(0xFF8A8FA3))),
              );
            }
            return ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (_, i) {
                final h = history[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEFFD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const AppIcon(AppIcons.history,
                          size: 16, color: Color(0xFF3E63DD)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_monthLabel(h.periodMonth),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                              'Sale: Rs. ${h.totalSales.toStringAsFixed(0)}   '
                              'Return: Rs. ${h.totalSalesReturn.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF8A8FA3))),
                        ],
                      ),
                    ),
                    Text('Rs. ${h.netSalary.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF3E63DD))),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _monthLabel(DateTime d) => '${_months[d.month - 1]} ${d.year}';
}
