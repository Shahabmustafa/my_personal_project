import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safishoe_app/features/warehouse/shared/catalog_delete_guard.dart';
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

  /// Case-insensitive exact match. `ilike` without wildcards, with `%`/`_`
  /// escaped so a name like "M_le" doesn't falsely match "Male". `limit(1)`
  /// instead of `maybeSingle()` so it never throws on multiple matches.
  Future<bool> _nameTaken(String name, {String? exceptId}) async {
    final pattern = name
        .trim()
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    var query = _client.from('categories').select('id').ilike('name', pattern);
    if (exceptId != null) query = query.neq('id', exceptId);
    final rows = await query.limit(1);
    return (rows as List).isNotEmpty;
  }

  /// `categories_name_unique` (on `lower(name)`) still guards against a race
  /// between the check and the write — map its violation to the same message.
  Exception _friendly(PostgrestException e) {
    if (e.code == '23505') {
      return Exception('A category with this name already exists');
    }
    return Exception(e.message);
  }

  Future<CategoryModel> create(CategoryModel model) async {
    final name = model.name.trim();
    if (await _nameTaken(name)) {
      throw Exception('A category with this name already exists');
    }
    try {
      final data = await _client
          .from('categories')
          .insert(model.copyWith(name: name).toJson())
          .select()
          .single();
      return CategoryModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw _friendly(e);
    }
  }

  Future<CategoryModel> update(CategoryModel model) async {
    final name = model.name.trim();
    if (await _nameTaken(name, exceptId: model.id)) {
      throw Exception('Another category with this name already exists');
    }
    try {
      final data = await _client
          .from('categories')
          .update(model.copyWith(name: name).toJson())
          .eq('id', model.id)
          .select()
          .single();
      return CategoryModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw _friendly(e);
    }
  }

  Future<void> delete(String id) async {
    await deleteCatalogRow(_client,
        table: 'categories', column: 'category_id', id: id, label: 'category');
  }
}
