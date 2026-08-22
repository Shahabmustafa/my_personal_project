import 'package:flutter/material.dart';
import '../../data/models/bank_entry_model.dart';

class BankEntryCard extends StatelessWidget {
  final BankEntryModel entry;
  final VoidCallback onDelete;

  const BankEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFFD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_outlined,
                color: Color(0xFF3E63DD), size: 22),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank name + balance badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.bankName.isEmpty ? 'Unknown Bank' : entry.bankName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    _BalanceBadge(amount: entry.openingBalance),
                  ],
                ),
                const SizedBox(height: 8),

                // Branch section card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE7E9F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5E6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.store_outlined,
                            size: 15, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.branchName.isEmpty
                                  ? 'Unknown Branch'
                                  : entry.branchName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF2D2D3A)),
                            ),
                            if (entry.branchAddress.isNotEmpty ||
                                entry.branchCity.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              _IconRow(
                                icon: Icons.location_on_outlined,
                                text: [entry.branchAddress, entry.branchCity]
                                    .where((s) => s.isNotEmpty)
                                    .join(', '),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Account number
                if (entry.accountNumber.isNotEmpty)
                  _IconRow(
                    icon: Icons.numbers_outlined,
                    text: 'A/C: ${entry.accountNumber}',
                    bold: true,
                  ),

                const SizedBox(height: 4),
                _IconRow(
                  icon: Icons.calendar_today_outlined,
                  text: _fmt(entry.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          _ActionBtn(
            icon: Icons.delete_outline,
            color: Colors.redAccent,
            onTap: onDelete,
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

// ─────────────────────────────────────────────────────────────────────────────

class _BalanceBadge extends StatelessWidget {
  final double amount;
  const _BalanceBadge({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFFD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Rs. ${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Color(0xFF3E63DD),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  const _IconRow({required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF8A8FA3)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: bold ? const Color(0xFF2D2D3A) : const Color(0xFF8A8FA3),
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
