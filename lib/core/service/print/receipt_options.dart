/// Receipt ke kaun se hisse print hon — printer head ke design se aata hai
/// (Sale Invoice / Exchange / Return teeno par lagta hai). Default: sab on.
class ReceiptOptions {
  final bool showDocNumber;
  final bool showDate;
  final bool showCustomer;
  final bool showSalesman;
  final bool showColorColumn;
  final bool showSizeColumn;
  final bool showDiscountColumn;
  final bool showSubTotal;
  final bool showDiscount;
  final bool showPayments;
  final bool showNotes;
  final bool showThankYou;

  /// "Thank you" line ka text.
  final String thankYouText;

  /// Footer par apni extra line (khali = print nahi hoti).
  final String extraNote;

  static const defaultThankYou = 'Thank you for shopping with us!';

  const ReceiptOptions({
    this.showDocNumber = true,
    this.showDate = true,
    this.showCustomer = true,
    this.showSalesman = true,
    this.showColorColumn = true,
    this.showSizeColumn = true,
    this.showDiscountColumn = true,
    this.showSubTotal = true,
    this.showDiscount = true,
    this.showPayments = true,
    this.showNotes = true,
    this.showThankYou = true,
    this.thankYouText = defaultThankYou,
    this.extraNote = '',
  });

  factory ReceiptOptions.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const ReceiptOptions();
    bool b(String k) => m[k] as bool? ?? true;
    final thanks = (m['thank_you_text'] as String?)?.trim() ?? '';
    return ReceiptOptions(
      showDocNumber: b('doc_number'),
      showDate: b('date'),
      showCustomer: b('customer'),
      showSalesman: b('salesman'),
      showColorColumn: b('color_col'),
      showSizeColumn: b('size_col'),
      showDiscountColumn: b('discount_col'),
      showSubTotal: b('sub_total'),
      showDiscount: b('discount'),
      showPayments: b('payments'),
      showNotes: b('notes'),
      showThankYou: b('thank_you'),
      thankYouText: thanks.isEmpty ? defaultThankYou : thanks,
      extraNote: (m['extra_note'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'doc_number': showDocNumber,
    'date': showDate,
    'customer': showCustomer,
    'salesman': showSalesman,
    'color_col': showColorColumn,
    'size_col': showSizeColumn,
    'discount_col': showDiscountColumn,
    'sub_total': showSubTotal,
    'discount': showDiscount,
    'payments': showPayments,
    'notes': showNotes,
    'thank_you': showThankYou,
    'thank_you_text': thankYouText,
    'extra_note': extraNote,
  };

  ReceiptOptions copyWith({
    bool? showDocNumber,
    bool? showDate,
    bool? showCustomer,
    bool? showSalesman,
    bool? showColorColumn,
    bool? showSizeColumn,
    bool? showDiscountColumn,
    bool? showSubTotal,
    bool? showDiscount,
    bool? showPayments,
    bool? showNotes,
    bool? showThankYou,
    String? thankYouText,
    String? extraNote,
  }) => ReceiptOptions(
    showDocNumber: showDocNumber ?? this.showDocNumber,
    showDate: showDate ?? this.showDate,
    showCustomer: showCustomer ?? this.showCustomer,
    showSalesman: showSalesman ?? this.showSalesman,
    showColorColumn: showColorColumn ?? this.showColorColumn,
    showSizeColumn: showSizeColumn ?? this.showSizeColumn,
    showDiscountColumn: showDiscountColumn ?? this.showDiscountColumn,
    showSubTotal: showSubTotal ?? this.showSubTotal,
    showDiscount: showDiscount ?? this.showDiscount,
    showPayments: showPayments ?? this.showPayments,
    showNotes: showNotes ?? this.showNotes,
    showThankYou: showThankYou ?? this.showThankYou,
    thankYouText: thankYouText ?? this.thankYouText,
    extraNote: extraNote ?? this.extraNote,
  );
}
