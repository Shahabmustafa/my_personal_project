import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../../../superadmin/employee_salary/presentation/providers/employee_salary_providers.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../data/model/sale_invoice_model.dart';
import '../../../../superadmin/discount/data/model/sale_discount_tier_model.dart';
import '../provider/sale_invoice_provider.dart';
import '../shortcuts/sale_invoice_shortcuts.dart';
import 'package:safishoe_app/core/widget/keyboard_dropdown.dart';
import '../widgets/sale_cart_table.dart';
import '../widgets/sale_product_selector.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/widget/invoice_page_body.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

class SaleInvoiceScreen extends ConsumerWidget {
  const SaleInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleInvoiceProvider);
    final primary = Theme.of(context).colorScheme.primary;

    final isMobile = Responsive(context).isMobile;

    final invoiceNo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Invoice Number :',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            state.invoiceLoading
                ? const SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : Text(
                    state.invoiceNumber.isEmpty ? '...' : state.invoiceNumber,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () =>
                  ref.read(saleInvoiceProvider.notifier).resetInvoice(),
              child: const AppIcon(
                AppIcons.refresh,
                size: 17,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );

    final dateBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Date',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(DateTime.now()),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );

    final typeToggle = _SaleTypeToggle(
      value: state.paymentType,
      stretch: isMobile,
      onChanged: (t) =>
          ref.read(saleInvoiceProvider.notifier).selectPaymentType(t),
    );

    return SaleInvoiceShortcuts(
      child: InvoicePageBody(
        top: [
          // ── Invoice header card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [invoiceNo, const Spacer(), dateBlock]),
                      const SizedBox(height: 12),
                      typeToggle,
                    ],
                  )
                : Row(
                    children: [
                      invoiceNo,
                      const SizedBox(width: 20),
                      typeToggle,
                      const Spacer(),
                      dateBlock,
                    ],
                  ),
          ),

          const SizedBox(height: 12),

          // ── Manager missing warning ──────────────────────────────────
          const _ManagerWarningBanner(),

          // ── Customer / Salesman / Printer / Bank ─────────────────────
          const _InvoiceMetaRow(),

          const SizedBox(height: 8),
          const SaleProductSelector(showShortcutHints: true),
          const SizedBox(height: 8),
        ],
        cart: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const SaleCartTable(),
        ),
        bottom: const [SizedBox(height: 12), _InvoiceFooter()],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Sale type toggle (cash / card) ────────────────────────────────────────

class _SaleTypeToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  /// Mobile: fill the row width, segments share it equally.
  final bool stretch;
  const _SaleTypeToggle({
    required this.value,
    required this.onChanged,
    this.stretch = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _seg('Cash', 'cash', AppIcons.paymentsOutlined, primary),
          _seg('Card', 'card', AppIcons.creditCardOutlined, primary),
          _seg('Cash + Card', 'cash_card', AppIcons.syncAlt, primary),
        ],
      ),
    );
  }

  Widget _seg(String label, String type, String icon, Color primary) {
    final selected = value == type;
    final seg = InkWell(
      onTap: () => onChanged(type),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: stretch ? 6 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisAlignment: stretch
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            AppIcon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            stretch
                ? Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: stretch ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  )
                : Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: stretch ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
          ],
        ),
      ),
    );
    return stretch ? Expanded(child: seg) : seg;
  }
}

// ── Salesman / Printer / Bank row ─────────────────────────────────────────
// Manager branch se auto-resolve hota hai (role='manager') aur cashier
// hamesha logged-in user hota hai — isliye yahan inka koi dropdown nahi
// dikhaya jata.

class _InvoiceMetaRow extends ConsumerStatefulWidget {
  const _InvoiceMetaRow();

  @override
  ConsumerState<_InvoiceMetaRow> createState() => _InvoiceMetaRowState();
}

