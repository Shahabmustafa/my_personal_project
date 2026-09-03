import 'package:flutter/material.dart';

/// Right-side slide-in panel shared by the sale/return/exchange report
/// screens — shows a single record's full detail (products, payments,
/// totals) when its "View" action is tapped. Each screen supplies its own
/// [child] body; only the header (title/subtitle/print/close) is common.
class ReportDetailPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onClose;

  /// Null hone par print button hide ho jata hai (e.g. assignment detail —
  /// print karne ko kuch nahi hota).
  final VoidCallback? onPrint;
  final Widget child;

  const ReportDetailPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onClose,
    this.onPrint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1B1F3B),
            blurRadius: 24,
            offset: Offset(-6, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (onPrint != null)
                  Tooltip(
                    message: 'Print',
                    child: IconButton(
                      icon: const Icon(Icons.print_outlined, size: 20),
                      onPressed: onPrint,
                    ),
                  ),
                Tooltip(
                  message: 'Close',
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// [ReportDetailPanel] ko table ke upar right-side overlay ki tarah dikhata
/// hai — peeche scrim (tap se close), panel poori height right par slide-in.
/// Table ab full width leti hai; detail sirf "View" par overlay hoti hai.
class ReportDetailOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onClose;
  final VoidCallback? onPrint;
  final Widget child;

  const ReportDetailOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onClose,
    this.onPrint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(color: const Color(0x33101223)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              heightFactor: 1,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                tween: Tween(begin: 1, end: 0),
                builder: (context, t, panel) => Transform.translate(
                  offset: Offset(t * 32, 0),
                  child: Opacity(opacity: 1 - t, child: panel),
                ),
                child: ReportDetailPanel(
                  title: title,
                  subtitle: subtitle,
                  accent: accent,
                  onClose: onClose,
                  onPrint: onPrint,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading used inside a detail panel body (e.g. "ITEMS", "PAYMENTS").
class DetailSectionLabel extends StatelessWidget {
  final String text;
  const DetailSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A8FA3),
                letterSpacing: 0.5)),
      );
}

/// A label/value row used for header fields (Invoice #, Date, Customer, …)
/// and totals (Sub Total, Discount, Total) inside a detail panel.
class DetailKV extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const DetailKV(this.label, this.value, {super.key, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? const Color(0xFF2D2D3A))),
          ],
        ),
      );
}

/// A single product line inside a detail panel's item list.
class DetailProductRow extends StatelessWidget {
  final String name;
  final String? sizeName;
  final String? colorName;
  final int quantity;
  final double total;

  const DetailProductRow({
    super.key,
    required this.name,
    this.sizeName,
    this.colorName,
    required this.quantity,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      if ((colorName ?? '').isNotEmpty) colorName!,
      if ((sizeName ?? '').isNotEmpty) 'Size ${sizeName!}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(meta,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('x$quantity', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
          const SizedBox(width: 12),
          Text('Rs. ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Divider used between detail-panel sections.
class DetailDivider extends StatelessWidget {
  const DetailDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFE7E9F0)));
}
