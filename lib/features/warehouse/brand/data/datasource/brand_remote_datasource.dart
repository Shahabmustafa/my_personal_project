import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/brand_model.dart';

class BrandRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BrandModel>> getAll() async {
    final data = await _client
        .from('brands')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => BrandModel.fromJson(e)).toList();
  }

  Future<BrandModel> create(BrandModel model) async {
    final existing = await _client
        .from('brands')
        .select('id')
        .ilike('name', model.name.trim())
        .maybeSingle();
    if (existing != null) {
      throw Exception('A brand with this brand name already exists');
    }
    final data = await _client
        .from('brands')
        .insert(model.toJson())
        .select()
        .single();
    return BrandModel.fromJson(data);
  }

  Future<BrandModel> update(BrandModel model) async {
    final existing = await _client
        .from('brands')
        .select('id')
        .ilike('name', model.name.trim())
        .neq('id', model.id)
        .maybeSingle();
    if (existing != null) {
      throw Exception('Another brand with this brand name already exists');
    }
    final data = await _client
        .from('brands')
        .update(model.toJson())
        .eq('id', model.id)
        .select()
        .single();
    return BrandModel.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('brands').delete().eq('id', id);
  }
}