class _InvoiceMetaRowState extends ConsumerState<_InvoiceMetaRow> {
  final _cashAmountCtrl = TextEditingController();
  final _customerKey = GlobalKey<KeyboardDropdownState<CustomerModel>>();
  final _printerKey = GlobalKey<KeyboardDropdownState<PrinterLookupItem>>();
  final _salesmanKey = GlobalKey<KeyboardDropdownState<EmployeeLookupItem>>();

  @override
  void dispose() {
    _cashAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleInvoiceProvider);
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final customersAsync = ref.watch(customersForSaleProvider);
    final salesmenAsync = ref.watch(salesmenProvider);
    final printersAsync = ref.watch(printersForSaleProvider);
    final bankAsync = ref.watch(bankEntriesForSaleProvider);
    final isMobile = Responsive(context).isMobile;

    // Ctrl+C / Ctrl+P — dropdown kholo (↑↓ + Enter se select).
    ref.listen(saleShortcutProvider, (_, e) {
      if (e?.action == SaleShortcut.customer) {
        _customerKey.currentState?.open();
      } else if (e?.action == SaleShortcut.salesman) {
        _salesmanKey.currentState?.open();
      } else if (e?.action == SaleShortcut.printer) {
        _printerKey.currentState?.open();
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // ── Row 1: Customer / Salesman / Printer ─────────────────────
          _adaptiveRow(isMobile, [
            Expanded(
              child: customersAsync.when(
                loading: () => const _FieldLoading(),
                error: (e, _) => Text(
                  'Error: $e',
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                ),
                data: (list) {
                  final active = list.where((c) => c.isActive).toList();
                  return KeyboardDropdown<CustomerModel>(
                    key: _customerKey,
                    filter: (f) => active
                        .where(
                          (c) => c.name.toLowerCase().contains(f.toLowerCase()),
                        )
                        .toList(),
                    selectedItem: state.customer,
                    itemAsString: (c) => c.name,
                    compareFn: (a, b) => a.id == b.id,
                    onSelected: notifier.selectCustomer,
                    decoration: _decor('Customer', required: true, hint: 'Ctrl + C'),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _empDropdown(
                label: 'Salesman',
                required: true,
                hint: 'Ctrl + M',
                dropdownKey: _salesmanKey,
                async: salesmenAsync,
                selected: state.salesman,
                onSelected: notifier.selectSalesman,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: printersAsync.when(
                loading: () => const _FieldLoading(),
                error: (e, _) => Text(
                  'Error: $e',
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                ),
                data: (list) => KeyboardDropdown<PrinterLookupItem>(
                  key: _printerKey,
                  filter: (f) => list
                      .where(
                        (e) => e.label.toLowerCase().contains(f.toLowerCase()),
                      )
                      .toList(),
                  selectedItem: state.printer,
                  itemAsString: (e) => e.label,
                  compareFn: (a, b) => a.id == b.id,
                  onSelected: notifier.selectPrinter,
                  decoration: _decor('Printer', required: true, hint: 'Ctrl + P'),
                ),
              ),
            ),
          ]),

          // ── Row 2: Bank / Cash Amount ──────────────────────────────
          if (state.paymentType == 'card' ||
              state.paymentType == 'cash_card') ...[
            const SizedBox(height: 6),
            _adaptiveRow(isMobile, [
              Expanded(
                child: bankAsync.when(
                  loading: () => const _FieldLoading(),
                  error: (e, _) => Text(
                    'Error: $e',
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                  data: (list) => DropdownSearch<BankEntryLookupItem>(
                    items: (f, _) => list
                        .where(
                          (e) =>
                              e.label.toLowerCase().contains(f.toLowerCase()),
                        )
                        .toList(),
                    selectedItem: state.bankEntry,
                    itemAsString: (e) => e.label,
                    compareFn: (a, b) => a.id == b.id,
                    onSelected: notifier.selectBankEntry,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decor('Bank Account', required: true),
                    ),
                    popupProps: const PopupProps.menu(
                      fit: FlexFit.loose,
                      showSearchBox: true,
                      constraints: BoxConstraints(maxHeight: 260),
                    ),
                  ),
                ),
              ),
              if (state.paymentType == 'cash_card') ...[
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _cashAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    onChanged: (v) =>
                        notifier.setCashAmount(double.tryParse(v.trim()) ?? 0),
                    decoration: _decor('Cash Amount *').copyWith(
                      helperText:
                          'Card: Rs. ${state.cardAmount.toStringAsFixed(0)}',
                      helperStyle: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ] else
                const Spacer(),
            ]),
          ],
        ],
      ),
    );
  }

  /// Desktop: fields side by side. Mobile: stacked full width (spacers and
  /// gaps dropped, each Expanded unwrapped).
  Widget _adaptiveRow(bool isMobile, List<Widget> items) {
    if (!isMobile) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: items);
    }
    final fields = [
      for (final w in items)
        if (w is Expanded) w.child,
    ];
    return Column(
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          fields[i],
        ],
      ],
    );
  }

