import 'package:flutter/material.dart';

import 'package:safishoe_app/features/superadmin/report/presentation/widgets/report_detail_panel.dart';

/// Stock rows that are the same article — same product, color, category,
/// brand and type — differing only by size. The list shows one row per group;
/// tapping it opens [showStockSizesPanel] with every size.
class StockGroup<T> {
  final List<T> items;
  const StockGroup(this.items);
  T get first => items.first;
}

/// Groups [rows] by [keyOf], keeping first-appearance order.
List<StockGroup<T>> groupStock<T>(List<T> rows, String Function(T) keyOf) {
  final map = <String, List<T>>{};
  for (final r in rows) {
    map.putIfAbsent(keyOf(r), () => []).add(r);
  }
  return [for (final items in map.values) StockGroup(items)];
}

/// One value when every size agrees, otherwise "min – max".
String sameOrRange(Iterable<double> values, String Function(double) fmt) {
  if (values.isEmpty) return '—';
  final lo = values.reduce((a, b) => a < b ? a : b);
  final hi = values.reduce((a, b) => a > b ? a : b);
  return lo == hi ? fmt(lo) : '${fmt(lo)} – ${fmt(hi)}';
}

int _compareSize(String a, String b) {
  final x = double.tryParse(a);
  final y = double.tryParse(b);
  if (x != null && y != null) return x.compareTo(y);
  return a.compareTo(b);
}

/// Opens the sizes panel: a right-side overlay on wide screens (put inside a
/// `Stack` over the list via [StockSizesOverlay]) or a bottom sheet on phones.
Future<void> showStockSizesSheet<T>(
  BuildContext context, {
  required String title,
  required String subtitle,
  required StockSizesBody<T> body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    ),
  );
}

/// Right-side slider over the list (desktop).
class StockSizesOverlay<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final StockSizesBody<T> body;

  const StockSizesOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => ReportDetailOverlay(
    title: title,
    subtitle: subtitle,
    accent: const Color(0xFF1565C0),
    onClose: onClose,
    child: body,
  );
}

/// All sizes of one article: stock, sale price and discount per size.
/// [loader] fetches the complete set from the database (the list only holds
/// the pages loaded so far); it re-runs when [refreshToken] changes, so edits
/// and realtime updates show up without closing the panel.
class StockSizesBody<T> extends StatefulWidget {
  final Future<List<T>> Function() loader;
  final Object? refreshToken;
  final String Function(T) sizeOf;
  final String Function(T) barcodeOf;
  final int Function(T) qtyOf;
  final double Function(T) salePriceOf;
  final double Function(T) discountOf;
  final Widget Function(T)? actionsOf;

  const StockSizesBody({
    super.key,
    required this.loader,
    required this.sizeOf,
    required this.barcodeOf,
    required this.qtyOf,
    required this.salePriceOf,
    required this.discountOf,
    this.refreshToken,
    this.actionsOf,
  });

  @override
  State<StockSizesBody<T>> createState() => _StockSizesBodyState<T>();
}

class _StockSizesBodyState<T> extends State<StockSizesBody<T>> {
  List<T>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(StockSizesBody<T> old) {
    super.didUpdateWidget(old);
    if (!identical(old.refreshToken, widget.refreshToken)) _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.loader();
      items.sort((a, b) => _compareSize(widget.sizeOf(a), widget.sizeOf(b)));
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items == null) {
      return Text('Error: $_error', style: const TextStyle(color: Colors.red));
    }
    final items = _items;
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('No sizes found')),
      );
    }
    final totalQty = items.fold<int>(0, (s, i) => s + widget.qtyOf(i));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _stat('Sizes', '${items.length}'),
            const SizedBox(width: 10),
            _stat('Total Stock', '$totalQty pairs'),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'SIZES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Color(0xFF8A8FA3),
          ),
        ),
        const SizedBox(height: 8),
        for (final i in items) _sizeCard(i),
      ],
    );
  }

  Widget _stat(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _sizeCard(T i) {
    final qty = widget.qtyOf(i);
    final discount = widget.discountOf(i);
    final actions = widget.actionsOf?.call(i);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Size ${widget.sizeOf(i)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: (qty < 5 ? Colors.orange : Colors.green).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Stock $qty',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: qty < 5
                        ? Colors.orange.shade800
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Rs ${widget.salePriceOf(i).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Discount ${discount.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: discount > 0
                      ? Colors.orange.shade800
                      : const Color(0xFF8A8FA3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.barcodeOf(i),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF8A8FA3),
                  ),
                ),
              ),
              ?actions,
            ],
          ),
        ],
      ),
    );
  }
}
