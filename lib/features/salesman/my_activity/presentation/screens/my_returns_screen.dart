import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../providers/my_activity_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Logged-in salesman ke apne sale returns — read-only history.
class MyReturnsScreen extends ConsumerWidget {
  const MyReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(myReturnsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myReturnsProvider);
          await ref.read(myReturnsProvider.future);
        },
        child: returnsAsync.when(
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
          data: (returns) {
            final total = returns.fold<double>(0, (s, i) => s + i.totalAmount);
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Returns',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                      '${returns.length} return${returns.length == 1 ? '' : 's'} · '
                      'Rs. ${total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  if (returns.isEmpty)
                    const _EmptyState(
                      icon: AppIcons.assignmentReturnOutlined,
                      text: 'Abhi tak koi return nahi hua',
                    )
                  else
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return isWide
                          ? _DesktopTable(returns: returns)
                          : _MobileList(returns: returns);
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
  final List<SaleReturnModel> returns;
  const _DesktopTable({required this.returns});

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
            _cell('Return #', flex: 2, style: headerStyle),
            _cell('Against Invoice', flex: 2, style: headerStyle),
            _cell('Customer', flex: 2, style: headerStyle),
            _cell('Date', flex: 2, style: headerStyle),
            _cell('Amount', flex: 2, style: headerStyle),
          ]),
        ),
        ...returns.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return Container(
            color: i.isEven ? Colors.grey.shade50 : Colors.white,
            child: Row(children: [
              _cell(r.returnNumber,
                  flex: 2,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary)),
              _cell(r.originalInvoiceNumber ?? '—', flex: 2),
              _cell(r.customerName ?? '—', flex: 2),
              _cell(_fmtDate(r.createdAt), flex: 2),
              _cell(r.totalAmount.toStringAsFixed(0),
                  flex: 2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.red)),
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
  final List<SaleReturnModel> returns;
  const _MobileList({required this.returns});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: returns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = returns[i];
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
                      child: Text(r.returnNumber,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                    const Spacer(),
                    Text(_fmtDate(r.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                if ((r.originalInvoiceNumber ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Against ${r.originalInvoiceNumber}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                if ((r.customerName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(r.customerName!, style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 8),
                Text('Rs. ${r.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.red)),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
