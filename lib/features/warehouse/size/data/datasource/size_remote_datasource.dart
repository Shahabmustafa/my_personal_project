import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/size_model.dart';

class SizeRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<SizeModel>> getAll() async {
    final data = await _client
        .from('sizes')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => SizeModel.fromJson(e)).toList();
  }

  Future<SizeModel> create(SizeModel model) async {
    final existing = await _client
        .from('sizes')
        .select('id')
        .ilike('number', model.number.trim())
        .maybeSingle();
    if (existing != null) {
      throw Exception('A size with this size number already exists');
    }
    final data = await _client
        .from('sizes')
        .insert(model.toJson())
        .select()
        .single();
    return SizeModel.fromJson(data);
  }

  Future<SizeModel> update(SizeModel model) async {
    final existing = await _client
        .from('sizes')
        .select('id')
        .ilike('number', model.number.trim())
        .neq('id', model.id)
        .maybeSingle();
    if (existing != null) {
      throw Exception('Another size with this size number already exists');
    }
    final data = await _client
        .from('sizes')
        .update(model.toJson())
        .eq('id', model.id)
        .select()
        .single();
    return SizeModel.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('sizes').delete().eq('id', id);
  }
}
