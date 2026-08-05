import '../datasource/type_remote_datasource.dart';
import '../model/type_model.dart';

class TypeRepository {
  final TypeRemoteDatasource remoteDatasource;
  TypeRepository({required this.remoteDatasource});

  Future<List<TypeModel>> getAll() => remoteDatasource.getAll();
  Future<TypeModel> create(TypeModel model) => remoteDatasource.create(model);
  Future<TypeModel> update(TypeModel model) => remoteDatasource.update(model);
  Future<void> delete(String id) => remoteDatasource.delete(id);
}
