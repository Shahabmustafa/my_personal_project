import '../datasource/brand_remote_datasource.dart';
import '../model/brand_model.dart';

class BrandRepository {
  final BrandRemoteDatasource remoteDatasource;
  BrandRepository({required this.remoteDatasource});

  Future<List<BrandModel>> getAll() => remoteDatasource.getAll();
  Future<BrandModel> create(BrandModel model) => remoteDatasource.create(model);
  Future<BrandModel> update(BrandModel model) => remoteDatasource.update(model);
  Future<void> delete(String id) => remoteDatasource.delete(id);
}
