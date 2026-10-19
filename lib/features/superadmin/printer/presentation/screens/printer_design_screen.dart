import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/service/print/print_service.dart';
import 'package:safishoe_app/core/service/print/receipt_options.dart';
import '../../data/models/printer_head_model.dart';
import '../providers/printer_providers.dart';

const _primary = Color(0xFF3E63DD);

void openPrinterDesign(BuildContext context, PrinterHeadModel printer) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PrinterDesignScreen(printer: printer)),
  );
}

enum _DocType { sale, exchange, ret }

/// Printer head ke receipt header ka design — left side controls, right
/// side live invoice preview. Sale Invoice / Exchange / Return teeno ke
/// header par yahi design lagta hai.
class PrinterDesignScreen extends ConsumerStatefulWidget {
  final PrinterHeadModel printer;
  const PrinterDesignScreen({super.key, required this.printer});

  @override
  ConsumerState<PrinterDesignScreen> createState() =>
      _PrinterDesignScreenState();
}

class _PrinterDesignScreenState extends ConsumerState<PrinterDesignScreen> {
  late String _position;
  late bool _showLogo;
  late bool _showName;
  late bool _showPhone;
  late bool _showAddress;
  late ReceiptOptions _opts;
  late final TextEditingController _thanksCtrl;
  late final TextEditingController _noteCtrl;
  _DocType _doc = _DocType.sale;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.printer;
    _position = p.logoPosition;
    _showLogo = p.showLogo;
    _showName = p.showName;
    _showPhone = p.showPhone;
    _showAddress = p.showAddress;
    _opts = p.receiptOptions;
    _thanksCtrl = TextEditingController(text: _opts.thankYouText);
    _noteCtrl = TextEditingController(text: _opts.extraNote);
  }

  @override
  void dispose() {
    _thanksCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _setOpts(ReceiptOptions o) => setState(() => _opts = o);

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(printerRepositoryProvider)
          .savePrinterDesign(
            id: widget.printer.id,
            logoPosition: _position,
            showLogo: _showLogo,
            showName: _showName,
            showPhone: _showPhone,
            showAddress: _showAddress,
            options: _opts,
          );
      ref.invalidate(printerHeadsProvider);
      ref.invalidate(assignedPrintersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Print design saved.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    final controls = _Controls(
      doc: _doc,
      onDoc: (d) => setState(() => _doc = d),
      position: _position,
      onPosition: (v) => setState(() => _position = v),
      showLogo: _showLogo,
      showName: _showName,
      showPhone: _showPhone,
      showAddress: _showAddress,
      opts: _opts,
      onOpts: _setOpts,
      thanksCtrl: _thanksCtrl,
      noteCtrl: _noteCtrl,
      onShowLogo: (v) => setState(() => _showLogo = v),
      onShowName: (v) => setState(() => _showName = v),
      onShowPhone: (v) => setState(() => _showPhone = v),
      onShowAddress: (v) => setState(() => _showAddress = v),
      saving: _saving,
      onSave: _save,
    );

    final preview = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _ReceiptPreview(
          printer: widget.printer,
          doc: _doc,
          position: _position,
          showLogo: _showLogo,
          showName: _showName,
          showPhone: _showPhone,
          showAddress: _showAddress,
          opts: _opts,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Print Design — ${widget.printer.name}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D3A),
          ),
        ),
      ),
      body: isMobile
          ? ListView(
              children: [
                Padding(padding: const EdgeInsets.all(16), child: controls),
                preview,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: controls,
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE7E9F0)),
                Expanded(child: preview),
              ],
            ),
    );
  }
}

