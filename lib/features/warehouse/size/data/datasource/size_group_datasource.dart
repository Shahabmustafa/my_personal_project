import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/size_group_model.dart';

class SizeGroupDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<SizeGroupModel>> getAll() async {
    final data = await _client.from('size_groups').select().order('name');
    return (data as List).map((e) => SizeGroupModel.fromJson(e)).toList();
  }

  Future<void> save(SizeGroupModel model) async {
    final dup = _client
        .from('size_groups')
        .select('id')
        .ilike('name', model.name.trim());
    final existing = await (model.id.isEmpty ? dup : dup.neq('id', model.id))
        .maybeSingle();
    if (existing != null) {
      throw Exception('A size group with this name already exists');
    }
    if (model.id.isEmpty) {
      await _client.from('size_groups').insert(model.toJson());
    } else {
      await _client.from('size_groups').update({
        ...model.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', model.id);
    }
  }

  Future<void> delete(String id) async {
    await _client.from('size_groups').delete().eq('id', id);
  }
}
