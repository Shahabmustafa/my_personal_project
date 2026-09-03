import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch/data/model/branch_model.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../../../branch/presentation/providers/branch_state.dart';

/// Superadmin yahan har branch ke liye max percentage set karta hai jo us
/// branch ka cashier Sale Invoice par invoice-wise (extra) discount ke taur
/// par laga sakta hai. 0 = us branch par discount field dikhta hi nahi.
class BranchInvoiceDiscountScreen extends ConsumerStatefulWidget {
  const BranchInvoiceDiscountScreen({super.key});

  @override
  ConsumerState<BranchInvoiceDiscountScreen> createState() =>
      _BranchInvoiceDiscountScreenState();
}

class _BranchInvoiceDiscountScreenState
    extends ConsumerState<BranchInvoiceDiscountScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchProvider.notifier).loadAllBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchState = ref.watch(branchProvider);

    ref.listen<BranchState>(branchProvider, (_, next) {
      if (next.status == BranchStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final filtered = branchState.branches
        .where((b) =>
            b.branchName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Branch Invoice Discount',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'Har branch ka cashier Sale Invoice par max itne % tak extra discount laga sakega. 0 = discount allowed nahi.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search branches...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8FA3)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
              ),
            ),
          ),
          Expanded(
            child: branchState.isLoading && branchState.branches.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text('No branches found',
                            style: TextStyle(color: Color(0xFF8A8FA3))))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _BranchDiscountRow(
                          key: ValueKey(filtered[i].id),
                          branch: filtered[i],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BranchDiscountRow extends ConsumerStatefulWidget {
  final BranchModel branch;
  const _BranchDiscountRow({super.key, required this.branch});

  @override
  ConsumerState<_BranchDiscountRow> createState() => _BranchDiscountRowState();
}

class _BranchDiscountRowState extends ConsumerState<_BranchDiscountRow> {
  late final TextEditingController _ctrl;

  String get _savedText => _fmt(widget.branch.maxInvoiceDiscountPct);
  bool get _dirty => _ctrl.text.trim() != _savedText;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _savedText);
  }

  @override
  void didUpdateWidget(covariant _BranchDiscountRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Save ke baad model refresh hone par field ko synced rakho (jab tak
    // user usi field mein aur type na kar raha ho).
    if (!_dirty &&
        oldWidget.branch.maxInvoiceDiscountPct !=
            widget.branch.maxInvoiceDiscountPct) {
      _ctrl.text = _savedText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _save() {
    final raw = double.tryParse(_ctrl.text.trim()) ?? 0;
    final pct = raw.clamp(0, 100).toDouble();
    _ctrl.text = _fmt(pct);
    FocusScope.of(context).unfocus();
    ref.read(branchProvider.notifier).updateBranch(
          widget.branch.copyWith(
            maxInvoiceDiscountPct: pct,
            canApplyInvoiceDiscount: pct > 0,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.branch;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFFD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment_outlined,
                color: Color(0xFF3E63DD), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.branchName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  b.maxInvoiceDiscountPct > 0
                      ? 'Allowed up to ${_fmt(b.maxInvoiceDiscountPct)}%'
                      : 'Not allowed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: b.maxInvoiceDiscountPct > 0
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF8A8FA3),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textAlign: TextAlign.end,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Max %',
                suffixText: '%',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _dirty ? _save : null,
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
