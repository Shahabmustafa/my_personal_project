import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/branch/sale_invoice/data/model/sale_invoice_model.dart'
    show PrinterLookupItem;

/// Printer dropdown for slips/invoices. Pre-selects the first printer once
/// the list loads; an empty list is fine — printing then falls back to the
/// default header.
class PrinterPickerField extends ConsumerStatefulWidget {
  final FutureProvider<List<PrinterLookupItem>> provider;
  final ValueChanged<PrinterLookupItem?> onChanged;

  const PrinterPickerField({
    super.key,
    required this.provider,
    required this.onChanged,
  });

  @override
  ConsumerState<PrinterPickerField> createState() => _PrinterPickerFieldState();
}

class _PrinterPickerFieldState extends ConsumerState<PrinterPickerField> {
  PrinterLookupItem? _selected;
  bool _autoSelected = false;

  void _select(PrinterLookupItem? p) {
    setState(() => _selected = p);
    widget.onChanged(p);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(widget.provider);

    return async.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Text('Printers unavailable: $e',
          style: const TextStyle(fontSize: 11, color: Colors.red)),
      data: (list) {
        if (list.isEmpty) {
          return Text('No printer assigned — default header will be used',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600));
        }
        if (!_autoSelected) {
          _autoSelected = true;
          _selected = list.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onChanged(_selected);
          });
        }
        return DropdownSearch<PrinterLookupItem>(
          items: (f, _) => list
              .where((e) => e.label.toLowerCase().contains(f.toLowerCase()))
              .toList(),
          selectedItem: _selected,
          itemAsString: (e) => e.label,
          compareFn: (a, b) => a.id == b.id,
          onSelected: _select,
          decoratorProps: const DropDownDecoratorProps(
            decoration: InputDecoration(
              labelText: 'Print slip on',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            constraints: BoxConstraints(maxHeight: 220),
          ),
        );
      },
    );
  }
}

/// What [pickPrinterForSlip] hands back — [printer] may be null when no
/// printer is assigned (the slip then prints with the default header).
class PrinterChoice {
  final PrinterLookupItem? printer;
  const PrinterChoice(this.printer);
}

/// Small "Print slip" dialog: pick a printer, then Print. Returns null if the
/// user cancels.
Future<PrinterChoice?> pickPrinterForSlip(
  BuildContext context,
  FutureProvider<List<PrinterLookupItem>> provider,
) {
  PrinterLookupItem? printer;
  return showDialog<PrinterChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Print Slip'),
      content: SizedBox(
        width: 360,
        child: PrinterPickerField(
          provider: provider,
          onChanged: (p) => printer = p,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, PrinterChoice(printer)),
          child: const Text('Print'),
        ),
      ],
    ),
  );
}
