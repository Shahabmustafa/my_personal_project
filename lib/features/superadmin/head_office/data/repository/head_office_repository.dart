import '../datasource/head_office_remote_datasource.dart';
import '../model/head_office_model.dart';

class HeadOfficeRepository {
  final HeadOfficeRemoteDatasource remoteDatasource;
  HeadOfficeRepository({required this.remoteDatasource});

  Future<List<HeadOfficeModel>> getAllHeadOffices() =>
      remoteDatasource.getAllHeadOffices();
  Future<HeadOfficeModel> getHeadOfficeById(String id) =>
      remoteDatasource.getHeadOfficeById(id);
  Future<HeadOfficeModel> createHeadOffice(HeadOfficeModel h) =>
      remoteDatasource.createHeadOffice(h);
  Future<HeadOfficeModel> updateHeadOffice(HeadOfficeModel h) =>
      remoteDatasource.updateHeadOffice(h);
  Future<void> deleteHeadOffice(String id) =>
      remoteDatasource.deleteHeadOffice(id);
}
