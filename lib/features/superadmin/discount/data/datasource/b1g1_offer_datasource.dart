import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/b1g1_offer_model.dart';

/// Offer screen ke dropdowns ke liye halka lookup (id + naam).
class B1g1Lookup {
  final String id;
  final String name;
  const B1g1Lookup(this.id, this.name);

  @override
  bool operator ==(Object other) => other is B1g1Lookup && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Head office stock ka ek variant — Sale Invoice ke Article dropdown jaisa
/// (color / size / brand / category / type ke sath).
class B1g1Variant {
  final String key;
  final String productId;
  final String productName;
  final String sizeName;
  final String colorName;
  final String brandName;
  final String categoryName;
  final String typeName;
  final String barcode;
  final double salePrice;
  final int quantity;

  const B1g1Variant({
    required this.key,
    required this.productId,
    required this.productName,
    this.sizeName = '',
    this.colorName = '',
    this.brandName = '',
    this.categoryName = '',
    this.typeName = '',
    this.barcode = '',
    this.salePrice = 0,
    this.quantity = 0,
  });

  /// "Red • Size 42 • Brand • Category • Type"
  String get details => [
        if (colorName.isNotEmpty) colorName,
        if (sizeName.isNotEmpty) 'Size $sizeName',
        if (brandName.isNotEmpty) brandName,
        if (categoryName.isNotEmpty) categoryName,
        if (typeName.isNotEmpty) typeName,
      ].join(' • ');

  String get label => details.isEmpty ? productName : '$productName — $details';

  @override
  bool operator ==(Object other) => other is B1g1Variant && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class B1g1OfferDatasource {
  final SupabaseClient _client;
  B1g1OfferDatasource(this._client);

  static const _table = 'b1g1_offers';

  Future<List<B1g1OfferModel>> getAll() async {
    final res = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: true);
    return (res as List)
        .map((e) => B1g1OfferModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(B1g1OfferModel offer) async {
    if (offer.id.isEmpty) {
      await _client.from(_table).insert(offer.toJson());
    } else {
      await _client.from(_table).update(offer.toJson()).eq('id', offer.id);
    }
  }

  Future<void> setActive(String id, bool active) async {
    await _client.from(_table).update({'is_active': active}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<List<B1g1Lookup>> _lookup(String table, String nameCol) async {
    final res = await _client
        .from(table)
        .select('id, $nameCol')
        .order(nameCol, ascending: true);
    return (res as List)
        .map((e) => B1g1Lookup(
              e['id'].toString(),
              e[nameCol]?.toString() ?? '',
            ))
        .toList();
  }

  Future<List<B1g1Lookup>> getProducts() => _lookup('products', 'article_name');
  Future<List<B1g1Lookup>> getBrands() => _lookup('brands', 'name');
  Future<List<B1g1Lookup>> getCategories() => _lookup('categories', 'name');

  Future<List<B1g1Variant>> getVariants() async {
    final res = await _client.from('stock_inventory').select('''
      product_id, size_id, color_id, brand_id, category_id, type_id,
      barcode, quantity,
      products(article_name, sale_price),
      sizes(number), colors(name), brands(name), categories(name), types(name)
    ''');
    String name(dynamic j, String col) =>
        (j as Map<String, dynamic>?)?[col]?.toString() ?? '';
    final seen = <String>{};
    final list = <B1g1Variant>[];
    for (final e in res as List) {
      String id(String c) => e[c]?.toString() ?? '';
      final key = b1g1VariantKey(
        productId: id('product_id'),
        sizeId: id('size_id'),
        colorId: id('color_id'),
        brandId: id('brand_id'),
        categoryId: id('category_id'),
        typeId: id('type_id'),
      );
      if (!seen.add(key)) continue;
      list.add(B1g1Variant(
        key: key,
        productId: id('product_id'),
        productName: name(e['products'], 'article_name'),
        sizeName: name(e['sizes'], 'number'),
        colorName: name(e['colors'], 'name'),
        brandName: name(e['brands'], 'name'),
        categoryName: name(e['categories'], 'name'),
        typeName: name(e['types'], 'name'),
        barcode: id('barcode'),
        salePrice:
            ((e['products'] as Map?)?['sale_price'] as num?)?.toDouble() ?? 0,
        quantity: (e['quantity'] as num?)?.toInt() ?? 0,
      ));
    }
    list.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }
}