  /// employee_salary se aaye salesman ke liye dropdown. List khali ho to
  /// hint dikhata hai.
  Widget _empDropdown({
    required String label,
    required AsyncValue<List<EmployeeLookupItem>> async,
    required EmployeeLookupItem? selected,
    required void Function(EmployeeLookupItem?) onSelected,
    bool required = false,
    String? hint,
    GlobalKey<KeyboardDropdownState<EmployeeLookupItem>>? dropdownKey,
  }) {
    return async.when(
      loading: () => const _FieldLoading(),
      error: (e, _) => Text(
        'Error: $e',
        style: const TextStyle(fontSize: 11, color: Colors.red),
      ),
      data: (list) {
        if (list.isEmpty) {
          return InputDecorator(
            decoration: _decor(label, required: required, hint: hint),
            child: Text(
              '—',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          );
        }
        return KeyboardDropdown<EmployeeLookupItem>(
          key: dropdownKey,
          filter: (f) => list
              .where((e) => e.name.toLowerCase().contains(f.toLowerCase()))
              .toList(),
          selectedItem: selected,
          itemAsString: (e) => e.name,
          compareFn: (a, b) => a.id == b.id,
          onSelected: onSelected,
          decoration: _decor(label, required: required, hint: hint),
        );
      },
    );
  }

  InputDecoration _decor(String label, {bool required = false, String? hint}) =>
      InputDecoration(
        labelText: required ? '$label *' : label,
        // Keyboard shortcut ka hint field ke neeche.
        helperText: hint == null ? null : 'Shortcut: $hint',
        helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3)),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      );
}

class _FieldLoading extends StatelessWidget {
  const _FieldLoading();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 48,
    child: Center(child: LinearProgressIndicator()),
  );
}

// ── Invoice footer ────────────────────────────────────────────────────────

class _InvoiceFooter extends ConsumerStatefulWidget {
  const _InvoiceFooter();

  @override
  ConsumerState<_InvoiceFooter> createState() => _InvoiceFooterState();
}

