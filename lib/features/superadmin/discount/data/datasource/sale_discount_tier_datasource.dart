import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/sale_discount_tier_model.dart';

class SaleDiscountTierDatasource {
  final SupabaseClient _client;
  SaleDiscountTierDatasource(this._client);

  Future<List<SaleDiscountTierModel>> getAll() async {
    final data = await _client
        .from('sale_discount_tiers')
        .select()
        .order('min_sale_amount', ascending: false);
    return (data as List)
        .map((e) => SaleDiscountTierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SaleDiscountTierModel> create(SaleDiscountTierModel tier) async {
    final data = await _client.from('sale_discount_tiers').insert(tier.toJson()).select().single();
    return SaleDiscountTierModel.fromJson(data);
  }

  Future<SaleDiscountTierModel> update(SaleDiscountTierModel tier) async {
    final data = await _client
        .from('sale_discount_tiers')
        .update(tier.toJson())
        .eq('id', tier.id)
        .select()
        .single();
    return SaleDiscountTierModel.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('sale_discount_tiers').delete().eq('id', id);
  }
}
