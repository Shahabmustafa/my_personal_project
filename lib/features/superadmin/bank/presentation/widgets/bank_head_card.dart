import 'package:flutter/material.dart';
import '../../data/models/bank_head_model.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class BankHeadCard extends StatelessWidget {
  final BankHeadModel bank;
  final VoidCallback onDelete;

  const BankHeadCard({super.key, required this.bank, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFFD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const AppIcon(AppIcons.accountBalanceOutlined,
                color: Color(0xFF3E63DD), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bank.bankName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const AppIcon(AppIcons.calendarTodayOutlined,
                        size: 12, color: Color(0xFF8A8FA3)),
                    const SizedBox(width: 4),
                    Text(
                      _fmt(bank.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8A8FA3)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppIcon(AppIcons.deleteOutline,
                  size: 18, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
