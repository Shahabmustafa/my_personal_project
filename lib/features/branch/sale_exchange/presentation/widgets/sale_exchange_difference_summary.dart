import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sale_invoice/data/model/sale_invoice_model.dart';
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show bankEntriesForSaleProvider;
import '../provider/sale_exchange_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
/// Return Total / New Total stat row + Collect/Refund/Even banner. Jab
/// difference amount 0 nahi hota, payment-type toggle + bank/cash fields
/// bhi dikhte hain (bilkul sale_invoice ke _InvoiceMetaRow ke conditional
/// block jaisa, bas totalAmount ki jagah absDifference par).
class SaleExchangeDifferenceSummary extends ConsumerStatefulWidget {
  const SaleExchangeDifferenceSummary({super.key});

  @override
  ConsumerState<SaleExchangeDifferenceSummary> createState() =>
      _SaleExchangeDifferenceSummaryState();
}

class _SaleExchangeDifferenceSummaryState
    extends ConsumerState<SaleExchangeDifferenceSummary> {
  final _cashAmountCtrl = TextEditingController();

  @override
  void dispose() {
    _cashAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleExchangeProvider);
    final notifier = ref.read(saleExchangeProvider.notifier);
    final bankAsync = ref.watch(bankEntriesForSaleProvider);

    final Color bannerColor;
    final String bannerLabel;
    if (state.isCollect) {
      bannerColor = Colors.green.shade700;
      bannerLabel = 'Collect Rs. ${state.absDifference.toStringAsFixed(0)}';
    } else if (state.isRefund) {
      bannerColor = Colors.red.shade700;
      bannerLabel = 'Refund Rs. ${state.absDifference.toStringAsFixed(0)}';
    } else {
      bannerColor = Colors.grey.shade600;
      bannerLabel = 'Even exchange — no payment due';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat('Return Total', state.returnTotal.toStringAsFixed(0), color: Colors.red.shade700),
              const SizedBox(width: 28),
              _stat('New Total', state.newTotal.toStringAsFixed(0), color: Colors.green.shade700),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: bannerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bannerColor.withOpacity(0.4)),
                ),
                child: Text(bannerLabel,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: bannerColor)),
              ),
            ],
          ),

          if (state.differenceAmount != 0) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExchangePaymentTypeToggle(
                  value: state.paymentType,
                  onChanged: notifier.selectPaymentType,
                ),
                if (state.paymentType == 'card' || state.paymentType == 'cash_card') ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: bankAsync.when(
                      loading: () => const SizedBox(
                          height: 48, child: Center(child: LinearProgressIndicator())),
                      error: (e, _) =>
                          Text('Error: $e', style: const TextStyle(fontSize: 11, color: Colors.red)),
                      data: (list) => DropdownSearch<BankEntryLookupItem>(
                        items: (f, _) =>
                            list.where((e) => e.label.toLowerCase().contains(f.toLowerCase())).toList(),
                        selectedItem: state.bankEntry,
                        itemAsString: (e) => e.label,
                        compareFn: (a, b) => a.id == b.id,
                        onSelected: notifier.selectBankEntry,
                        decoratorProps:
                            DropDownDecoratorProps(decoration: _decor('Bank Account', required: true)),
                        popupProps: const PopupProps.menu(
                            showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
                      ),
                    ),
                  ),
                ],
                if (state.paymentType == 'cash_card') ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _cashAmountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                      ],
                      onChanged: (v) => notifier.setCashAmount(double.tryParse(v.trim()) ?? 0),
                      decoration: _decor('Cash Amount *').copyWith(
                        helperText: 'Card: Rs. ${state.cardAmount.toStringAsFixed(0)}',
                        helperStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  InputDecoration _decor(String label, {bool required = false}) => InputDecoration(
        labelText: required ? '$label *' : label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      );
}

class _ExchangePaymentTypeToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _ExchangePaymentTypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _seg('Cash', 'cash', AppIcons.paymentsOutlined, primary),
        _seg('Card', 'card', AppIcons.creditCardOutlined, primary),
        _seg('Cash + Card', 'cash_card', AppIcons.syncAlt, primary),
      ]),
    );
  }

  Widget _seg(String label, String type, String icon, Color primary) {
    final selected = value == type;
    return InkWell(
      onTap: () => onChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(children: [
          AppIcon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade700)),
        ]),
      ),
    );
  }
}
