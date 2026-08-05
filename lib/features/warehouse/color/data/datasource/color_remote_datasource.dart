import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/color_model.dart';

class ColorRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ColorModel>> getAll() async {
    final data = await _client
        .from('colors')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => ColorModel.fromJson(e)).toList();
  }

  Future<ColorModel> create(ColorModel model) async {
    final existing = await _client
        .from('colors')
        .select('id')
        .ilike('name', model.name.trim())
        .maybeSingle();
    if (existing != null) {
      throw Exception('A color with this color name already exists');
    }
    final data = await _client
        .from('colors')
        .insert(model.toJson())
        .select()
        .single();
    return ColorModel.fromJson(data);
  }

  Future<ColorModel> update(ColorModel model) async {
    final existing = await _client
        .from('colors')
        .select('id')
        .ilike('name', model.name.trim())
        .neq('id', model.id)
        .maybeSingle();
    if (existing != null) {
      throw Exception('Another color with this color name already exists');
    }
    final data = await _client
        .from('colors')
        .update(model.toJson())
        .eq('id', model.id)
        .select()
        .single();
    return ColorModel.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('colors').delete().eq('id', id);
  }
}
