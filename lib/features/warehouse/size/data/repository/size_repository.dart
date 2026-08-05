import '../datasource/size_remote_datasource.dart';
import '../model/size_model.dart';

class SizeRepository {
  final SizeRemoteDatasource remoteDatasource;
  SizeRepository({required this.remoteDatasource});

  Future<List<SizeModel>> getAll() => remoteDatasource.getAll();
  Future<SizeModel> create(SizeModel model) => remoteDatasource.create(model);
  Future<SizeModel> update(SizeModel model) => remoteDatasource.update(model);
  Future<void> delete(String id) => remoteDatasource.delete(id);
}
