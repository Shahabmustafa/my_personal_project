import '../datasource/category_remote_datasource.dart';
import '../model/category_model.dart';

class CategoryRepository {
  final CategoryRemoteDatasource remoteDatasource;
  CategoryRepository({required this.remoteDatasource});

  Future<List<CategoryModel>> getAll() => remoteDatasource.getAll();
  Future<CategoryModel> create(CategoryModel model) => remoteDatasource.create(model);
  Future<CategoryModel> update(CategoryModel model) => remoteDatasource.update(model);
  Future<void> delete(String id) => remoteDatasource.delete(id);
}
