import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch_payment/presentation/providers/branch_payment_provider.dart';
import '../../../shared/current_branch_provider.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../data/model/branch_cash_counter_model.dart';
import '../providers/branch_cash_counter_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
import 'package:safishoe_app/core/widget/cash_counter_bar_chart.dart';
import 'package:safishoe_app/features/superadmin/report/presentation/widgets/report_detail_panel.dart';
class BranchCashCounterScreen extends ConsumerStatefulWidget {
  const BranchCashCounterScreen({super.key});

  @override
  ConsumerState<BranchCashCounterScreen> createState() =>
      _BranchCashCounterScreenState();
}

class _BranchCashCounterScreenState
    extends ConsumerState<BranchCashCounterScreen> {
  /// Row tap par right-side slider mein iska bar graph dikhta hai.
  BranchCashCounterModel? _selected;

  /// [available] is today's running balance — the most recent record is
  /// today's counter (rows are loaded newest first).
  Future<void> _onPay(double available) async {
    final paid = await showDialog<bool>(
      context: context,
      builder: (_) => _PayToHeadOfficeDialog(available: available),
    );
    if (paid != true || !mounted) return;
    ref.read(branchCashCounterProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment sent — waiting for Head Office to accept'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchCashCounterProvider);
    final stats = ref.watch(branchCashCounterStatsProvider);
    final notifier = ref.read(branchCashCounterProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cash Counter',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(
                          '${state.isFirstLoad ? '…' : groupThousands(state.totalCount)} record${state.totalCount == 1 ? '' : 's'} — read only',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF8A8FA3))),
                    ],
                  ),
                ),
                FilledButton.icon(
                  // Aaj ka balance sab se naya record hai — search lagi ho to
                  // rows filtered hoti hain, is liye tab Pay band rehta hai.
                  onPressed: state.rows.isEmpty || state.search.isNotEmpty
                      ? null
                      : () => _onPay(state.rows.first.totalAmount),
                  icon: const AppIcon(AppIcons.sendOutlined,
                      size: 16, color: Colors.white),
                  label: Text(isMobile ? 'Pay' : 'Pay to Head Office'),
                ),
              ],
            ),
          ),

          // ── Summary Cards ─────────────────────────────────────────────
          if (stats != null && !state.isFirstLoad && stats.recordCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: isMobile
                  ? Column(
                      children: [
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Total Sale',
                                  amount: stats.totalSale,
                                  icon: AppIcons.pointOfSaleOutlined,
                                  color: const Color(0xFF3E63DD))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Net Sale',
                                  amount: stats.netSale,
                                  icon: AppIcons.publishedWithChangesOutlined,
                                  color: const Color(0xFF0F9D8F))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Gross',
                                  amount: stats.gross,
                                  icon: AppIcons.trendingUpOutlined,
                                  color: const Color(0xFF22A06B))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Expense',
                                  amount: stats.expense,
                                  icon: AppIcons.receiptLongOutlined,
                                  color: const Color(0xFFE56A00))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Total Amount',
                                  amount: stats.totalAmount,
                                  icon: AppIcons.accountBalanceWalletOutlined,
                                  color: const Color(0xFF6C4DE0))),
                        ]),
                      ],
                    )
                  : Row(children: [
                      Expanded(
                          child: _SummaryCard(
                              label: 'Total Sale',
                              amount: stats.totalSale,
                              icon: AppIcons.pointOfSaleOutlined,
                              color: const Color(0xFF3E63DD))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Net Sale',
                              amount: stats.netSale,
                              icon: AppIcons.publishedWithChangesOutlined,
                              color: const Color(0xFF0F9D8F))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Gross',
                              amount: stats.gross,
                              icon: AppIcons.trendingUpOutlined,
                              color: const Color(0xFF22A06B))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Expense',
                              amount: stats.expense,
                              icon: AppIcons.receiptLongOutlined,
                              color: const Color(0xFFE56A00))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Total Amount',
                              amount: stats.totalAmount,
                              icon: AppIcons.accountBalanceWalletOutlined,
                              color: const Color(0xFF6C4DE0))),
                    ]),
            ),

          // ── Search ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: notifier.setSearch,
              decoration: _searchDecor('Search by date (dd/mm/yyyy, mm/yyyy) or total sale amount...'),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: isMobile
                ? PaginatedListView<BranchCashCounterModel>(
                    state: state,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    emptyText: 'No cash counter records found',
                    onLoadMore: notifier.loadMore,
                    onRefresh: notifier.refresh,
                    onRetry: notifier.refresh,
                    itemBuilder: (_, r, _) =>
                        _MobileCard(record: r, onTap: _select),
                  )
                : _DesktopTable(
                    state: state,
                    notifier: notifier,
                    onTap: _select,
                  ),
          ),
        ],
      ),
      if (_selected != null)
        ReportDetailOverlay(
          title: 'Cash Counter',
          subtitle: _fmtDate(_selected!.createdAt),
          accent: const Color(0xFF3E63DD),
          onClose: () => setState(() => _selected = null),
          child: CashCounterBarChart(bars: _barsFor(_selected!)),
        ),
      ]),
    );
  }

  void _select(BranchCashCounterModel r) => setState(() => _selected = r);

  List<CashCounterBar> _barsFor(BranchCashCounterModel r) => [
        CashCounterBar('Cash', 'Cash Sale', r.cashSale, const Color(0xFF3E63DD)),
        CashCounterBar('Card', 'Card Sale', r.cardSale, const Color(0xFF0EA5E9)),
        CashCounterBar('Total', 'Total Sale', r.totalSale, const Color(0xFF6366F1)),
        CashCounterBar('Return', 'Return Sale', r.returnSale, const Color(0xFFE2483D)),
        CashCounterBar('Ex.Out', 'Return in Exchange', r.returnAmountInExchange,
            const Color(0xFFF472B6)),
        CashCounterBar('Ex.In', 'Received in Exchange', r.receivedAmountInExchange,
            const Color(0xFF14B8A6)),
        CashCounterBar('Net', 'Net Sale', r.netSale, const Color(0xFF0F9D8F)),
        CashCounterBar('Exp.', 'Expense', r.expense, const Color(0xFFE56A00)),
        CashCounterBar('Gross', 'Gross', r.gross, const Color(0xFF22A06B)),
        CashCounterBar('Paid', 'Paid Amount', r.paidAmount, const Color(0xFF64748B)),
        CashCounterBar('Bal.', 'Total Amount', r.totalAmount, const Color(0xFF6C4DE0)),
      ];
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppIcon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8FA3),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  'Rs. ${_fmtAmt(amount)}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop Table (horizontal scroll — many columns, rows lazily built) ───────

