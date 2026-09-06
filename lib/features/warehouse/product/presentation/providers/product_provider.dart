import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:safishoe_app/features/warehouse/stock_inventory/presentation/providers/stock_provider.dart'
    show stockProductsProvider;

import '../../../../../core/pagination/pagination.dart';
import '../../data/datasource/product_remote_datasource.dart';
import '../../data/model/product_model.dart';
import '../../data/repository/product_repository.dart';

final productRemoteDatasourceProvider =
    Provider<ProductRemoteDatasource>((_) => ProductRemoteDatasource());

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
      remoteDatasource: ref.read(productRemoteDatasourceProvider));
});

/// Server-paginated products list. Search runs as a PostgreSQL `ilike` on
/// `article_name` (trigram index); the total comes from a single `COUNT` on the
/// first page / refresh only.
class ProductNotifier extends PaginatedListNotifier<ProductModel> {
  final ProductRepository _repo;
  final Ref _ref;
  ProductNotifier(this._repo, this._ref);

  /// Stock/purchase dialogs cache the product lookup list in a plain
  /// [FutureProvider]. Bust that cache after any write so newly added products
  /// appear in their dropdowns without a full page refresh.
  void _invalidateLookups() => _ref.invalidate(stockProductsProvider);

  @override
  Future<PageResult<ProductModel>> fetchPage(PageRequest request) =>
      _repo.fetchPage(request);

  /// Returns the public URL, or null on failure.
  Future<String?> uploadImage({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      return await _repo.uploadImage(
          fileName: fileName, bytes: bytes, mimeType: mimeType);
    } catch (_) {
      return null;
    }
  }

  /// Case-insensitive duplicate check. Returns true if another product already
  /// uses this article name. Falls back to false on network errors so the write
  /// path (which re-checks) stays the source of truth.
  Future<bool> articleNameExists(String articleName, {String? excludeId}) async {
    try {
      return await _repo.articleNameExists(articleName, excludeId: excludeId);
    } catch (_) {
      return false;
    }
  }

  Future<String?> create(ProductModel model) async {
    try {
      await _repo.create(model);
      await refresh();
      _invalidateLookups();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> update(ProductModel model) async {
    try {
      final updated = await _repo.update(model);
      replaceRow((p) => p.id == updated.id, updated);
      _invalidateLookups();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> delete(String id, String imageUrl) async {
    try {
      await _repo.delete(id, imageUrl);
      removeRow((p) => p.id == id);
      _invalidateLookups();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

final productProvider =
    StateNotifierProvider<ProductNotifier, PaginatedListState<ProductModel>>(
        (ref) => ProductNotifier(ref.read(productRepositoryProvider), ref));