// ── Controls (left) ─────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final _DocType doc;
  final ValueChanged<_DocType> onDoc;
  final String position;
  final ValueChanged<String> onPosition;
  final bool showLogo, showName, showPhone, showAddress;
  final ValueChanged<bool> onShowLogo, onShowName, onShowPhone, onShowAddress;
  final ReceiptOptions opts;
  final ValueChanged<ReceiptOptions> onOpts;
  final TextEditingController thanksCtrl;
  final TextEditingController noteCtrl;
  final bool saving;
  final VoidCallback onSave;

  const _Controls({
    required this.doc,
    required this.onDoc,
    required this.position,
    required this.onPosition,
    required this.showLogo,
    required this.showName,
    required this.showPhone,
    required this.showAddress,
    required this.onShowLogo,
    required this.onShowName,
    required this.onShowPhone,
    required this.onShowAddress,
    required this.opts,
    required this.onOpts,
    required this.thanksCtrl,
    required this.noteCtrl,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('PREVIEW'),
        SegmentedButton<_DocType>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _DocType.sale, label: Text('Sale')),
            ButtonSegment(value: _DocType.exchange, label: Text('Exchange')),
            ButtonSegment(value: _DocType.ret, label: Text('Return')),
          ],
          selected: {doc},
          onSelectionChanged: (s) => onDoc(s.first),
        ),
        const SizedBox(height: 22),
        const _Label('LOGO POSITION'),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: 'left',
              icon: Icon(Icons.format_align_left, size: 18),
              label: Text('Left'),
            ),
            ButtonSegment(
              value: 'center',
              icon: Icon(Icons.format_align_center, size: 18),
              label: Text('Center'),
            ),
            ButtonSegment(
              value: 'right',
              icon: Icon(Icons.format_align_right, size: 18),
              label: Text('Right'),
            ),
          ],
          selected: {position},
          onSelectionChanged: (s) => onPosition(s.first),
        ),
        const SizedBox(height: 6),
        const Text(
          'Name, phone and address follow the logo side.',
          style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
        ),
        const SizedBox(height: 22),
        const _Label('SHOW ON RECEIPT'),
        _Toggle('Logo', showLogo, onShowLogo),
        _Toggle('Name', showName, onShowName),
        _Toggle('Phone number', showPhone, onShowPhone),
        _Toggle('Address', showAddress, onShowAddress),
        const SizedBox(height: 22),
        const _Label('INVOICE DETAILS'),
        _Toggle(
          'Invoice / document number',
          opts.showDocNumber,
          (v) => onOpts(opts.copyWith(showDocNumber: v)),
        ),
        _Toggle(
          'Date',
          opts.showDate,
          (v) => onOpts(opts.copyWith(showDate: v)),
        ),
        _Toggle(
          'Customer',
          opts.showCustomer,
          (v) => onOpts(opts.copyWith(showCustomer: v)),
        ),
        _Toggle(
          'Salesman',
          opts.showSalesman,
          (v) => onOpts(opts.copyWith(showSalesman: v)),
        ),
        const SizedBox(height: 22),
        const _Label('ITEM COLUMNS'),
        _Toggle(
          'Color',
          opts.showColorColumn,
          (v) => onOpts(opts.copyWith(showColorColumn: v)),
        ),
        _Toggle(
          'Size',
          opts.showSizeColumn,
          (v) => onOpts(opts.copyWith(showSizeColumn: v)),
        ),
        _Toggle(
          'Discount',
          opts.showDiscountColumn,
          (v) => onOpts(opts.copyWith(showDiscountColumn: v)),
        ),
        const SizedBox(height: 22),
        const _Label('TOTALS'),
        _Toggle(
          'Sub total',
          opts.showSubTotal,
          (v) => onOpts(opts.copyWith(showSubTotal: v)),
        ),
        _Toggle(
          'Discount lines',
          opts.showDiscount,
          (v) => onOpts(opts.copyWith(showDiscount: v)),
        ),
        _Toggle(
          'Payment method / amounts',
          opts.showPayments,
          (v) => onOpts(opts.copyWith(showPayments: v)),
        ),
        const SizedBox(height: 22),
        const _Label('FOOTER'),
        _Toggle(
          'Policy notes',
          opts.showNotes,
          (v) => onOpts(opts.copyWith(showNotes: v)),
        ),
        _Toggle(
          'Thank-you line',
          opts.showThankYou,
          (v) => onOpts(opts.copyWith(showThankYou: v)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: thanksCtrl,
          onChanged: (v) => onOpts(opts.copyWith(thankYouText: v)),
          decoration: const InputDecoration(
            labelText: 'Thank-you text',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: noteCtrl,
          onChanged: (v) => onOpts(opts.copyWith(extraNote: v)),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Extra footer note (optional)',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Design'),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8A8FA3),
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(label, style: const TextStyle(fontSize: 14)),
    value: value,
    activeThumbColor: _primary,
    onChanged: onChanged,
  );
}