class _InvoiceFooterState extends ConsumerState<_InvoiceFooter> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleInvoiceProvider);
    final theme = Theme.of(context);

    // Ctrl+S — invoice save (Sale Invoice button ki tarah hi shartein).
    ref.listen(saleShortcutProvider, (_, e) {
      if (e?.action != SaleShortcut.save) return;
      final s = ref.read(saleInvoiceProvider);
      if (s.isSaving || s.cartItems.isEmpty || s.manager == null) return;
      _onSaveTap(context, ref);
    });
    final branchPct =
        ref.watch(currentBranchMaxInvoiceDiscountPctProvider).value ?? 0;
    // Superadmin ne branch ka fixed % badla — cashier ko message dikhao.
    ref.listen<AsyncValue<double>>(currentBranchMaxInvoiceDiscountPctProvider, (
      prev,
      next,
    ) {
      final old = prev?.value;
      final now = next.value;
      if (old == null || now == null || old == now) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blueGrey.shade800,
          content: Text(
            now > 0
                ? 'Admin changed this branch\'s invoice discount to ${_fmtPct(now)}% '
                      '(was ${_fmtPct(old)}%).'
                : 'Admin removed the extra invoice discount for this branch.',
          ),
        ),
      );
    });
    // B1G1 lagi invoice par koi aur discount nahi.
    final allowDiscount = branchPct > 0 && !state.b1g1Applied;
    // Admin ka tier (bulk) discount lag gaya — branch % nahi lagta.
    final tier = state.matchedDiscountTier;
    final manualLocked = tier != null;

    final isMobile = Responsive(context).isMobile;

    final noteField = TextField(
      onChanged: (v) => ref.read(saleInvoiceProvider.notifier).setNote(v),
      decoration: InputDecoration(
        hintText: 'Note (optional)',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );

    final netBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Net Amount',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          state.totalAmount.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );

    final clearButton = OutlinedButton.icon(
      icon: const AppIcon(AppIcons.clearAll, size: 18),
      label: const Text('Clear'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: state.cartItems.isEmpty
          ? null
          : () => ref.read(saleInvoiceProvider.notifier).clearCart(),
    );

    final saveButton = Tooltip(
      message: state.manager == null
          ? 'Select a manager first (branch manager missing — add under Employees)'
          : 'Shortcut: Ctrl + S',
      child: FilledButton.icon(
        icon: state.isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const AppIcon(AppIcons.receiptLong, size: 18),
        label: const Text('Sale Invoice'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed:
            state.isSaving || state.cartItems.isEmpty || state.manager == null
            ? null
            : () => _onSaveTap(context, ref),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    _stat('Sub Total', state.subtotal.toStringAsFixed(0)),
                    _stat(
                      'Discount',
                      '- ${state.itemDiscount.toStringAsFixed(0)}',
                      color: Colors.orange.shade700,
                    ),
                    if (state.b1g1Applied) ...[
                      _stat(
                        'Buy 1 Get 1 Free',
                        '- ${state.b1g1Discount.toStringAsFixed(0)}',
                        color: Colors.green.shade700,
                      ),
                    ],
                    if (state.autoDiscount > 0) ...[
                      _stat(
                        'Bulk Discount (${_tierLabel(tier)})',
                        '- ${state.autoDiscount.toStringAsFixed(0)}',
                        color: Colors.green.shade700,
                      ),
                    ],
                    if (allowDiscount) ...[
                      SizedBox(
                        width: 150,
                        // Cashier edit nahi kar sakta — admin ka tay kiya % khud lagta hai.
                        child: TextFormField(
                          key: ValueKey(
                            'branch-disc-${manualLocked ? 0 : branchPct}',
                          ),
                          initialValue: manualLocked ? '0' : _fmtPct(branchPct),
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Extra Discount %',
                            suffixText: '%',
                            helperText: manualLocked
                                ? 'Auto discount applied (${_tierLabel(tier)})'
                                : 'Set by admin  •  - Rs. ${state.invoiceDiscount.toStringAsFixed(0)}',
                            helperStyle: const TextStyle(fontSize: 10),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                    netBlock,
                  ],
                ),
                const SizedBox(height: 12),
                noteField,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [const _HoldButtons(), clearButton],
                ),
                const SizedBox(height: 10),
                saveButton,
              ],
            )
          : Row(
              children: [
                _stat('Sub Total', state.subtotal.toStringAsFixed(0)),
                const SizedBox(width: 28),
                _stat(
                  'Discount',
                  '- ${state.itemDiscount.toStringAsFixed(0)}',
                  color: Colors.orange.shade700,
                ),
                if (state.b1g1Applied) ...[
                  const SizedBox(width: 28),
                  _stat(
                    'Buy 1 Get 1 Free',
                    '- ${state.b1g1Discount.toStringAsFixed(0)}',
                    color: Colors.green.shade700,
                  ),
                ],
                if (state.autoDiscount > 0) ...[
                  const SizedBox(width: 28),
                  _stat(
                    'Bulk Discount (${_tierLabel(tier)})',
                    '- ${state.autoDiscount.toStringAsFixed(0)}',
                    color: Colors.green.shade700,
                  ),
                ],
                if (allowDiscount) ...[
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 150,
                    // Cashier edit nahi kar sakta — admin ka tay kiya % khud lagta hai.
                    child: TextFormField(
                      key: ValueKey(
                        'branch-disc-${manualLocked ? 0 : branchPct}',
                      ),
                      initialValue: manualLocked ? '0' : _fmtPct(branchPct),
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Extra Discount %',
                        suffixText: '%',
                        helperText: manualLocked
                            ? 'Auto discount applied (${_tierLabel(tier)})'
                            : 'Set by admin  •  - Rs. ${state.invoiceDiscount.toStringAsFixed(0)}',
                        helperStyle: const TextStyle(fontSize: 10),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 28),
                Expanded(child: noteField),
                const SizedBox(width: 20),
                netBlock,
                const SizedBox(width: 20),
                const _HoldButtons(),
                const SizedBox(width: 10),
                clearButton,
                const SizedBox(width: 10),
                saveButton,
              ],
            ),
    );
  }

  String _tierLabel(SaleDiscountTierModel? t) {
    if (t == null) return '';
    return t.discountType == DiscountTierType.percent
        ? '${_fmtPct(t.discountValue)}%'
        : 'Rs. ${_fmtPct(t.discountValue)}';
  }

  String _fmtPct(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _onSaveTap(BuildContext context, WidgetRef ref) async {
    final state = ref.read(saleInvoiceProvider);

    String? warning;
    if (state.customer == null) {
      warning = 'Please select a customer';
    } else if (state.salesman == null) {
      warning = 'Please select a salesman';
    } else if (state.printer == null) {
      warning = 'Please select a printer';
    } else if (state.paymentType == 'card' && state.bankEntry == null) {
      warning = 'Please select a bank account for card sale';
    } else if (state.paymentType == 'cash_card') {
      if (state.bankEntry == null) {
        warning = 'Please select a bank account for the card portion';
      } else if (state.cashAmount <= 0 ||
          state.cashAmount >= state.totalAmount) {
        warning = 'Enter a cash amount between 0 and the net amount';
      }
    }
    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const AppIcon(
                AppIcons.warningAmberRounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(warning),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            AppIcon(AppIcons.receiptLong, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text(
              'Confirm Sale Invoice',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Save this invoice for Rs. ${state.totalAmount.toStringAsFixed(0)} '
          '(${state.totalQuantity} pairs, ${state.paymentType == 'cash_card' ? 'CASH Rs.${state.cashAmount.toStringAsFixed(0)} + CARD Rs.${state.cardAmount.toStringAsFixed(0)}' : state.paymentType.toUpperCase()})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final printer = state.printer;
    final error = await ref.read(saleInvoiceProvider.notifier).saveInvoice();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Invoice ne is salesman ki employee_salary total_sales badal di hai
    // (DB trigger se) — Branch Employee screen ki cached figures ko taaza
    // karne ke liye is provider ko invalidate karna zaroori hai.
    ref.invalidate(employeeSalariesForBranchProvider);

    final savedInvoice = ref.read(saleInvoiceProvider).lastSavedInvoice;
    if (savedInvoice != null) {
      try {
        await ThermalPrintService.printSaleInvoice(
          savedInvoice,
          printer: printer,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Print failed: $e'),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        }
      }
    }
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const AppIcon(
          AppIcons.checkCircleOutline,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Invoice Saved!'),
        content: const Text('Sale invoice saved successfully.'),
        actions: [
          FilledButton(
            autofocus: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(saleInvoiceProvider.notifier).resetInvoice();
            },
            child: const Text('New Invoice'),
          ),
        ],
      ),
    );
  }
}

// ── Manager missing warning ────────────────────────────────────────────────
// Manager branch se auto-resolve hota hai; ye banner sirf tab dikhta hai
// jab branch ko koi manager assign hi nahi kiya gaya.

class _ManagerWarningBanner extends ConsumerWidget {
  const _ManagerWarningBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerAsync = ref.watch(branchManagerProvider);
    final manager = managerAsync.value;

    if (!managerAsync.hasValue || manager != null)
      return const SizedBox.shrink();

    const fg = Color(0xFFC62828);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          AppIcon(AppIcons.errorOutline, size: 18, color: fg),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This branch has no manager assigned. Add a manager under Employees before creating an invoice.',
              style: TextStyle(
                fontSize: 12.5,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hold / Held invoices ──────────────────────────────────────────────────

/// Customer abhi shopping kar raha ho to chalti invoice "Hold" karo, doosre
/// customer ka invoice shuru karo, aur baad mein "Held" se wapas kholo.
class _HoldButtons extends ConsumerWidget {
  const _HoldButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleInvoiceProvider);
    final held = ref.watch(heldInvoicesProvider);
    const pad = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          icon: const AppIcon(AppIcons.accessTimeOutlined, size: 18),
          label: const Text('Hold'),
          style: OutlinedButton.styleFrom(padding: pad, shape: shape),
          onPressed: state.cartItems.isEmpty || state.isSaving
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ref
                      .read(saleInvoiceProvider.notifier)
                      .holdInvoice();
                  if (!ok) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Invoice put on hold — new invoice started. '
                        'You can reopen it from "Held".',
                      ),
                    ),
                  );
                },
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          icon: const AppIcon(AppIcons.history, size: 18),
          label: Text('Held (${held.length})'),
          style: OutlinedButton.styleFrom(padding: pad, shape: shape),
          onPressed: held.isEmpty
              ? null
              : () => showDialog<void>(
                  context: context,
                  builder: (_) => const _HeldInvoicesDialog(),
                ),
        ),
      ],
    );
  }
}

