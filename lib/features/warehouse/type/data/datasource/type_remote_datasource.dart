import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/type_model.dart';

class TypeRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TypeModel>> getAll() async {
    final data = await _client
        .from('types')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => TypeModel.fromJson(e)).toList();
  }

  Future<TypeModel> create(TypeModel model) async {
    final existing = await _client
        .from('types')
        .select('id')
        .ilike('name', model.name.trim())
        .maybeSingle();
    if (existing != null) {
      throw Exception('A type with this type name already exists');
    }
    final data = await _client
        .from('types')
        .insert(model.toJson())
        .select()
        .single();
    return TypeModel.fromJson(data);
  }

  Future<TypeModel> update(TypeModel model) async {
    final existing = await _client
        .from('types')
        .select('id')
        .ilike('name', model.name.trim())
        .neq('id', model.id)
        .maybeSingle();
    if (existing != null) {
      throw Exception('Another type with this type name already exists');
    }
    final data = await _client
        .from('types')
        .update(model.toJson())
        .eq('id', model.id)
        .select()
        .single();
    return TypeModel.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('types').delete().eq('id', id);
  }
}
