import '../datasource/color_remote_datasource.dart';
import '../model/color_model.dart';

class ColorRepository {
  final ColorRemoteDatasource remoteDatasource;
  ColorRepository({required this.remoteDatasource});

  Future<List<ColorModel>> getAll() => remoteDatasource.getAll();
  Future<ColorModel> create(ColorModel model) => remoteDatasource.create(model);
  Future<ColorModel> update(ColorModel model) => remoteDatasource.update(model);
  Future<void> delete(String id) => remoteDatasource.delete(id);
}
