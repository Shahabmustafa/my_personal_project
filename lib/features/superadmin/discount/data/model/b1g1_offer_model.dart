/// Buy 1 Get 1 Free offer — admin chunta hai kin Articles / Brands /
/// Categories par lagega. Item in mein se kisi ek se bhi match ho to offer
/// mein hai.
class B1g1OfferModel {
  final String id;
  final String name;
  final List<String> productIds;
  final List<String> brandIds;
  final List<String> categoryIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const B1g1OfferModel({
    required this.id,
    required this.name,
    this.productIds = const [],
    this.brandIds = const [],
    this.categoryIds = const [],
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  bool matches({
    required String productId,
    required String brandId,
    required String categoryId,
  }) =>
      productIds.contains(productId) ||
      brandIds.contains(brandId) ||
      categoryIds.contains(categoryId);

  /// Active ho aur [now] start/end date ke andar ho (dono din shamil).
  bool isRunningOn(DateTime now) {
    if (!isActive) return false;
    final today = DateTime(now.year, now.month, now.day);
    if (startDate != null && today.isBefore(startDate!)) return false;
    if (endDate != null && today.isAfter(endDate!)) return false;
    return true;
  }

  static List<String> _ids(dynamic v) =>
      ((v as List?) ?? const []).map((e) => e.toString()).toList();

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory B1g1OfferModel.fromJson(Map<String, dynamic> json) => B1g1OfferModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        productIds: _ids(json['product_ids']),
        brandIds: _ids(json['brand_ids']),
        categoryIds: _ids(json['category_ids']),
        startDate: _date(json['start_date']),
        endDate: _date(json['end_date']),
        isActive: json['is_active'] as bool? ?? true,
      );

  static String? _dateStr(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'name': name,
        'product_ids': productIds,
        'brand_ids': brandIds,
        'category_ids': categoryIds,
        'start_date': _dateStr(startDate),
        'end_date': _dateStr(endDate),
        'is_active': isActive,
      };
}

/// Ek cart line ka B1G1 natija. [offerId] null = line offer mein nahi (ya
/// offer ki jodi nahi bani) — normal sale, return ho sakti hai.
class B1g1LineResult {
  final String? offerId;
  final int freeQty;
  const B1g1LineResult({this.offerId, this.freeQty = 0});
}

/// Cart lines (price + kis offer mein hai) le kar har line ke free units
/// nikalta hai. Har offer ke units qeemat ke hisaab se (mehnge pehle) line
/// mein lagte hain; har jodi ka doosra (sasta ya barabar) unit free.
///
/// [lines] mein har entry: (price, quantity, productId, brandId, categoryId).
List<B1g1LineResult> computeB1g1(
  List<({double price, int quantity, String productId, String brandId, String categoryId})>
      lines,
  List<B1g1OfferModel> offers,
) {
  final offerOf = <int, B1g1OfferModel>{};
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i];
    for (final o in offers) {
      if (o.matches(
          productId: l.productId,
          brandId: l.brandId,
          categoryId: l.categoryId)) {
        offerOf[i] = o;
        break;
      }
    }
  }

  final free = List<int>.filled(lines.length, 0);
  // Jis offer ke 2 se kam units hon wo laga hi nahi — wo lines normal sale.
  final applied = <String>{};
  for (final offer in offers) {
    final units = <({int line, double price})>[
      for (final e in offerOf.entries)
        if (e.value.id == offer.id)
          for (var q = 0; q < lines[e.key].quantity; q++)
            (line: e.key, price: lines[e.key].price),
    ]..sort((a, b) => b.price.compareTo(a.price));
    if (units.length >= 2) applied.add(offer.id);
    for (var u = 1; u < units.length; u += 2) {
      free[units[u].line]++;
    }
  }

  return [
    for (var i = 0; i < lines.length; i++)
      B1g1LineResult(
        offerId: applied.contains(offerOf[i]?.id) ? offerOf[i]!.id : null,
        freeQty: free[i],
      ),
  ];
}
