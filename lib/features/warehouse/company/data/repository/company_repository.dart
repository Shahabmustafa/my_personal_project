import '../datasource/company_remote_datasource.dart';
import '../model/company_model.dart';

class CompanyRepository {
  final CompanyRemoteDatasource remoteDatasource;
  CompanyRepository({required this.remoteDatasource});

  Future<List<CompanyModel>> getAllCompanies() =>
      remoteDatasource.getAllCompanies();

  Future<List<CompanyModel>> getCompaniesByWarehouse(String warehouseId) =>
      remoteDatasource.getCompaniesByWarehouse(warehouseId);

  Future<List<CompanyModel>> getCompaniesForWarehouses(
          List<String> warehouseIds) =>
      remoteDatasource.getCompaniesForWarehouses(warehouseIds);

  Future<CompanyModel> createCompany(CompanyModel company) =>
      remoteDatasource.createCompany(company);

  Future<CompanyModel> updateCompany(CompanyModel company) =>
      remoteDatasource.updateCompany(company);

  Future<void> deleteCompany(String id) =>
      remoteDatasource.deleteCompany(id);
}