class _HeldInvoicesDialog extends ConsumerWidget {
  const _HeldInvoicesDialog();

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final held = ref.watch(heldInvoicesProvider);
    // Aakhri hold pehle.
    final rows = held.reversed.toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Held Invoices (${held.length})',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 460,
        child: rows.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No held invoices.'),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final h = rows[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      h.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${h.totalQuantity} pairs  •  Rs. ${h.totalAmount.toStringAsFixed(0)}'
                      '  •  held at ${_time(h.heldAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            final note = await ref
                                .read(saleInvoiceProvider.notifier)
                                .resumeHeld(h.id);
                            messenger.showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(
                                  seconds: note == null ? 3 : 7,
                                ),
                                backgroundColor: note == null
                                    ? null
                                    : Colors.orange.shade800,
                                content: Text(
                                  note == null
                                      ? 'Held invoice reopened.'
                                      : 'Held invoice reopened, but:\n$note',
                                ),
                              ),
                            );
                          },
                          child: const Text('Resume'),
                        ),
                        IconButton(
                          tooltip: 'Delete held invoice',
                          icon: const AppIcon(
                            AppIcons.deleteOutline,
                            size: 19,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dctx) => AlertDialog(
                                title: const Text('Held invoice delete?'),
                                content: Text(
                                  'The held invoice of ${h.customerName} (${h.totalQuantity} pairs) '
                                  'will be deleted permanently.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(dctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              ref
                                  .read(saleInvoiceProvider.notifier)
                                  .discardHeld(h.id);
                              if (ref.read(heldInvoicesProvider).isEmpty &&
                                  context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
