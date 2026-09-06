import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/pagination/pagination.dart';
import '../model/product_model.dart';

class ProductRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;
  static const _bucket = 'product-images';

  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final path = 'products/$fileName';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucket);
      if (bucketIndex == -1) return;
      final path = segments.sublist(bucketIndex + 1).join('/');
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {}
  }

  Future<List<ProductModel>> getAll() async {
    final data = await _client
        .from('products')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  /// Server-side paginated + searched page of products.
  Future<PageResult<ProductModel>> fetchPage(PageRequest request) async {
    var query = _client.from('products').select();
    if (request.search.isNotEmpty) {
      query = query.ilike('article_name', '%${request.search}%');
    }
    final result = await runSupabasePage(
      query.order('created_at', ascending: false),
      request: request,
    );
    return result.map(ProductModel.fromJson);
  }

  Future<ProductModel> create(ProductModel model) async {
    final data = await _client
        .from('products')
        .insert(model.toJson())
        .select()
        .single();
    return ProductModel.fromJson(data);
  }

  Future<ProductModel> update(ProductModel model) async {
    final data = await _client
        .from('products')
        .update(model.toJson())
        .eq('id', model.id)
        .select()
        .single();
    return ProductModel.fromJson(data);
  }

  Future<void> delete(String id, String imageUrl) async {
    await deleteImage(imageUrl);
    await _client.from('products').delete().eq('id', id);
  }
}
