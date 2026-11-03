import 'package:safishoe_app/core/utils/date_format.dart' as dfmt;
import 'package:flutter/material.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/app_icon.dart';
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

String claimFmtDate(DateTime dt) => dfmt.fmtDateTime(dt);

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

const saleClaimAccent = Color(0xFFE56A00);

/// Search: claim no, invoice, customer, product, brand, branch, barcode.
bool saleClaimMatchesSearch(SaleClaimModel c, String q) {
  final query = q.trim().toLowerCase();
  if (query.isEmpty) return true;
  return [
    c.claimNumber,
    c.invoiceNumber,
    c.customerName,
    c.productName,
    c.brandName,
    c.branchName,
    c.barcode,
  ].any((v) => (v ?? '').toLowerCase().contains(query));
}

/// Old / Damaged badge.
class SaleClaimConditionChip extends StatelessWidget {
  final SaleClaimModel claim;
  const SaleClaimConditionChip(this.claim, {super.key});

  @override
  Widget build(BuildContext context) {
    final damaged = claim.shoeCondition == 'damaged';
    final c = damaged ? Colors.red.shade600 : Colors.blueGrey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(claim.shoeConditionLabel,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

/// Search textfield — branch aur admin dono screens mein.
class SaleClaimSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;
  const SaleClaimSearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search claim no, invoice, customer, product...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(cursorHeight: 16, 
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: const AppIcon(AppIcons.search, size: 18),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0)),
        ),
      ),
    );
  }
}

/// All / Pending / Approved / Rejected chips with counts.
class SaleClaimStatusFilterChips extends StatelessWidget {
  final String value; // all | pending | approved | rejected
  final Map<String, int> counts; // keys: all, pending, approved, rejected
  final ValueChanged<String> onChanged;
  const SaleClaimStatusFilterChips({
    super.key,
    required this.value,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const entries = [
      ('All', 'all'),
      ('Pending', 'pending'),
      ('Approved', 'approved'),
      ('Rejected', 'rejected'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, key) in entries) ...[
            _chip(label, key),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String key) {
    final selected = value == key;
    final color = switch (key) {
      'pending' => Colors.orange,
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => const Color(0xFF1565C0),
    };
    return GestureDetector(
      onTap: () => onChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${counts[key] ?? 0}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.grey.shade600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile par table ki jagah card.
class SaleClaimCard extends StatelessWidget {
  final SaleClaimModel claim;
  final bool showBranch;
  final VoidCallback onTap;
  final Widget? trailing; // admin: approve/reject buttons
  const SaleClaimCard({
    super.key,
    required this.claim,
    required this.onTap,
    this.showBranch = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = claim;
    final sub = [
      if (showBranch) c.branchName,
      if (c.customerName != null) c.customerName,
      if (c.invoiceNumber != null) c.invoiceNumber,
    ].whereType<String>().join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(c.claimNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: saleClaimAccent)),
                  ),
                  SaleClaimStatusChip(c.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(claimProductLabel(c),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                'Size ${c.sizeName ?? '—'} · ${c.colorName ?? '—'} · Qty ${c.quantity}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (sub.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sub,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SaleClaimConditionChip(c),
                  const SizedBox(width: 8),
                  Text(claimFmtDate(c.claimDate),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Claim ki poori detail — branch aur admin dono. [actions] admin ke
/// approve/reject buttons ke liye; na diye jayein to sirf Close.
Future<void> showSaleClaimDetail(
  BuildContext context,
  SaleClaimModel c, {
  bool showBranch = true,
  List<Widget> Function(BuildContext ctx)? actions,
}) {
  Widget kv(String k, String? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(k,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
            ),
            Expanded(
              child: Text(
                (v == null || v.trim().isEmpty) ? '—' : v,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
  Widget section(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A8FA3),
                letterSpacing: 0.5)),
      );

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const AppIcon(AppIcons.warningAmberOutlined,
              color: saleClaimAccent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(c.claimNumber,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
          ),
          SaleClaimStatusChip(c.status),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              section('CLAIM'),
              if (showBranch) kv('Branch', c.branchName),
              kv('Claim Date', claimFmtDate(c.claimDate)),
              kv('Shoe Condition', c.shoeConditionLabel),
              kv('Reason', c.reason),
              section('SALE'),
              kv('Invoice', c.invoiceNumber),
              kv('Customer', c.customerName),
              kv('Sale Date', claimFmtDate(c.saleDate)),
              section('PRODUCT'),
              kv('Product', c.productName),
              kv('Brand', c.brandName),
              kv('Category', c.categoryName),
              kv('Type', c.typeName),
              kv('Size', c.sizeName),
              kv('Color', c.colorName),
              kv('Barcode', c.barcode),
              section('AMOUNT'),
              kv('Quantity', '${c.quantity}'),
              kv('Sale Price', 'Rs. ${c.salePrice.toStringAsFixed(0)}'),
              kv('Total', 'Rs. ${c.totalPrice.toStringAsFixed(0)}'),
              if (c.status != 'pending') ...[
                section('REVIEW'),
                kv('Reviewed At',
                    c.reviewedAt == null ? null : claimFmtDate(c.reviewedAt!)),
                kv('HO Remarks', c.reviewRemarks),
              ],
            ],
          ),
        ),
      ),
      actions: actions != null
          ? actions(ctx)
          : [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
    ),
  );
}
