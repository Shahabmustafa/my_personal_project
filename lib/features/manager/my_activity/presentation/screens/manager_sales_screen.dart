import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../providers/manager_activity_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Sirf jin invoices par logged-in manager assign hai — read-only history,
/// nayi invoice "Sale Invoice" nav item se hi banti hai.
class ManagerSalesScreen extends ConsumerWidget {
  const ManagerSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(myManagerSalesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myManagerSalesProvider);
          await ref.read(myManagerSalesProvider.future);
        },
        child: salesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          data: (sales) {
            final total = sales.fold<double>(0, (s, i) => s + i.totalAmount);
            final commission =
                sales.fold<double>(0, (s, i) => s + i.managerCommissionAmount);
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Sales',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                      '${sales.length} invoice${sales.length == 1 ? '' : 's'} · '
                      'Rs. ${total.toStringAsFixed(0)} · '
                      'Commission Rs. ${commission.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  if (sales.isEmpty)
                    _EmptyState(
                      icon: AppIcons.receiptLongOutlined,
                      text: 'Abhi tak koi sale nahi hui',
                    )
                  else
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return isWide
                          ? _DesktopTable(sales: sales)
                          : _MobileList(sales: sales);
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            AppIcon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(text,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final List<SaleInvoiceModel> sales;
  const _DesktopTable({required this.sales});

  @override
  Widget build(BuildContext context) {
    const headerStyle =
        TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white);
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(children: [
            _cell('Invoice #', flex: 2, style: headerStyle),
            _cell('Customer', flex: 2, style: headerStyle),
            _cell('Date', flex: 2, style: headerStyle),
            _cell('Net Amount', flex: 2, style: headerStyle),
            _cell('My Commission', flex: 2, style: headerStyle),
          ]),
        ),
        ...sales.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return Container(
            color: i.isEven ? Colors.grey.shade50 : Colors.white,
            child: Row(children: [
              _cell(s.invoiceNumber,
                  flex: 2,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary)),
              _cell(s.customerName ?? '—', flex: 2),
              _cell(_fmtDate(s.createdAt), flex: 2),
              _cell(s.totalAmount.toStringAsFixed(0),
                  flex: 2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.green)),
              _cell(s.managerCommissionAmount.toStringAsFixed(0),
                  flex: 2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF6C4DE0))),
            ]),
          );
        }),
      ],
    );
  }

  Widget _cell(String text, {int flex = 2, TextStyle? style}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child:
              Text(text, overflow: TextOverflow.ellipsis, style: style ?? const TextStyle(fontSize: 13)),
        ),
      );
}

class _MobileList extends StatelessWidget {
  final List<SaleInvoiceModel> sales;
  const _MobileList({required this.sales});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = sales[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(s.invoiceNumber,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                    const Spacer(),
                    Text(_fmtDate(s.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                if ((s.customerName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(s.customerName!, style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('Net Amount', s.totalAmount.toStringAsFixed(0),
                        color: Colors.green.shade700),
                    _stat('My Commission',
                        s.managerCommissionAmount.toStringAsFixed(0),
                        color: const Color(0xFF6C4DE0)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
