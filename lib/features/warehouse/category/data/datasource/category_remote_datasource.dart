import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/category_model.dart';

class CategoryRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CategoryModel>> getAll() async {
    final data = await _client
        .from('categories')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel> create(CategoryModel model) async {
    final existing = await _client
        .from('categories')
        .select('id')
        .ilike('name', model.name.trim())
        .maybeSingle();
    if (existing != null) {
      throw Exception('A category with this category already exists');
    }
    final data = await _client
        .from('categories')
        .insert(model.toJson())
        .select()
        .single();
    return CategoryModel.fromJson(data);
  }

  Future<CategoryModel> update(CategoryModel model) async {
    final existing = await _client
        .from('categories')
        .select('id')
        .ilike('name', model.name.trim())
        .neq('id', model.id)
        .maybeSingle();
    if (existing != null) {
      throw Exception('Another category with this category already exists');
    }
    final data = await _client
        .from('categories')
        .update(model.toJson())
        .eq('id', model.id)
        .select()
        .single();
    return CategoryModel.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
