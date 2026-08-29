import 'package:flutter/material.dart';
import '../../data/models/employee_salary_model.dart';

class EmployeeSalaryCard extends StatelessWidget {
  final EmployeeSalaryModel salary;
  final VoidCallback onDelete;

  const EmployeeSalaryCard(
      {super.key, required this.salary, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFFD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline,
                    size: 18, color: Color(0xFF3E63DD)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salary.userName.isEmpty ? '—' : salary.userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      salary.branchName.isEmpty ? '—' : salary.branchName,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8A8FA3)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.redAccent),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                  child: _Stat(label: 'Salary', value: salary.salary)),
              Expanded(
                  child: _Stat(
                      label: 'Commission', value: salary.commissionPercent,
                      suffix: '%')),
              Expanded(
                  child: _Stat(
                      label: 'Net Salary',
                      value: salary.netSalary,
                      highlight: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _Stat(label: 'Total Sale', value: salary.totalSales)),
              Expanded(
                  child: _Stat(
                      label: 'Total Return',
                      value: salary.totalSalesReturn,
                      isReturn: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double value;
  final String suffix;
  final bool highlight;
  final bool isReturn;

  const _Stat({
    required this.label,
    required this.value,
    this.suffix = '',
    this.highlight = false,
    this.isReturn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
        const SizedBox(height: 2),
        Text(
          suffix.isNotEmpty
              ? '${value.toStringAsFixed(1)}$suffix'
              : isReturn && value > 0
                  ? '- Rs. ${value.toStringAsFixed(0)}'
                  : 'Rs. ${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlight
                ? const Color(0xFF3E63DD)
                : isReturn && value > 0
                    ? Colors.red.shade400
                    : const Color(0xFF2D2D3A),
          ),
        ),
      ],
    );
  }
}
