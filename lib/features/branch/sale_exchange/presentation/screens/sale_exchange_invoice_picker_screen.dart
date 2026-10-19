import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sale_invoice/data/model/sale_invoice_model.dart';
import '../../../sale_invoice/presentation/screens/sale_invoices_list_screen.dart';
import '../provider/sale_exchange_provider.dart';
import 'sale_exchange_screen.dart';

/// Exchange ka entry point — sab branches ki invoices, ek din ki (default
/// aaj, date filter se badal sakte hain). Har row par "Exchange" action hai;
/// tap hone par invoice ki detail load hoti hai aur SaleExchangeScreen push
/// ho jati hai.
class SaleExchangeInvoicePickerScreen extends ConsumerWidget {
  const SaleExchangeInvoicePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SaleInvoicesListScreen(
      showNewInvoiceButton: false,
      allBranchesByDate: true,
      onExchangeTap: (invoice) => _startExchange(context, ref, invoice),
    );
  }

  Future<void> _startExchange(
      BuildContext context, WidgetRef ref, SaleInvoiceModel invoice) async {
    await ref.read(saleExchangeProvider.notifier).selectOriginalInvoice(invoice);
    if (!context.mounted) return;
    final branch = invoice.branchName;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
              title: Text(branch == null || branch.isEmpty
                  ? 'Exchange — ${invoice.invoiceNumber}'
                  : 'Exchange — ${invoice.invoiceNumber} ($branch)')),
          body: const SaleExchangeScreen(),
        ),
      ),
    );
    if (context.mounted) {
      ref.read(saleExchangeProvider.notifier).resetExchange();
    }
  }
}
