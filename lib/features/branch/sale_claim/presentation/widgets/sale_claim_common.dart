import 'package:flutter/material.dart';
import '../../data/model/sale_claim_model.dart';

/// pending / approved / rejected badge — branch aur admin dono screens mein.
class SaleClaimStatusChip extends StatelessWidget {
  final String status;
  const SaleClaimStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'approved' => (Colors.green.shade50, Colors.green.shade700, 'Approved'),
      'rejected' => (Colors.red.shade50, Colors.red.shade700, 'Rejected'),
      _ => (Colors.orange.shade50, Colors.orange.shade700, 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

String claimFmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/'
    '${dt.month.toString().padLeft(2, '0')}/'
    '${dt.year}';

/// Table ke Reason/Remarks columns — lamba text ellipsis + hover par poora.
class SaleClaimTextCell extends StatelessWidget {
  final String? text;
  const SaleClaimTextCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final value = (text ?? '').trim();
    if (value.isEmpty) return const Text('—');
    return Tooltip(
      message: value,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Claim ki product detail ke DataCells ke liye ek line: "Article · Brand".
String claimProductLabel(SaleClaimModel c) {
  final name = c.productName ?? '—';
  final brand = c.brandName;
  return brand == null || brand.isEmpty ? name : '$name · $brand';
}