// ── Receipt preview (right) ─────────────────────────────────────────────

class _ReceiptPreview extends StatelessWidget {
  final PrinterHeadModel printer;
  final _DocType doc;
  final String position;
  final bool showLogo, showName, showPhone, showAddress;
  final ReceiptOptions opts;

  const _ReceiptPreview({
    required this.printer,
    required this.doc,
    required this.position,
    required this.showLogo,
    required this.showName,
    required this.showPhone,
    required this.showAddress,
    required this.opts,
  });

  static const _mono = 'monospace';
  static const _grey = Color(0xFF616161);

  CrossAxisAlignment get _cross => switch (position) {
    'left' => CrossAxisAlignment.start,
    'right' => CrossAxisAlignment.end,
    _ => CrossAxisAlignment.center,
  };

  TextAlign get _textAlign => switch (position) {
    'left' => TextAlign.left,
    'right' => TextAlign.right,
    _ => TextAlign.center,
  };

  @override
  Widget build(BuildContext context) {
    final title = switch (doc) {
      _DocType.sale => 'SALE INVOICE',
      _DocType.exchange => 'SALE EXCHANGE',
      _DocType.ret => 'SALE RETURN',
    };
    final numberLabel = switch (doc) {
      _DocType.sale => 'Invoice #',
      _DocType.exchange => 'Exchange #',
      _DocType.ret => 'Return #',
    };
    final number = switch (doc) {
      _DocType.sale => 'INV-0001',
      _DocType.exchange => 'EXC-0001',
      _DocType.ret => 'RET-0001',
    };

    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: _mono,
          fontSize: 11,
          color: Colors.black,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: logo, then name / phone / address ──
            Column(
              crossAxisAlignment: _cross,
              children: [
                if (showLogo) _logo(),
                if (showName)
                  Text(
                    ThermalPrintService.defaultShopName.toUpperCase(),
                    textAlign: _textAlign,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.5,
                    ),
                  ),
                if (showPhone && printer.phoneNumber.isNotEmpty)
                  Text(
                    printer.phoneNumber,
                    textAlign: _textAlign,
                    style: const TextStyle(fontSize: 10, color: _grey),
                  ),
                if (showAddress && printer.address.isNotEmpty)
                  Text(
                    printer.address,
                    textAlign: _textAlign,
                    style: const TextStyle(fontSize: 10, color: _grey),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const _Dash(),
            if (opts.showDocNumber) _kv(numberLabel, number),
            if (opts.showDate) _kv('Date', '19/10/2026 04:30 PM'),
            if (opts.showCustomer) _kv('Customer', 'Walk-in Customer'),
            if (opts.showSalesman) _kv('Salesman', 'Ali'),
            const _Dash(),
            ..._items(),
            ..._footer(),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    final url = printer.imageUrl;
    return Container(
      width: 55,
      height: 55,
      margin: const EdgeInsets.only(bottom: 8),
      child: url.isEmpty
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD9DCE6)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'No logo',
                style: TextStyle(fontSize: 9, color: Color(0xFF8A8FA3)),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_not_supported_outlined,
                color: Color(0xFF8A8FA3),
              ),
            ),
    );
  }

  Widget _cell(
    String t,
    int flex,
    TextAlign align, {
    bool bold = false,
    double size = 11,
  }) => Expanded(
    flex: flex,
    child: Text(
      t,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: size,
      ),
    ),
  );

  Widget _head() => Row(
    children: [
      _cell('ITEM', 3, TextAlign.left, bold: true, size: 9),
      if (opts.showColorColumn)
        _cell('COLOR', 2, TextAlign.center, bold: true, size: 9),
      if (opts.showSizeColumn)
        _cell('SIZE', 2, TextAlign.center, bold: true, size: 9),
      _cell('QTY', 1, TextAlign.center, bold: true, size: 9),
      if (opts.showDiscountColumn)
        _cell('DIS', 2, TextAlign.center, bold: true, size: 9),
      _cell('TOTAL', 2, TextAlign.right, bold: true, size: 9),
    ],
  );

  Widget _row(
    String name,
    String color,
    String size,
    String qty,
    String dis,
    String total,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        _cell(name, 3, TextAlign.left, size: 10),
        if (opts.showColorColumn) _cell(color, 2, TextAlign.center, size: 10),
        if (opts.showSizeColumn) _cell(size, 2, TextAlign.center, size: 10),
        _cell(qty, 1, TextAlign.center, size: 10),
        if (opts.showDiscountColumn) _cell(dis, 2, TextAlign.center, size: 10),
        _cell(total, 2, TextAlign.right, bold: true, size: 10),
      ],
    ),
  );

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      t,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 9,
        color: _grey,
      ),
    ),
  );

  List<Widget> _items() {
    switch (doc) {
      case _DocType.sale:
        return [
          _head(),
          const _Dash(),
          _row('Sports Runner', 'Black', '42', '1', '-', '3500'),
          _row('Formal Loafer', 'Brown', '41', '2', '500', '5500'),
          const _Dash(),
          if (opts.showSubTotal) _kv('Sub Total', '9,500'),
          if (opts.showDiscount) _kv('Discount', '-500'),
          _total('TOTAL', '9,000'),
          if (opts.showPayments) ...[
            const _Dash(),
            _section('PAID VIA'),
            _kv('Cash', '9,000'),
          ],
        ];
      case _DocType.exchange:
        return [
          _section('RETURNED ITEMS'),
          _head(),
          const _Dash(),
          _row('Sports Runner', 'Black', '42', '1', '-', '3500'),
          if (opts.showSubTotal) _kv('Return Sub Total', '3,500'),
          const _Dash(),
          _section('NEW ITEMS'),
          _head(),
          const _Dash(),
          _row('Casual Sneaker', 'White', '43', '1', '-', '4000'),
          if (opts.showSubTotal) _kv('New Sub Total', '4,000'),
          const _Dash(),
          _total('COLLECT FROM CUSTOMER', '500'),
          if (opts.showPayments) ...[
            const _Dash(),
            _section('PAYMENT'),
            _kv('Collected (Cash)', '500'),
          ],
        ];
      case _DocType.ret:
        return [
          _head(),
          const _Dash(),
          _row('Sports Runner', 'Black', '42', '1', '-', '3500'),
          const _Dash(),
          if (opts.showSubTotal) _kv('Sub Total', '3,500'),
          _total('REFUND AMOUNT', '3,500'),
          if (opts.showPayments) ...[
            const _Dash(),
            _section('REFUNDED VIA'),
            _kv('Cash', '3,500'),
          ],
        ];
    }
  }

  List<Widget> _footer() {
    final policy = switch (doc) {
      _DocType.sale =>
        '1) No warranty without original invoice.\n2) No exchange on worn or used footwear.\n3) Exchange within 7 days with tag intact.',
      _DocType.exchange =>
        'Exchanged pairs are subject to inspection before acceptance.',
      _DocType.ret => 'Returned pairs are subject to inspection before refund.',
    };
    return [
      const _Dash(),
      if (opts.showNotes)
        Text(policy, style: const TextStyle(fontSize: 8, color: _grey)),
      if (opts.extraNote.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          opts.extraNote,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: _grey),
        ),
      ],
      if (opts.showThankYou) ...[
        const SizedBox(height: 12),
        Text(
          opts.thankYouText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: _grey),
        ),
      ],
    ];
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(color: _grey)),
        Text(v),
      ],
    ),
  );

  Widget _total(String k, String v) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          v,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    ),
  );
}

class _Dash extends StatelessWidget {
  const _Dash();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
    child: Text(
      '- - - - - - - - - - - - - - - - - - - - - -',
      maxLines: 1,
      overflow: TextOverflow.clip,
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
    ),
  );
}
