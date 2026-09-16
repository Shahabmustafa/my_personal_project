import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../providers/my_activity_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Logged-in salesman ke apne sale exchanges — read-only history.
class MyExchangesScreen extends ConsumerWidget {
  const MyExchangesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangesAsync = ref.watch(myExchangesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myExchangesProvider);
          await ref.read(myExchangesProvider.future);
        },
        child: exchangesAsync.when(
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
          data: (exchanges) {
            final commission = exchanges.fold<double>(
                0, (s, i) => s + i.salesmanCommissionAmount);
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Exchanges',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                      '${exchanges.length} exchange${exchanges.length == 1 ? '' : 's'} · '
                      'Commission Rs. ${commission.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  if (exchanges.isEmpty)
                    const _EmptyState(
                      icon: AppIcons.swapHorizOutlined,
                      text: 'Abhi tak koi exchange nahi hua',
                    )
                  else
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return isWide
                          ? _DesktopTable(exchanges: exchanges)
                          : _MobileList(exchanges: exchanges);
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
  final List<SaleExchangeModel> exchanges;
  const _DesktopTable({required this.exchanges});

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
            _cell('Exchange #', flex: 2, style: headerStyle),
            _cell('Against Invoice', flex: 2, style: headerStyle),
            _cell('Customer', flex: 2, style: headerStyle),
            _cell('Date', flex: 2, style: headerStyle),
            _cell('Difference', flex: 2, style: headerStyle),
            _cell('My Commission', flex: 2, style: headerStyle),
          ]),
        ),
        ...exchanges.asMap().entries.map((e) {
          final i = e.key;
          final x = e.value;
          final diffColor = x.differenceAmount > 0
              ? Colors.green
              : x.differenceAmount < 0
                  ? Colors.red
                  : Colors.grey;
          return Container(
            color: i.isEven ? Colors.grey.shade50 : Colors.white,
            child: Row(children: [
              _cell(x.exchangeNumber,
                  flex: 2,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary)),
              _cell(x.originalInvoiceNumber ?? '—', flex: 2),
              _cell(x.customerName ?? '—', flex: 2),
              _cell(_fmtDate(x.createdAt), flex: 2),
              _cell(
                  '${x.differenceLabel} ${x.differenceAmount.abs().toStringAsFixed(0)}',
                  flex: 2,
                  style: TextStyle(fontWeight: FontWeight.w700, color: diffColor)),
              _cell(x.salesmanCommissionAmount.toStringAsFixed(0),
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
  final List<SaleExchangeModel> exchanges;
  const _MobileList({required this.exchanges});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exchanges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final x = exchanges[i];
        final diffColor = x.differenceAmount > 0
            ? Colors.green
            : x.differenceAmount < 0
                ? Colors.red
                : Colors.grey;
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
                      child: Text(x.exchangeNumber,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                    const Spacer(),
                    Text(_fmtDate(x.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                if ((x.originalInvoiceNumber ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Against ${x.originalInvoiceNumber}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(
                        x.differenceLabel,
                        x.differenceAmount.abs().toStringAsFixed(0),
                        color: diffColor),
                    _stat('My Commission',
                        x.salesmanCommissionAmount.toStringAsFixed(0),
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
