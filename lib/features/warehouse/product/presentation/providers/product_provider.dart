import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:safishoe_app/features/warehouse/product/presentation/providers/product_state.dart';
import '../../data/datasource/product_remote_datasource.dart';
import '../../data/model/product_model.dart';
import '../../data/repository/product_repository.dart';

final productRemoteDatasourceProvider =
    Provider<ProductRemoteDatasource>((_) => ProductRemoteDatasource());

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
      remoteDatasource: ref.read(productRemoteDatasourceProvider));
});

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRepository _repo;
  ProductNotifier(this._repo) : super(const ProductState());

  Future<void> loadAll() async {
    state = state.copyWith(status: ProductStatus.loading, errorMessage: null);
    try {
      final items = await _repo.getAll();
      state = state.copyWith(status: ProductStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<String?> uploadImage({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      return await _repo.uploadImage(
          fileName: fileName, bytes: bytes, mimeType: mimeType);
    } catch (e) {
      state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<void> create(ProductModel model) async {
    state = state.copyWith(status: ProductStatus.loading, errorMessage: null);
    try {
      await _repo.create(model);
      final items = await _repo.getAll();
      state = state.copyWith(status: ProductStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> update(ProductModel model) async {
    state = state.copyWith(status: ProductStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.update(model);
      final list =
          state.items.map((i) => i.id == updated.id ? updated : i).toList();
      state = state.copyWith(status: ProductStatus.success, items: list);
    } catch (e) {
      state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> delete(String id, String imageUrl) async {
    state = state.copyWith(status: ProductStatus.loading, errorMessage: null);
    try {
      await _repo.delete(id, imageUrl);
      final list = state.items.where((i) => i.id != id).toList();
      state = state.copyWith(status: ProductStatus.success, items: list);
    } catch (e) {
      state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final productProvider =
    StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ref.read(productRepositoryProvider));
});