class _Col {
  final String label;
  final double width;
  const _Col(this.label, this.width);
}

const _cols = [
  _Col('Date', 120),
  _Col('Cash Sale', 120),
  _Col('Card Sale', 120),
  _Col('Total Sale', 130),
  _Col('Return Sale', 120),
  _Col('Return in Exch.', 140),
  _Col('Received in Exch.', 150),
  _Col('Net Sale', 130),
  _Col('Expense', 120),
  _Col('Gross', 120),
  _Col('Paid Amount', 130),
  _Col('Total Amount', 140),
];

final double _tableWidth = _cols.fold(0.0, (w, c) => w + c.width);

class _DesktopTable extends StatelessWidget {
  final PaginatedListState<BranchCashCounterModel> state;
  final BranchCashCounterNotifier notifier;
  final ValueChanged<BranchCashCounterModel> onTap;
  const _DesktopTable(
      {required this.state, required this.notifier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _tableWidth,
              child: Column(
                children: [
                  Container(
                    height: 48,
                    color: const Color(0xFFF7F8FC),
                    child: Row(
                      children: [
                        for (final c in _cols)
                          _cell(
                            c.width,
                            Text(c.label,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8A8FA3))),
                            alignRight: c.label != 'Date',
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE7E9F0)),
                  Expanded(
                    child: PaginatedListView<BranchCashCounterModel>(
                      state: state,
                      padding: EdgeInsets.zero,
                      emptyText: 'No cash counter records found',
                      onLoadMore: notifier.loadMore,
                      onRefresh: notifier.refresh,
                      onRetry: notifier.refresh,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFF0F1F6)),
                      itemBuilder: (_, r, _) => _row(r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _cell(double width, Widget child, {bool alignRight = true}) =>
      SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment:
                alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: child,
          ),
        ),
      );

  Widget _row(BranchCashCounterModel r) {
    const base = TextStyle(fontSize: 13);
    Widget amt(int col, double v, {Color? color, FontWeight? weight}) => _cell(
          _cols[col].width,
          Text('Rs. ${_fmtAmt(v)}',
              style: base.copyWith(color: color, fontWeight: weight)),
        );
    const grey = Color(0xFF8A8FA3);

    return InkWell(
      onTap: () => onTap(r),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            _cell(
              _cols[0].width,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFFD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_fmtDate(r.createdAt),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E63DD))),
              ),
              alignRight: false,
            ),
            amt(1, r.cashSale),
            amt(2, r.cardSale),
            amt(3, r.totalSale,
                color: const Color(0xFF3E63DD), weight: FontWeight.w600),
            amt(4, r.returnSale,
                color: r.returnSale > 0 ? const Color(0xFFE2483D) : grey),
            amt(5, r.returnAmountInExchange),
            amt(6, r.receivedAmountInExchange),
            amt(7, r.netSale,
                color: const Color(0xFF0F9D8F), weight: FontWeight.w600),
            amt(8, r.expense,
                color: r.expense > 0 ? const Color(0xFFE56A00) : grey),
            amt(9, r.gross,
                color: const Color(0xFF22A06B), weight: FontWeight.w600),
            amt(10, r.paidAmount),
            amt(11, r.totalAmount,
                color: const Color(0xFF6C4DE0), weight: FontWeight.w700),
          ],
        ),
      ),
    );
  }
}

