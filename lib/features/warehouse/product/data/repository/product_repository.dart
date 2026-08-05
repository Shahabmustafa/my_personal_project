import 'dart:typed_data';
import '../datasource/product_remote_datasource.dart';
import '../model/product_model.dart';

class ProductRepository {
  final ProductRemoteDatasource remoteDatasource;
  ProductRepository({required this.remoteDatasource});

  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) =>
      remoteDatasource.uploadImage(
          fileName: fileName, bytes: bytes, mimeType: mimeType);

  Future<List<ProductModel>> getAll() => remoteDatasource.getAll();
  Future<ProductModel> create(ProductModel model) => remoteDatasource.create(model);
  Future<ProductModel> update(ProductModel model) => remoteDatasource.update(model);
  Future<void> delete(String id, String imageUrl) =>
      remoteDatasource.delete(id, imageUrl);
}
