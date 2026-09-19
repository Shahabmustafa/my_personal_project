import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../return_stock_to_other_branch/presentation/screens/branch_stock_return_screen.dart'
    show StatusChip;
import '../../data/model/branch_payment_model.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Branch → Head Office payments, shown under a cash counter table.
/// [showBranch] adds the "From Branch" column (Admin side, where payments of
/// every branch are listed).
class BranchPaymentsPanel extends StatelessWidget {
  final AsyncValue<List<BranchPaymentModel>> payments;
  final bool showBranch;
  final VoidCallback onRetry;

  const BranchPaymentsPanel({
    super.key,
    required this.payments,
    required this.onRetry,
    this.showBranch = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final list = payments.value ?? const <BranchPaymentModel>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              child: Row(
                children: [
                  const AppIcon(AppIcons.paymentsOutlined,
                      size: 20, color: Color(0xFF3E63DD)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      showBranch
                          ? 'Branch Payments'
                          : 'Payments to Head Office',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (payments.hasValue)
                    Text('${list.length}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8FA3))),
                  IconButton(
                    icon: const AppIcon(AppIcons.refresh, size: 18),
                    tooltip: 'Refresh',
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE7E9F0)),
            if (payments.isLoading && !payments.hasValue)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (payments.hasError && !payments.hasValue)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('Error: ${payments.error}',
                      style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No payments yet',
                      style: TextStyle(color: Color(0xFF8A8FA3))),
                ),
              )
            else if (isMobile)
              for (final p in list) _MobileRow(payment: p, showBranch: showBranch)
            else ...[
              _headerRow(),
              for (var i = 0; i < list.length; i++)
                _DesktopRow(
                  payment: list[i],
                  showBranch: showBranch,
                  isLast: i == list.length - 1,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    Widget th(String t, {int flex = 2}) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(t,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A8FA3))),
          ),
        );
    return Container(
      color: const Color(0xFFF7F8FC),
      child: Row(children: [
        th('Payment No'),
        if (showBranch) th('From Branch'),
        th('Date'),
        th('Status'),
        th('Amount'),
      ]),
    );
  }
}

class _DesktopRow extends StatelessWidget {
  final BranchPaymentModel payment;
  final bool showBranch;
  final bool isLast;
  const _DesktopRow(
      {required this.payment, required this.showBranch, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final p = payment;
    Widget cell(Widget child) => Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
      ),
      child: Row(children: [
        cell(Text(p.paymentNumber,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFF3E63DD)))),
        if (showBranch)
          cell(Text(p.branchName ?? '—', style: const TextStyle(fontSize: 13))),
        cell(Text(_fmtDate(p.paidAt), style: const TextStyle(fontSize: 13))),
        cell(StatusChip(p.status)),
        cell(Text('Rs. ${_fmtAmt(p.amount)}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF22A06B)))),
      ]),
    );
  }
}

class _MobileRow extends StatelessWidget {
  final BranchPaymentModel payment;
  final bool showBranch;
  const _MobileRow({required this.payment, required this.showBranch});

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.paymentNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFF3E63DD))),
                const SizedBox(height: 4),
                Text(
                  showBranch
                      ? '${p.branchName ?? '—'} · ${_fmtDate(p.paidAt)}'
                      : _fmtDate(p.paidAt),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8A8FA3)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. ${_fmtAmt(p.amount)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22A06B))),
              const SizedBox(height: 4),
              StatusChip(p.status),
            ],
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}