// ── Mobile card ───────────────────────────────────────────────────────────────

class _MobileCard extends StatelessWidget {
  final BranchCashCounterModel record;
  final ValueChanged<BranchCashCounterModel> onTap;
  const _MobileCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = record;
    return GestureDetector(
      onTap: () => onTap(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEFFD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_fmtDate(r.createdAt),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF3E63DD))),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE7E9F0)),
            const SizedBox(height: 12),
            _MobileRow(label: 'Cash Sale', value: 'Rs. ${_fmtAmt(r.cashSale)}'),
            const SizedBox(height: 8),
            _MobileRow(label: 'Card Sale', value: 'Rs. ${_fmtAmt(r.cardSale)}'),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Total Sale',
                value: 'Rs. ${_fmtAmt(r.totalSale)}',
                valueColor: const Color(0xFF3E63DD)),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Return Sale',
                value: 'Rs. ${_fmtAmt(r.returnSale)}',
                valueColor: r.returnSale > 0
                    ? const Color(0xFFE2483D)
                    : const Color(0xFF8A8FA3)),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Return in Exchange',
                value: 'Rs. ${_fmtAmt(r.returnAmountInExchange)}'),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Received in Exchange',
                value: 'Rs. ${_fmtAmt(r.receivedAmountInExchange)}'),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Net Sale',
                value: 'Rs. ${_fmtAmt(r.netSale)}',
                valueColor: const Color(0xFF0F9D8F)),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Expense',
                value: 'Rs. ${_fmtAmt(r.expense)}',
                valueColor: r.expense > 0
                    ? const Color(0xFFE56A00)
                    : const Color(0xFF8A8FA3)),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Gross',
                value: 'Rs. ${_fmtAmt(r.gross)}',
                valueColor: const Color(0xFF22A06B)),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Paid Amount', value: 'Rs. ${_fmtAmt(r.paidAmount)}'),
            const SizedBox(height: 8),
            _MobileRow(
                label: 'Total Amount',
                value: 'Rs. ${_fmtAmt(r.totalAmount)}',
                valueColor: const Color(0xFF6C4DE0)),
          ],
        ),
      ),
    );
  }
}

class _MobileRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MobileRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF2D2D3A))),
      ],
    );
  }
}

// ── Helper functions ──────────────────────────────────────────────────────────

/// `created_at` UTC se aata hai (jaise "2026-08-24T19:00:00Z"), lekin har
/// row ka din pg_cron ke Pakistan-time midnight boundary (`0 19 * * *` UTC)
/// se decide hota hai — yani 19:00 UTC row asal mein *agle* din (00:00 PKT)
/// ki hai. Raw UTC date parts dikhana ek din peeche ki date deta tha, is
/// liye display se pehle hamesha PKT (UTC+5) mein shift karo.
String _fmtDate(DateTime d) {
  final pkt = d.toUtc().add(const Duration(hours: 5));
  return '${pkt.day.toString().padLeft(2, '0')}/${pkt.month.toString().padLeft(2, '0')}/${pkt.year}';
}

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

InputDecoration _searchDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
      prefixIcon: const TextFieldIcon(AppIcons.search, size: 18, color: Color(0xFF8A8FA3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
    );


// ── Pay to Head Office dialog ─────────────────────────────────────────────────

class _PayToHeadOfficeDialog extends ConsumerStatefulWidget {
  final double available;
  const _PayToHeadOfficeDialog({required this.available});

  @override
  ConsumerState<_PayToHeadOfficeDialog> createState() =>
      _PayToHeadOfficeDialogState();
}

class _PayToHeadOfficeDialogState
    extends ConsumerState<_PayToHeadOfficeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(branchPaymentRepositoryProvider).pay(
            branchId: ref.read(currentBranchIdProvider),
            amount: double.parse(_amountCtrl.text),
            notes: _notesCtrl.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          AppIcon(AppIcons.sendOutlined, color: Color(0xFF3E63DD), size: 22),
          SizedBox(width: 8),
          Text('Pay to Head Office'),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available in cash counter: Rs. ${_fmtAmt(widget.available)}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF8A8FA3)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  if (n > widget.available) {
                    return 'Exceeds available balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Pay'),
        ),
      ],
    );
  }
}
