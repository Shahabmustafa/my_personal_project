import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../../../../core/widget/app_icon.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../superadmin/shared/current_head_office_provider.dart';
import '../../../sale_invoice/data/model/sale_invoice_model.dart';
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show saleInvoiceListProvider, saleInvoiceRepositoryProvider;
import '../../../shared/current_branch_provider.dart';
import '../providers/sale_claim_provider.dart';
import 'sale_claim_common.dart';

/// Naya claim: invoice chuno -> us invoice ki product line chuno -> quantity
/// + reason. Claim Head Office ko 'pending' jata hai.
class NewSaleClaimDialog extends ConsumerStatefulWidget {
  const NewSaleClaimDialog({super.key});

  @override
  ConsumerState<NewSaleClaimDialog> createState() => _NewSaleClaimDialogState();
}

class _NewSaleClaimDialogState extends ConsumerState<NewSaleClaimDialog> {
  static const _accent = Color(0xFFE56A00);

  final _qtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  SaleInvoiceModel? _picked; // dropdown mein selected (list row)
  SaleInvoiceModel? _invoice; // items ke sath (detail)
  Map<String, int> _claimed = {};
  SaleInvoiceItemModel? _item;
  bool _detailLoading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      if (ref.read(saleInvoiceListProvider).invoices.isEmpty) {
        ref.read(saleInvoiceListProvider.notifier).loadInvoices();
      }
    });
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  int _remaining(SaleInvoiceItemModel item) =>
      item.quantity - (_claimed[item.id] ?? 0);

  Future<void> _onInvoiceSelected(SaleInvoiceModel? listInvoice) async {
    if (listInvoice == null) return;
    setState(() {
      _picked = listInvoice;
      _invoice = null;
      _item = null;
      _qtyCtrl.clear();
      _detailLoading = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(saleInvoiceRepositoryProvider)
          .getInvoiceDetail(listInvoice.id);
      final claimed = await ref
          .read(saleClaimRepositoryProvider)
          .getClaimedQuantities(listInvoice.id);
      if (!mounted) return;
      setState(() {
        _invoice = detail;
        _claimed = claimed;
        _detailLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    final invoice = _invoice;
    final item = _item;
    if (invoice == null || item == null) {
      setState(() => _error = 'Select an invoice and a product');
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final remaining = _remaining(item);
    if (qty < 1 || qty > remaining) {
      setState(() => _error = 'Quantity must be between 1 and $remaining');
      return;
    }
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Reason is required');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final headOfficeId = await ref.read(headOfficeIdProvider.future);
      if (headOfficeId.isEmpty) {
        throw Exception('Head Office is not set up yet');
      }
      await ref.read(saleClaimRepositoryProvider).createClaim(
            branchId: ref.read(currentBranchIdProvider),
            headOfficeId: headOfficeId,
            invoice: invoice,
            item: item,
            quantity: qty,
            reason: reason,
            claimedBy: ref.read(authProvider).user?.id,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(saleInvoiceListProvider).invoices;
    final listLoading = ref.watch(saleInvoiceListProvider).isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIcon(AppIcons.warningAmberOutlined,
                      color: _accent, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('New Sale Claim',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.clear, size: 18),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSearchDropdown<SaleInvoiceModel>(
                        label: listLoading ? 'Loading invoices…' : 'Invoice',
                        items: invoices,
                        selectedItem: _picked,
                        itemLabel: (i) =>
                            '${i.invoiceNumber}  •  ${i.customerName ?? 'Walk-in'}'
                            '  •  ${claimFmtDate(i.createdAt)}',
                        isRequired: true,
                        prefixIcon: const AppIcon(AppIcons.receiptLongOutlined,
                            size: 18),
                        onChanged: _onInvoiceSelected,
                      ),
                      if (_detailLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_invoice != null) ...[
                        const SizedBox(height: 12),
                        _InvoiceSummary(invoice: _invoice!),
                        const SizedBox(height: 16),
                        const Text('Select product',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        for (final it in _invoice!.items)
                          _ItemTile(
                            item: it,
                            claimed: _claimed[it.id] ?? 0,
                            selected: _item?.id == it.id,
                            onTap: _remaining(it) <= 0
                                ? null
                                : () => setState(() {
                                      _item = it;
                                      _qtyCtrl.text = '1';
                                      _error = null;
                                    }),
                          ),
                        if (_item != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: _decoration(
                                      'Claim Quantity * (max ${_remaining(_item!)})'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ReadOnlyField(
                                  label: 'Sale Date',
                                  value: claimFmtDate(_invoice!.createdAt),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ReadOnlyField(
                                  label: 'Claim Date',
                                  value: claimFmtDate(DateTime.now()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _reasonCtrl,
                            minLines: 3,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _decoration(
                                'Reason * (e.g. sole came off after 1 week)'),
                          ),
                        ],
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                    onPressed: _saving || _item == null ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Claim'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: Colors.white,
    );

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _decoration(label).copyWith(
        fillColor: Colors.grey.shade100,
      ),
      child: Text(value, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _InvoiceSummary extends StatelessWidget {
  final SaleInvoiceModel invoice;
  const _InvoiceSummary({required this.invoice});

  @override
  Widget build(BuildContext context) {
    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.only(right: 24, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text(v,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Wrap(
        children: [
          kv('Invoice', invoice.invoiceNumber),
          kv('Customer', invoice.customerName ?? 'Walk-in'),
          kv('Sale Date', claimFmtDate(invoice.createdAt)),
          kv('Total', 'Rs. ${invoice.totalAmount.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final SaleInvoiceItemModel item;
  final int claimed;
  final bool selected;
  final VoidCallback? onTap;
  const _ItemTile({
    required this.item,
    required this.claimed,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = item.quantity - claimed;
    final details = [
      if (item.brandName != null) item.brandName!,
      if (item.sizeName != null) 'Size ${item.sizeName}',
      if (item.colorName != null) item.colorName!,
      if (item.categoryName != null) item.categoryName!,
      if (item.typeName != null) item.typeName!,
    ].join(' · ');

    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF4E8) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFFE56A00) : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName ?? 'Product',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    if (details.isNotEmpty)
                      Text(details,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    if ((item.barcode ?? '').isNotEmpty)
                      Text(item.barcode!,
                          style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs. ${item.salePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    remaining <= 0
                        ? 'Fully claimed'
                        : 'Sold ${item.quantity} · Can claim $remaining',
                    style: TextStyle(
                        fontSize: 11,
                        color: remaining <= 0
                            ? Colors.red.shade400
                            : Colors.grey.shade600),
                  ),
                ],
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                const AppIcon(AppIcons.checkCircleOutline,
                    size: 20, color: Color(0xFFE56A00)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
