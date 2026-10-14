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
}
